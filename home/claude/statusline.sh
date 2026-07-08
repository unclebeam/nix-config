#!/usr/bin/env bash
# Claude Code statusline
# Shows: context window usage %, 5h session limit usage/reset, 7d weekly
# limit usage/reset, and current model name.
#
# The statusline stdin JSON only exposes the combined `seven_day` weekly
# figure, so the model-scoped weekly limit (e.g. Fable) is fetched from
# the Anthropic usage API using the local OAuth token, cached for 60s in
# ~/.claude/statusline-usage-cache.json to keep refreshes instant.

input=$(cat)

# --- Context window percentage ---
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -z "$ctx_pct" ] || [ "$ctx_pct" = "null" ]; then
  # Fallback: estimate from the transcript's most recent usage entry.
  transcript=$(echo "$input" | jq -r '.transcript_path // empty')
  window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
  [ -z "$window_size" ] || [ "$window_size" = "null" ] && window_size=200000

  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    tokens=$(tail -n 300 "$transcript" 2>/dev/null | jq -rs '
      [.[] | select(.message.usage != null)] | last | .message.usage
      | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
    ' 2>/dev/null)
    if [ -n "$tokens" ] && [ "$tokens" != "null" ]; then
      ctx_pct=$(awk -v t="$tokens" -v w="$window_size" 'BEGIN { if (w>0) printf "%.0f", (t/w)*100 }')
    fi
  fi
fi

# Colorize a percentage value for glanceability: green (<70), yellow
# (70-89), red (90+). Only the number+"%" is colored, never the label.
color_pct() {
  local raw="$1" pct color
  pct=$(printf "%.0f" "$raw" 2>/dev/null) || return
  if [ "$pct" -ge 90 ]; then color="31"
  elif [ "$pct" -ge 70 ]; then color="33"
  else color="32"
  fi
  printf "\033[%sm%s%%\033[0m" "$color" "$pct"
}

ctx_str=""
if [ -n "$ctx_pct" ] && [ "$ctx_pct" != "null" ]; then
  ctx_str="Context: $(color_pct "$ctx_pct") used"
fi

# --- Rate limits (5h session / 7d weekly) ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Formats an epoch reset time as a friendly 12-hour clock time, e.g.
# "5:00 PM". Prepends the weekday abbreviation only when the reset falls
# on a day other than today, e.g. "Fri 3:00 PM". Never shows a raw
# timestamp or 24-hour time.
fmt_time() {
  local epoch="$1"
  [ -z "$epoch" ] || [ "$epoch" = "null" ] && return
  local time_str today_str reset_day day_str
  time_str=$(date -r "$epoch" "+%I:%M %p" 2>/dev/null || date -d "@$epoch" "+%I:%M %p" 2>/dev/null)
  [ -z "$time_str" ] && return
  time_str=$(echo "$time_str" | sed 's/^0//')
  today_str=$(date "+%Y-%m-%d")
  reset_day=$(date -r "$epoch" "+%Y-%m-%d" 2>/dev/null || date -d "@$epoch" "+%Y-%m-%d" 2>/dev/null)
  if [ "$reset_day" != "$today_str" ]; then
    day_str=$(date -r "$epoch" "+%a" 2>/dev/null || date -d "@$epoch" "+%a" 2>/dev/null)
    echo "$day_str $time_str"
  else
    echo "$time_str"
  fi
}

five_str=""
if [ -n "$five_pct" ] && [ "$five_pct" != "null" ]; then
  five_str="Session: $(color_pct "$five_pct")"
  rt=$(fmt_time "$five_reset")
  [ -n "$rt" ] && five_str="$five_str (resets $rt)"
fi

week_rt=""
if [ -n "$week_pct" ] && [ "$week_pct" != "null" ]; then
  week_rt=$(fmt_time "$week_reset")
fi

# --- Model-scoped weekly limit (e.g. Fable) ---
# Not present in the stdin JSON; fetched from the usage API with the
# OAuth token from the macOS Keychain or, on Linux, from Claude Code's
# plain-file credential store (~/.claude/.credentials.json). The token is
# never printed and the response is cached for 60s so most refreshes
# never touch the network.
usage_cache="$HOME/.claude/statusline-usage-cache.json"
cache_fresh=false
if [ -f "$usage_cache" ]; then
  now_epoch=$(date +%s)
  cache_mtime=$(stat -f %m "$usage_cache" 2>/dev/null || stat -c %Y "$usage_cache" 2>/dev/null)
  [ -n "$cache_mtime" ] && [ $((now_epoch - cache_mtime)) -lt 60 ] && cache_fresh=true
fi
if [ "$cache_fresh" != true ]; then
  # Token source differs by OS: macOS Keychain first (the 2>/dev/null also
  # swallows bash's command-not-found for `security` on Linux), then
  # Linux's plain-file store — same JSON shape in both.
  oauth_token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
    | jq -r '.claudeAiOauth.accessToken // empty')
  if [ -z "$oauth_token" ] && [ -f "$HOME/.claude/.credentials.json" ]; then
    oauth_token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  fi
  if [ -n "$oauth_token" ]; then
    usage_resp=$(curl -s --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
      -H "Authorization: Bearer $oauth_token" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "Content-Type: application/json" 2>/dev/null)
    # Only replace the cache with a response that actually has limits;
    # otherwise keep serving the stale cache.
    if [ -n "$usage_resp" ] && echo "$usage_resp" | jq -e '.limits' >/dev/null 2>&1; then
      printf "%s" "$usage_resp" > "$usage_cache"
    fi
  fi
fi

# Converts an ISO-8601 UTC timestamp (e.g. 2026-07-11T12:59:59.87+00:00)
# to epoch seconds for fmt_time.
iso_to_epoch() {
  local iso="$1"
  [ -z "$iso" ] || [ "$iso" = "null" ] && return
  local trimmed="${iso%%.*}"
  trimmed="${trimmed%%+*}"
  date -u -j -f "%Y-%m-%dT%H:%M:%S" "$trimmed" +%s 2>/dev/null \
    || date -d "$iso" +%s 2>/dev/null
}

scoped_pct=""
scoped_label="Fable"
if [ -f "$usage_cache" ]; then
  scoped_pct=$(jq -r '[.limits[]? | select(.kind=="weekly_scoped")][0].percent // empty' "$usage_cache" 2>/dev/null)
  if [ -n "$scoped_pct" ] && [ "$scoped_pct" != "null" ]; then
    scoped_label=$(jq -r '[.limits[]? | select(.kind=="weekly_scoped")][0].scope.model.display_name // "Fable"' "$usage_cache" 2>/dev/null)
    # Use the scoped reset as a fallback when the stdin JSON gave none.
    if [ -z "$week_rt" ]; then
      scoped_iso=$(jq -r '[.limits[]? | select(.kind=="weekly_scoped")][0].resets_at // empty' "$usage_cache" 2>/dev/null)
      scoped_epoch=$(iso_to_epoch "$scoped_iso")
      [ -n "$scoped_epoch" ] && week_rt=$(fmt_time "$scoped_epoch")
    fi
  else
    scoped_pct=""
  fi
fi

# Combined weekly section: "Week: All-25% Fable-46% (resets Sat 8:00 PM)".
# Each sub-limit appears only when its data is available; the "All-"
# prefix is dropped when there is no scoped limit to distinguish from.
week_str=""
if [ -n "$week_pct" ] && [ "$week_pct" != "null" ]; then
  if [ -n "$scoped_pct" ]; then
    week_str="Week: All-$(color_pct "$week_pct") ${scoped_label}-$(color_pct "$scoped_pct")"
  else
    week_str="Week: $(color_pct "$week_pct")"
  fi
elif [ -n "$scoped_pct" ]; then
  week_str="Week: ${scoped_label}-$(color_pct "$scoped_pct")"
fi
[ -n "$week_str" ] && [ -n "$week_rt" ] && week_str="$week_str (resets $week_rt)"

# --- Model name (helps disambiguate which weekly-limit tier applies) ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

parts=()
[ -n "$ctx_str" ] && parts+=("$ctx_str")
[ -n "$five_str" ] && parts+=("$five_str")
[ -n "$week_str" ] && parts+=("$week_str")
[ -n "$model_name" ] && parts+=("$model_name")

out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$p"
  else
    out="$out · $p"
  fi
done

[ -z "$out" ] && out="Usage info unavailable — type /usage"

printf "%s" "$out"
