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
-- Monitors. Matched by EDID description ("desc:" = make model
-- serial — same string sway matches on, WITHOUT the "(PORT)"
-- suffix hyprctl prints). Entries that don't match a plugged-in
-- monitor are ignored, which is what lets both hosts share this
-- file; the wildcard fallback FIRST means an unmatched panel still
-- comes up at its preferred mode instead of going dark.
-- ⚠ VERIFY after first login with `hyprctl monitors all` — these
-- descs are carried over from sway's "make model serial" strings
-- and hyprland may format them slightly differently.
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

-- The thinkpad's built-in OLED panel: pin 120Hz (default pick is
-- 60Hz) and scale 1.5 (logical 1920x1200). VRR stays off (the
-- default) on purpose: VRR on OLED panels commonly causes
-- brightness flicker.
-- The desc is the exact `description` string hyprctl reports (make +
-- model, serial is empty so it contributes nothing) — verified with
-- `hyprctl monitors all -j`. NOT sway's "make model serial" form:
-- hyprland reports no serial/"Unknown" here, so that suffix made the
-- entry silently never match (panel fell back to 60Hz/scale 2.0).
hl.monitor({
  output   = "desc:Samsung Display Corp. ATNA40HQ02-0",
  mode     = "2880x1800@120",
  position = "auto",
  scale    = 1.5,
})

--------------------------------------------------------------------
-- Look & feel. The minimal look is deliberate: no gaps, no
-- rounding, no blur, no shadows, no animations — melange borders
-- on a solid melange background, matching the sway setup exactly.
-- (Two knobs sway had that hyprland doesn't: an urgent-window
-- border color, and titlebars — hyprland simply has neither.)
--------------------------------------------------------------------
hl.config({
  general = {
    gaps_in     = 0,
    gaps_out    = 0,
    border_size = 2,
    col = {
      -- focused = warm comment-beige, everything else fades into
      -- the bg — same mapping as home/sway.nix window colors.
      active_border   = "rgb(" .. nix.colors.a.com .. ")",
      inactive_border = "rgb(" .. nix.colors.a.float .. ")",
    },
    -- dwindle auto-splits along the longer side of the focused
    -- window — natively covering what the autotiling daemon does
    -- for sway (home/autotiling.nix stays sway-only).
    layout = "dwindle",
  },

  decoration = {
    rounding = 0,
    shadow = { enabled = false },
    blur = { enabled = false },
  },

  animations = { enabled = false },

  misc = {
    -- Both required to get a plain background: the logo/anime-girl
    -- wallpaper must be off before background_color applies.
    disable_hyprland_logo   = true,
    force_default_wallpaper = 0,
    -- No wallpaper manager, just solid melange — the counterpart
    -- of sway's `output * bg <color> solid_color`. Wants a number,
    -- so parse the palette's rrggbb hex string.
    background_color = tonumber(nix.colors.a.bg, 16),
  },

  input = {
    -- Keyboard: US + Thai, Alt+Shift cycles layouts. Applies to
    -- every keyboard, including kanata's virtual one.
    -- resolve_binds_by_sym stays false (the default): binds
    -- resolve against the FIRST layout, so SUPER+1 still switches
    -- workspaces under the Thai layout — hyprland's equivalent of
    -- sway's bindkeysToCode.
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
})

--------------------------------------------------------------------
-- Keybinds. Hyprland ships NO default binds — everything sway gave
-- us for free (terminal, menu, focus, workspaces…) is declared
-- explicitly here, same keys as the sway config.
--------------------------------------------------------------------
local mod  = "SUPER"
local term = "alacritty"

hl.bind(mod .. " + Return",        hl.dsp.exec_cmd(term))
hl.bind(mod .. " + D",             hl.dsp.exec_cmd("fuzzel"))
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.close())
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
-- No confirmation nag like sway's — this exits immediately.
hl.bind(mod .. " + SHIFT + E",     hl.dsp.exit())

-- Focus / move: arrows and hjkl, like sway's defaults.
local dirs = {
  { "left", "left" }, { "right", "right" }, { "up", "up" }, { "down", "down" },
  { "H", "left" },    { "L", "right" },     { "K", "up" },  { "J", "down" },
}
for _, d in ipairs(dirs) do
  hl.bind(mod .. " + " .. d[1],         hl.dsp.focus({ direction = d[2] }))
  hl.bind(mod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }))
end

-- Workspaces 1–10 (the 0 key is workspace 10).
for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mouse: SUPER+LMB drags, SUPER+RMB resizes (any window). The RMB
-- resize replaces sway's resize mode, which has no dwindle
-- equivalent (nor do tabbed/stacking layouts or focus-parent).
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys → PipeWire. locked = they work on the lock screen too;
-- repeating = hold-to-repeat (both upgrades over the sway binds).
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
-- Obsidian scratchpad → special workspace (hyprland's scratchpad).
-- Launched at login and sent to special:obsidian silently (nothing
-- appears on screen), as a centered 1200x800 float; SUPER+N toggles
-- it — the same instant-dropdown setup as under sway. The Electron
-- process is resident from boot as the price of that instant
-- summon. class is "obsidian" under native Wayland (NIXOS_OZONE_WL);
-- if the toggle stops matching, re-check with `hyprctl clients`.
--------------------------------------------------------------------
hl.window_rule({
  name  = "obsidian-scratchpad",
  match = { class = "obsidian" },
  workspace = "special:obsidian silent",
  float  = true,
  size   = { 1200, 800 },
  center = true,
})
hl.bind(mod .. " + N", hl.dsp.workspace.toggle_special("obsidian"))
hl.on("hyprland.start", function()
  hl.exec_cmd("obsidian")
end)

--------------------------------------------------------------------
-- Cursor: theme/size from home/cursor.nix via the generated nix.lua.
-- Adwaita ships no hyprcursor variant; hyprland falls back to
-- XCursor, which is exactly what sway renders too.
--------------------------------------------------------------------
hl.env("XCURSOR_THEME", nix.cursor.name)
hl.env("XCURSOR_SIZE", tostring(nix.cursor.size))
