-- home/hypr/hyprland.lua — THE hyprland config, a plain lua file symlinked to
-- ~/.config/hypr/hyprland.lua by home/hyprland.nix (same "editor configs stay
-- plain files" rule as helix). Edit it here, rebuild (or `hyprctl reload`
-- after a rebuild — home-manager doesn't reload for us), done.
--
-- Intellisense: hyprland ships official LuaLS stubs for the whole hl.* API;
-- .luarc.json at the repo root points lua-language-server at them (via the
-- ~/.config/hypr/stubs symlink), so helix gives completion/hover/type checks
-- in this file.
--
-- Hyprland 0.55 loads hyprland.lua INSTEAD of hyprland.conf when it exists
-- (hyprlang is deprecated and will be dropped in a release or two).

-- Values that come from Nix: the melange palette (home/colors.nix is the
-- single source of truth — NEVER hardcode a hex color here) and the cursor
-- theme/size (home/cursor.nix's home.pointerCursor). home/hyprland.nix
-- generates ~/.config/hypr/nix.lua next to this file; data only, no logic.
local nix = require("nix")

--------------------------------------------------------------------
-- ⚠ Load-bearing: makes systemd user services work in BOTH launch
-- modes the greeter offers — plain "Hyprland" and "Hyprland
-- (uwsm-managed)". Waybar (graphical-session.target), the portal,
-- and hypridle (hyprland-session.target, declared in
-- home/hyprland.nix) all hang off this firing. Never delete.
--
-- uwsm mode only: wayland-wm@hyprland.desktop.service is Type=notify
-- with a 30s timeout — `uwsm finalize` exports WAYLAND_DISPLAY and
-- DISPLAY (always) plus the named vars into the systemd user env,
-- then signals READY=1. Skip it and uwsm tears the whole session
-- down after 30 seconds. NOTIFY_SOCKET is the mode probe: systemd
-- sets it for notify-type units, a plain greetd exec doesn't. The
-- `||` + `;` keep the rest of the chain alive when the guard skips
-- (plain mode) or finalize fails; re-runs on `hyprctl reload` are
-- safe (an already-active finalize exits 0). uwsm is on PATH via
-- programs.hyprland.withUWSM in modules/hyprland.nix.
--
-- Both modes: dbus-update-activation-environment pushes the vars
-- into the D-Bus activation env too (finalize only feeds systemd),
-- then hyprland-session.target is stop/started — the stop-then-start
-- makes `hyprctl reload` restart the session services cleanly. In
-- plain mode its BindsTo pulls up graphical-session.target; under
-- uwsm that's already up because finalize ran first.
-- (dbus-update-activation-environment is on PATH via services.dbus,
-- always on under NixOS.)
--------------------------------------------------------------------
hl.on("hyprland.start", function()
  hl.exec_cmd('test -z "$NOTIFY_SOCKET"'
    .. " || uwsm finalize HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP"
    .. " XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE"
    .. " ; dbus-update-activation-environment --systemd DISPLAY"
    .. " HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    .. " XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE"
    .. " && systemctl --user stop hyprland-session.target"
    .. " && systemctl --user start hyprland-session.target")
end)

--------------------------------------------------------------------
-- Monitors. Matched by EDID description ("desc:" = the exact
-- `description` string from `hyprctl monitors all`, WITHOUT the
-- "(PORT)" suffix hyprctl prints). Entries that don't match a
-- plugged-in monitor are ignored, which is what lets both hosts
-- share this file; the wildcard fallback FIRST means an unmatched
-- panel still comes up at its preferred mode instead of going dark.
-- ⚠ When adding a monitor, take the desc verbatim from
-- `hyprctl monitors all -j` — hand-derived "make model serial"
-- strings can silently never match (see the OLED note below).
--------------------------------------------------------------------
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.monitor({
  output   = "desc:Dell Inc. DELL U3225QE 27D4834",
  mode     = "3840x2160@120",
  position = "auto",
  scale    = 1.5,
})

-- GIGA-BYTE M28U — 28" 4K gaming panel (external, on the ThinkPad).
-- Best EDID mode is 4K @ 144Hz; scale 1.25 = logical 3072x1728.
hl.monitor({
  output   = "desc:GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22060B005352",
  mode     = "3840x2160@144",
  position = "auto",
  scale    = 1.25,
})

-- Dell S2721DGF — 27" 1440p gaming panel (external, over HDMI).
-- Best EDID mode over HDMI is 1440p @ 144Hz (the panel does 165Hz,
-- but only over DisplayPort — bump the mode if it ever moves to DP).
-- 27" at 1440p is comfortable at 1x, so no fractional scaling.
hl.monitor({
  output   = "desc:Dell Inc. DELL S2721DGF 361Y3H3",
  mode     = "2560x1440@144",
  position = "auto",
  scale    = 1.0,
})

-- The thinkpad's built-in OLED panel: pin 120Hz (default pick is
-- 60Hz) and scale 1.5 (logical 1920x1200). VRR stays off (the
-- default) on purpose: VRR on OLED panels commonly causes
-- brightness flicker.
-- The desc is the exact `description` string hyprctl reports (make +
-- model, serial is empty so it contributes nothing) — verified with
-- `hyprctl monitors all -j`. A hand-derived "make model serial" form
-- was used here once; hyprland reports no serial/"Unknown", so that
-- suffix made the entry silently never match (panel fell back to
-- 60Hz/scale 2.0).
hl.monitor({
  output   = "desc:Samsung Display Corp. ATNA40HQ02-0",
  mode     = "2880x1800@120",
  position = "auto",
  scale    = 1.5,
})

--------------------------------------------------------------------
-- Look & feel. Lightly polished, deliberately so: small gaps,
-- slight rounding, fast animations, and blur behind the one
-- translucent surface we have (alacritty at 0.92 opacity, set in
-- home/alacritty.nix). Shadows stay off, and nothing more gets
-- added — the restrained look is a feature (see CLAUDE.md).
--------------------------------------------------------------------
hl.config({
  general = {
    gaps_in     = 5,
    gaps_out    = 10,
    border_size = 2,
    col = {
      -- focused = warm comment-beige, everything else fades into
      -- the bg.
      active_border   = "rgb(" .. nix.colors.a.com .. ")",
      inactive_border = "rgb(" .. nix.colors.a.float .. ")",
    },
    -- dwindle auto-splits along the longer side of the focused
    -- window — no autotiling daemon needed.
    layout = "dwindle",
  },

  decoration = {
    rounding = 8,
    shadow = { enabled = false },
    -- "A bit" of blur — only visible through translucent surfaces,
    -- i.e. the terminal. size/passes kept modest so the 4K panels
    -- don't pay for a heavy blur kernel every frame.
    blur = {
      enabled = true,
      size    = 5,
      passes  = 2,
    },
  },

  -- Master switch; the actual curves and per-leaf timings are the
  -- hl.curve/hl.animation calls right below this config block.
  animations = { enabled = true },

  misc = {
    -- Both required to get a plain background: the logo/anime-girl
    -- wallpaper must be off before background_color applies.
    disable_hyprland_logo   = true,
    force_default_wallpaper = 0,
    -- No wallpaper manager, just solid melange. Wants a number,
    -- so parse the palette's rrggbb hex string.
    background_color = tonumber(nix.colors.a.bg, 16),
  },

  input = {
    -- Keyboard: US + Thai, Alt+Shift cycles layouts. Applies to
    -- every keyboard, including kanata's virtual one.
    -- resolve_binds_by_sym stays false (the default): binds
    -- resolve against the FIRST layout, so SUPER+1 still switches
    -- workspaces under the Thai layout.
    kb_layout  = "us,th",
    kb_options = "grp:alt_shift_toggle",

    -- Mice scroll naturally, to match the touchpad.
    natural_scroll = true,

    -- Touchpad (laptop): tap-to-click, natural scrolling, palm
    -- rejection while typing.
    touchpad = {
      natural_scroll       = true,
      tap_to_click         = true,
      disable_while_typing = true,
    },
  },

  -- Keep the split direction where you put it instead of
  -- re-deriving it from window size on every close.
  dwindle = { preserve_split = true },

  -- Theme the group so it matches everything else — the groupbar
  -- renders the moment a group exists, and unstyled it ships
  -- hyprland's default (non-melange) colors. Palette from
  -- home/colors.nix via nix.colors (already #-stripped), same rgb()
  -- form as the window borders above. Gradients off = flat tabs, in
  -- keeping with the restrained look.
  group = {
    col = {
      -- Group's own tile border: reuse the window border scheme.
      border_active   = "rgb(" .. nix.colors.a.com .. ")",
      border_inactive = "rgb(" .. nix.colors.a.float .. ")",
    },
    groupbar = {
      enabled   = true,
      gradients = false,
      col = {
        -- Active tab = selection bg, the rest = float bg.
        active   = "rgb(" .. nix.colors.a.sel .. ")",
        inactive = "rgb(" .. nix.colors.a.float .. ")",
      },
      -- Tab titles: cream for the focused tab, muted beige otherwise.
      text_color          = "rgb(" .. nix.colors.a.fg .. ")",
      text_color_inactive = "rgb(" .. nix.colors.a.com .. ")",
    },
  },
})

-- Fast, snappy animations. `speed` is a duration in ~deciseconds,
-- so LOWER = faster — hyprland's own defaults sit around 4.8
-- (≈480ms); these run at roughly half that. The "global" leaf is
-- the fallback for every animation not listed; the explicit leaves
-- tune the ones you actually see all day. Curve/leaf API cribbed
-- from the example config hyprland ships (share/hypr/hyprland.lua).
hl.curve("quick",        { type = "bezier", points = { {0.15, 0},  {0.1, 1}  } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })

hl.animation({ leaf = "global",     enabled = true, speed = 2,   bezier = "quick" })
hl.animation({ leaf = "windows",    enabled = true, speed = 2,   bezier = "quick", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "quick", style = "popin 90%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1.2, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })

--------------------------------------------------------------------
-- Keybinds. Hyprland ships NO default binds — everything a
-- compositor usually gives for free (terminal, menu, focus,
-- workspaces…) is declared explicitly here.
--------------------------------------------------------------------
local mod  = "SUPER"
local term = "alacritty"

hl.bind(mod .. " + Return",        hl.dsp.exec_cmd(term))
hl.bind(mod .. " + D",             hl.dsp.exec_cmd("fuzzel"))
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.close())
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
-- Sway's tabbed container ≙ a hyprland group: toggle turns the focused
-- window into a group (a groupbar/tab strip appears) and dissolves it
-- again. Windows opened while a group member is focused join as tabs;
-- SUPER+T / SUPER+SHIFT+T cycle the tabs, and SUPER+ALT+<dir> moves
-- a window in/out of a group (both in the group block further below).
-- Groupbar theming lives in the group block of hl.config.
hl.bind(mod .. " + G",             hl.dsp.group.toggle())
-- This exits immediately — no confirmation nag.
hl.bind(mod .. " + SHIFT + E",     hl.dsp.exit())

-- Focus / move: arrows and hjkl. Plain and vanilla — SUPER+<dir>
-- moves focus, SUPER+SHIFT+<dir> moves the window. Group behavior
-- lives on its own keys below, deliberately kept OFF these so normal
-- tiling never has grouping intrude.
local dirs = {
  { "left", "left" }, { "right", "right" }, { "up", "up" }, { "down", "down" },
  { "H", "left" },    { "L", "right" },     { "K", "up" },  { "J", "down" },
}
for _, d in ipairs(dirs) do
  hl.bind(mod .. " + " .. d[1],         hl.dsp.focus({ direction = d[2] }))
  hl.bind(mod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }))
end

-- Group navigation (Sway's tabbed container; SUPER+G toggles a group,
-- up with the window binds). T / SHIFT+T cycle the tabs
-- (group.next/prev = changeGroupActive fwd/back). SUPER+ALT+<dir> moves
-- the focused window IN or OUT of a group: window.move{group_aware=true}
-- dispatches moveWindowOrGroup — into a group in that direction, or out
-- at the far edge — WITHOUT touching the plain SUPER+SHIFT+<dir> move.
-- (Field names verified against hyprland's LuaBindingsDispatchers.cpp.)
hl.bind(mod .. " + T",         hl.dsp.group.next())
hl.bind(mod .. " + SHIFT + T", hl.dsp.group.prev())
for _, d in ipairs(dirs) do
  hl.bind(mod .. " + ALT + " .. d[1], hl.dsp.window.move({ direction = d[2], group_aware = true }))
end

-- Workspaces 1–10 (the 0 key is workspace 10).
for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mouse: SUPER+LMB drags, SUPER+RMB resizes (any window) — the
-- only resize mechanism; there is no keyboard resize mode.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys → PipeWire. locked = they work on the lock screen too;
-- repeating = hold-to-repeat.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })

-- Backlight keys (laptop; harmless on the PC).
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Screenshots always open the satty annotator (home/satty.nix).
-- Bare Print = whole screen; Ctrl+Print = pick a region first. The
-- region bind grabs slurp's geometry into $sel FIRST so an Escape
-- in slurp exits non-zero and aborts the chain instead of handing
-- satty an empty capture. ([[…]] = lua raw string, no quote fights.)
hl.bind("Print",        hl.dsp.exec_cmd([[mkdir -p "$HOME/Pictures/Screenshots" && grim - | satty --filename -]]))
hl.bind("CTRL + Print", hl.dsp.exec_cmd([[sel="$(slurp)" && mkdir -p "$HOME/Pictures/Screenshots" && grim -g "$sel" - | satty --filename -]]))

-- Lock now. Via loginctl (not hyprlock directly) so it takes the
-- same path as idle/suspend locking and hypridle's lock_cmd can
-- guarantee a single hyprlock instance.
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("loginctl lock-session"))

--------------------------------------------------------------------
-- Obsidian & TickTick LAZY scratchpads → special workspaces
-- (hyprland's scratchpad). Nothing runs at login: SUPER+N / SUPER+O
-- launch the app on first press and toggle it thereafter — trading an
-- instant first summon for not paying idle Electron RAM every session.
-- The window rule sends each app to its
-- special workspace WITHOUT `silent`, so the first launch REVEALS it;
-- the bind is a plain lua callback (special workspaces have no
-- lazy-launch dispatcher of their own): if a window exists, toggle the
-- special workspace, else launch the app. class is the Wayland app_id —
-- "obsidian"; "ticktick" is pinned via --class in home/ticktick.nix.
-- If a toggle stops matching, re-check with `hyprctl clients`.
--
-- ⚠ Do NOT rewrite this as a shell guard around `hyprctl dispatch
-- togglespecialworkspace …` (the classic hyprlang spelling). Under the
-- lua config, `hyprctl dispatch X` evaluates X as the LUA EXPRESSION
-- hl.dispatch(X) — the old dispatcher string is a lua syntax error, and
-- hyprctl still exits 0 on that error, so even an `|| launch` fallback
-- never fires. That exact bug shipped once: first press launched,
-- every later press silently did nothing.
--------------------------------------------------------------------
-- launch-or-toggle: window with this class exists → toggle its special
-- workspace; else spawn it (the window rule reveals it on first map).
local function scratchpad(class, cmd)
  return function()
    if #hl.get_windows({ class = class }) > 0 then
      hl.dispatch(hl.dsp.workspace.toggle_special(class))
    else
      hl.exec_cmd(cmd)
    end
  end
end

hl.window_rule({
  name  = "obsidian-scratchpad",
  match = { class = "obsidian" },
  workspace = "special:obsidian",   -- no `silent`: first launch shows it
  float  = true,
  size   = { 1200, 800 },
  center = true,
})
hl.bind(mod .. " + N", scratchpad("obsidian", "obsidian"))

hl.window_rule({
  name  = "ticktick-scratchpad",
  match = { class = "ticktick" },
  workspace = "special:ticktick",   -- no `silent`: first launch shows it
  float  = true,
  size   = { 1200, 800 },
  center = true,
})
hl.bind(mod .. " + O", scratchpad("ticktick", "ticktick"))

--------------------------------------------------------------------
-- Cursor: theme/size from home/cursor.nix via the generated nix.lua.
-- Adwaita ships no hyprcursor variant; hyprland falls back to
-- XCursor, the same rendering every other toolkit uses.
--------------------------------------------------------------------
hl.env("XCURSOR_THEME", nix.cursor.name)
hl.env("XCURSOR_SIZE", tostring(nix.cursor.size))
