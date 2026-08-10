-- home/hypr/hosts/unclebeam-pc.lua — THIS machine's displays.
--
-- One file per host, and Nix picks which one gets symlinked to
-- ~/.config/hypr/host.lua (home/hyprland.nix, keyed on
-- osConfig.networking.hostName). So hyprland.lua carries NO hostname branch:
-- the other machine's rules are never even loaded here, which matters because
-- monitor-description rules for an ABSENT monitor are not no-ops — see the
-- thinkpad file for the workspace-default bug that caused.
--
-- Everything below is a HARDWARE FACT read off this machine with
-- `hyprctl monitors all` — never guessed. Tracked in git (safe now that Nix
-- only ever links this host's file), so a fresh install boots with the right
-- layout instead of falling back to auto-config. Still an out-of-store
-- symlink: edits apply on a bare `hyprctl reload`, no rebuild.

-- ── Monitors ────────────────────────────────────────────────────────────
--
-- Physical layout: the Dell sits stacked directly ON TOP of the Alienware,
-- both landscape (no transform).
--
--   ┌────────────────┐  Dell S2725QS   2560x1440 logical @ 0,-1440
--   └────────────────┘
--   ┌────────────────┐  Alienware AW2725Q  2560x1440 logical @ 0,0  (main)
--   └────────────────┘
--
-- Two conventions worth knowing before editing:
--
-- * Outputs are selected by `desc:` (the EDID description), NOT by the DP-n
--   connector: port numbers renumber across replugs and BIOS updates,
--   descriptions don't. `desc:` is compared with starts_with, so these
--   strings could be shortened, but the serials are kept in full to stay
--   unambiguous.
--
-- * `position` is in LOGICAL pixels, i.e. AFTER scale. Both panels are 4K
--   (3840x2160) at scale 1.5 => 2560x1440 logical each. So the top monitor
--   goes at y = -1440, not -2160; using the physical height is the classic
--   mistake that leaves a dead 720 px gap between the screens that the
--   cursor has to cross. x = 0 on both left-aligns the stack — they're the
--   same logical width, so the edges match exactly.
--
-- Modes are spelled out rather than left at "preferred"/auto: hyprland's
-- auto-config picks the first EDID mode, which on both of these panels is
-- 60 Hz — the whole point of a 240 Hz OLED is lost silently. If a mode ever
-- fails to link-train hyprland falls back and logs it, so check
-- `hyprctl monitors` after changing one.

-- Main: Alienware AW2725Q, 27" 4K QD-OLED, DP-1.
-- 4K240 needs DisplayPort 2.1 + DSC — fine on this box's RX 9070 XT (Navi
-- 48). If it ever refuses to train (cable swapped for a DP 1.4 one, say),
-- the next step down in the EDID list is 3840x2160@143.99.
-- vrr = 2 is fullscreen-only adaptive sync: games get it, the desktop
-- doesn't — deliberate, since always-on VRR (vrr = 1) can make OLED panels
-- flicker on a mostly-static desktop.
local main = "desc:Dell Inc. AW2725Q 4KTF174"
hl.monitor({
	output = main,
	mode = "3840x2160@239.99",
	position = "0x0",
	scale = 1.5,
	vrr = 2,
})

-- Above: Dell S2725QS, 27" 4K IPS, DP-2. 120 Hz is this panel's maximum.
-- No vrr here: it's the secondary/reference screen, nothing runs fullscreen
-- on it.
local secondary = "desc:Dell Inc. DELL S2725QS 3V7S364"
hl.monitor({
	output = secondary,
	mode = "3840x2160@120.00",
	position = "0x-1440",
	scale = 1.5,
})

-- ── Workspace pins ──────────────────────────────────────────────────────
--
-- 1-8 live on the Alienware (main, below), 9-10 on the Dell (above). Same
-- `desc:` selectors as the monitor rules, deliberately — one place to fix
-- if a panel is ever replaced. `default` on 1 and 9 makes each monitor start
-- on its first bound workspace at login and on monitor-connect.
--
-- The split ends at 10, not 9, because the binds in home/hypr/binds.lua run
-- SUPER+1..0 => workspaces 1..10: workspace 10 used to have no rule at all,
-- so SUPER+0 landed wherever hyprland felt like putting it. Every numbered
-- bind now names a pinned monitor. (Leftovers are not harmless — see the
-- thinkpad file, where unmatched pins put real monitors on workspaces 11/12,
-- off the end of the binds entirely.)
for ws = 1, 8 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = main, default = (ws == 1) })
end
for ws = 9, 10 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = secondary, default = (ws == 9) })
end
