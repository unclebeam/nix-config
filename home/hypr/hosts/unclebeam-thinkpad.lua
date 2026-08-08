-- home/hypr/hosts/unclebeam-thinkpad.lua — THIS machine's displays.
--
-- One file per host, and Nix picks which one gets symlinked to
-- ~/.config/hypr/host.lua (home/hyprland.nix, keyed on
-- osConfig.networking.hostName). So hyprland.lua carries NO hostname branch,
-- and the PC's rules are never loaded on this machine — which used to matter
-- a lot: see the absent-monitor note below.

-- ── Monitors ────────────────────────────────────────────────────────────
--
-- TODO(hardware facts): no `hl.monitor()` lines yet. Resolution, scale,
-- position and VRR are HARDWARE FACTS that must be read off this machine —
-- CLAUDE.md's never-invent rule — and they haven't been captured yet. With
-- this section empty hyprland just uses auto monitor config, which is
-- exactly the behaviour this machine has today, so nothing regresses.
--
-- To fill it in, ON THE THINKPAD:
--   hyprctl monitors all
-- then write one hl.monitor({ output = "desc:…", mode = …, position = …,
-- scale = … }) per panel, mirroring hosts/unclebeam-pc.lua. Remember
-- `position` is in LOGICAL pixels (after scale), and select externals by
-- `desc:` rather than the DP-n connector — dock ports renumber.
--
-- Docking is not a problem for a tracked file: a monitor rule for an output
-- that isn't plugged in is simply never applied, so one file can describe
-- the docked panels and still be correct when undocked.

-- ── Workspace pins ──────────────────────────────────────────────────────
--
-- 1-5 on the built-in panel, 6-10 on the docked Dell above it.
--
-- eDP-1 by connector (built-in, never renumbers); the Dell by description
-- (USB-C dock ports do renumber — the U3225QE came up as DP-5, the U2725QE
-- as DP-1).
--
-- `desc:` is a PREFIX, deliberately: it's compared with starts_with
-- (hyprland's CMonitor::matchesStaticSelector), so "Dell Inc. DELL U"
-- catches whichever docked Dell is plugged in — U3225QE 27D4834 or
-- U2725QE 5R1YC34. Two rules for the same workspace would NOT work as an
-- alternative: the FIRST match wins and the second is silently dropped, so
-- the absent monitor's rule would win half the time.
--
-- Why the internal panel's own workspaces are pinned here rather than left
-- implicit: workspace rules naming an ABSENT monitor are not no-ops. Back
-- when both hosts' rules lived in one hostname-branched file and the guard
-- was removed, the PC's rules claimed workspaces 1-9 as belonging elsewhere
-- and eDP-1's default became 10 instead of 1. Per-host files make that
-- class of bug structurally impossible now, but pinning 1-5 explicitly is
-- still what keeps eDP-1's default at 1 when the Dell is unplugged (its
-- workspaces just fall back to eDP-1).
local internal = "eDP-1"
local external = "desc:Dell Inc. DELL U"

for ws = 1, 5 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = internal, default = (ws == 1) })
end
for ws = 6, 10 do
	hl.workspace_rule({ workspace = tostring(ws), monitor = external, default = (ws == 6) })
end
