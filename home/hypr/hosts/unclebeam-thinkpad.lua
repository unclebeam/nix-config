-- home/hypr/hosts/unclebeam-thinkpad.lua — THIS machine's displays.
--
-- One file per host, and Nix picks which one gets symlinked to
-- ~/.config/hypr/host.lua (home/hyprland.nix, keyed on
-- osConfig.networking.hostName). So hyprland.lua carries NO hostname branch,
-- and the PC's rules are never loaded on this machine — which used to matter
-- a lot: see the absent-monitor note under the workspace pins below.
--
-- Everything here is a HARDWARE FACT read off this machine with
-- `hyprctl monitors all` — never guessed. Tracked in git (safe now that Nix
-- only ever links this host's file), so a fresh install boots with the right
-- layout instead of falling back to auto-config. Still an out-of-store
-- symlink: edits apply on a bare `hyprctl reload`, no rebuild.

-- ── Monitors ────────────────────────────────────────────────────────────
--
-- Physical layout: the Gigabyte sits stacked directly ON TOP of the MSI, and
-- the laptop is open to the LEFT of the MSI with their BOTTOM edges level
-- (the laptop sits on the desk, the monitors are up on a stand).
--
--                      ┌────────────────────────┐
--                      │ GIGABYTE  0x-1440      │  y -1440 .. 0
--                      └────────────────────────┘
--    ┌──────────────┐  ┌────────────────────────┐
--    │ eDP-1        │  │ MSI (main)  0x0        │  y     0 .. 1440
--    │ -1920x240    │  │                        │
--    └──────────────┘  └────────────────────────┘
--     x -1920 .. 0      x     0 .. 2560
--
-- Three conventions worth knowing before editing:
--
-- * `position` is in LOGICAL pixels, i.e. AFTER scale. Both externals are 4K
--   (3840x2160) at scale 1.5 => 2560x1440 logical, so the top one goes at
--   y = -1440, not -2160; using the PHYSICAL height is the classic mistake
--   that leaves a dead 720 px gap the cursor has to cross. Likewise the
--   laptop is 1920x1200 logical, so bottom-aligning it against the MSI's
--   bottom edge (y = 1440) means y = 1440 - 1200 = 240, and x = -1920 puts
--   its right edge flush against the MSI's left edge.
--
-- * The MSI anchors the origin because it's the main panel (same convention
--   as hosts/unclebeam-pc.lua). That's what makes x negative here — normal in
--   hyprland, but this is the repo's first negative x, so if a layout ever
--   comes back wrong, `hyprctl monitors` is the check.
--
-- * Externals are selected by `desc:` (the EDID description), NOT by the
--   DP-n / HDMI-A-n connector: port numbers renumber across replugs and dock
--   changes. `desc:` is compared with starts_with, so these are prefixes.
--
-- Modes are spelled out rather than left at "preferred"/auto: hyprland's
-- auto-config picks the first EDID mode, which is 60 Hz on BOTH 120 Hz panels
-- here — the point of a 120 Hz OLED and a 4K120 external is lost silently. If
-- a mode ever fails to link-train hyprland falls back and logs it, so check
-- `hyprctl monitors` after changing one.
--
-- No `vrr` on any of these, deliberately: hyprland's default is already 0 and
-- this repo prunes default-valued settings. Don't "enable FreeSync" on the
-- M28U just because the panel supports it — this is Intel graphics and
-- nothing games on it. (The PC's OLED sets vrr = 2 because it does.)

-- Main: MSI PM271UPXW12G, 27" 4K, on USB-C (came up as DP-1).
-- Full EDID description is "Micro-Star Int'l Co. Ltd. PM271UPXW12G
-- 0x01010101" — the serial is trimmed off the selector on purpose. 0x01010101
-- is a placeholder MSI ships on many panels, so it identifies nothing;
-- matching on the model is the honest prefix. (Contrast the Gigabyte below,
-- whose serial is real and is kept.)
-- 4K120 exceeds HBR3 (~25.8 Gbps needed vs ~17.28 available), so it only
-- works with DSC over the Thunderbolt DP tunnel — and this machine has a
-- history of tunnel instability (repeated "DP tunnel activation failed" with
-- the old Dells, 2026-08-01). If it starts blanking or re-enumerating, drop
-- to "3840x2160@60.000" — a measured mode from this panel's list, not a guess.
local main = "desc:Micro-Star Int'l Co. Ltd. PM271UPXW12G"
hl.monitor({
	output = main,
	mode = "3840x2160@120.000",
	position = "0x0",
	scale = 1.5,
})

-- Above: GIGABYTE M28U, 28" 4K.
-- Living proof of the `desc:` rule two paragraphs up: this panel used to
-- enumerate as HDMI-A-1 (where 4K really was capped at 60 — everything faster
-- in that EDID was 1440p or lower), and it now comes up as DP-3. Nothing in
-- this file had to change for that, because nothing here names a connector.
-- On the current link `hyprctl monitors all` lists 4K at 144, 120 and 60.
-- 120 is chosen deliberately over the panel's 144 ceiling: it matches the MSI,
-- and both externals share ONE USB-C/Thunderbolt DP tunnel on a machine with a
-- history of tunnel flapping (see the MSI's note above) — the spare bandwidth
-- is worth more than 24 Hz nobody will notice. Measured fallback if the link
-- ever misbehaves: "3840x2160@60.000".
local secondary = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. M28U 22060B005352"
hl.monitor({
	output = secondary,
	mode = "3840x2160@120.000",
	position = "0x-1440",
	scale = 1.5,
})

-- Left: the built-in Samsung ATNA40HQ02-0 OLED. Selected by CONNECTOR, not
-- desc — an internal panel never renumbers, and eDP-1 is the clearer name.
-- Scale 1.5 divides both axes exactly (2880/1.5 = 1920, 1800/1.5 = 1200), so
-- there's no fractional-remainder blur: 1080p-equivalent width at the panel's
-- native 16:10.
local internal = "eDP-1"
hl.monitor({
	output = internal,
	mode = "2880x1800@120.000",
	position = "-1920x240",
	scale = 1.5,
})

-- ── Workspace pins ──────────────────────────────────────────────────────
--
-- 1-5 on the MSI (main), 6-8 on the Gigabyte above it, 9-10 on the laptop
-- panel. Same selectors as the monitor rules, deliberately — one place to fix
-- if a panel is ever replaced. `default` on 1, 6 and 9 makes each monitor
-- start on its first bound workspace at login and on monitor-connect.
--
-- Why the laptop's own workspaces are pinned here rather than left implicit:
-- an unpinned monitor does NOT quietly inherit the low numbers, it gets
-- whatever is left over. That was live breakage until this file was written —
-- with the pins still naming the long-gone Dells, the MSI and Gigabyte
-- matched nothing and landed on workspaces 11 and 12, off the end of the
-- SUPER+1..0 binds entirely.
--
-- Undocked (laptop alone) is deliberately NOT special-cased: workspace 1
-- belongs to the absent MSI, so hyprland reassigns the orphans and eDP-1 comes
-- up on 9. Every number still works, they just all land on the one live
-- output. Not worth extra machinery — a second `default = true` for workspace
-- 1 wouldn't help anyway, since the FIRST matching rule wins and the second is
-- silently dropped.
for ws = 1, 5 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = main, default = (ws == 1) })
end
for ws = 6, 8 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = secondary, default = (ws == 6) })
end
for ws = 9, 10 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = internal, default = (ws == 9) })
end
