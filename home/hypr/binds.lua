-- binds.lua — the keybinds, OURS and tracked (require()d by hyprland.lua).
-- Under DMS this file was generated and owned by the shell (`dms setup` →
-- dms/binds.lua); Noctalia manages no compositor config, so the binds came
-- home in the 2026-07 migration. Shell interactions go through
-- `noctalia msg …` (`noctalia msg --help` lists every command); window/
-- workspace management is compositor-native and carried over verbatim
-- from the DMS-era set — muscle memory preserved on purpose.
--
-- DMS binds with no Noctalia equivalent were DROPPED, not remapped (their
-- keys are free again): ALT+space (spotlight-bar), SUPER+M + CTRL+ALT+Del
-- (process list), SUPER+SHIFT+N (notepad), SUPER+SHIFT+/ (keybind cheat
-- sheet), SUPER+SHIFT+W (window-rules panel), CTRL+SHIFT+R (workspace
-- rename), CTRL+XF86Audio* (per-player mpris volume), SUPER+P (display
-- profile cycle).

local msg = "noctalia msg "

-- === Application Launchers ===
hl.bind("SUPER + T", hl.dsp.exec_cmd("alacritty"))
hl.bind("SUPER + space", hl.dsp.exec_cmd(msg .. "panel-toggle launcher"))
hl.bind("SUPER + V", hl.dsp.exec_cmd(msg .. "panel-toggle clipboard"))
hl.bind("SUPER + comma", hl.dsp.exec_cmd(msg .. "settings-toggle"))
-- Control center is the closest home for what DMS's notification panel
-- showed (notification history lives in one of its tabs).
hl.bind("SUPER + N", hl.dsp.exec_cmd(msg .. "panel-toggle control-center"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd(msg .. "panel-toggle wallpaper"))
-- Noctalia has no compositor-overview toggle like DMS's; its Alt-Tab-style
-- window switcher is the nearest thing, on the same two keys.
hl.bind("SUPER + TAB", hl.dsp.exec_cmd(msg .. "window-switcher"))
hl.bind("SUPER + O", hl.dsp.exec_cmd(msg .. "window-switcher"))
hl.bind("SUPER + X", hl.dsp.exec_cmd(msg .. "panel-toggle session"))

-- === Security ===
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd(msg .. "session lock"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

-- === Audio Controls ===
-- (Step size is a shell setting now, not a bind argument like DMS's
-- `audio increment 3` — adjust in the Settings GUI if the default steps
-- feel wrong.)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(msg .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(msg .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(msg .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(msg .. "mic-mute"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(msg .. "media toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(msg .. "media toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(msg .. "media previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(msg .. "media next"), { locked = true })

-- === Brightness Controls ===
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(msg .. "brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(msg .. "brightness-down"), { locked = true, repeating = true })

-- === Window Management ===
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + W", hl.dsp.group.toggle())

-- === Focus Navigation ===
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))

-- === Window Movement ===
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- === Column Navigation ===
hl.bind("SUPER + Home", hl.dsp.focus({ window = "first" }))
hl.bind("SUPER + End", hl.dsp.focus({ window = "last" }))

-- === Monitor Navigation ===
hl.bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }))
hl.bind("SUPER + CTRL + H", hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + J", hl.dsp.focus({ monitor = "d" }))
hl.bind("SUPER + CTRL + K", hl.dsp.focus({ monitor = "u" }))
hl.bind("SUPER + CTRL + L", hl.dsp.focus({ monitor = "r" }))

-- === Move to Monitor ===
hl.bind("SUPER + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind("SUPER + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }))

-- === Workspace Navigation ===
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + I", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + U", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ workspace = "e-1" }))
-- U/I directions match the focus binds above: I = next, U = prev.
hl.bind("SUPER + CTRL + I", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + U", hl.dsp.window.move({ workspace = "e-1" }))

-- === Move Workspaces ===
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "e-1" }))
-- U/I directions match the focus binds above: I = next, U = prev.
hl.bind("SUPER + SHIFT + I", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + U", hl.dsp.window.move({ workspace = "e-1" }))

-- === Mouse Wheel Navigation ===
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "e-1" }))

-- === Touchpad Gestures ===
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- === Numbered Workspaces ===
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }))
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "6" }))
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }))
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "8" }))
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "9" }))
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))

-- === Move to Numbered Workspaces ===
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- === Column Management ===
hl.bind("SUPER + bracketleft", hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))

-- === Sizing & Layout ===
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))

-- === Move/resize windows with mainMod + LMB/RMB and dragging ===
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

hl.bind(
	"SUPER + code:20",
	hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
	{ description = "Expand window left" }
)
hl.bind(
	"SUPER + code:21",
	hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
	{ description = "Shrink window left" }
)

-- === Manual Sizing ===
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

-- === Screenshots ===
-- Every capture pipes into satty ([shell.screenshot] in
-- home/noctalia/config.toml) — Enter commits (clipboard + saved file),
-- Escape discards. No focused-window mode: Noctalia captures region or
-- output only (DMS's ALT+Print window shot has no equivalent — draw the
-- region instead).
hl.bind("Print", hl.dsp.exec_cmd(msg .. "screenshot-region"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(msg .. "screenshot-fullscreen"))

-- === System Controls ===
hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))
