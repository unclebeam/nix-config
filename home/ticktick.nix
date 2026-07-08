# home/ticktick.nix — TickTick task-management client.
# One file per intent: everything that exists because of TickTick lives here.
# Removing TickTick = delete this file + its import line in default.nix —
# PLUS the small SUPER+O scratchpad blocks it owns in home/sway.nix and
# home/hypr/hyprland.lua (kept next to obsidian's, the same split obsidian
# has). Grep "ticktick" across home/ to find them.
#
# Unfree package — covered by the allowUnfree set in modules/core.nix
# (home-manager runs with useGlobalPkgs, so the system nixpkgs config
# applies here too; no per-file allowUnfree needed).
#
# No mime handlers and no Qt block: TickTick doesn't own any file types
# worth claiming. Login and task data live in ~/.config/TickTick, managed
# by the app itself, not Nix.
{ config, lib, pkgs, ... }:

let
  # TickTick ships a PREBUILT electron bundle (nixpkgs just unpacks the
  # upstream .deb), so it carries its own electron that ignores
  # NIXOS_OZONE_WL — the global var in modules/desktop.nix only steers
  # nixpkgs' OWN electron builds (obsidian, slack…). Left alone TickTick
  # falls back to XWayland, which blurs under our 1.5/1.25 fractional
  # scaling and exposes no app_id for a window rule to match.
  #
  # So force it — the same native-Wayland story obsidian gets for free,
  # just made explicit on the bundled binary:
  #   --ozone-platform-hint=auto → use Wayland when present, fall back to
  #     X11 if not (safe: never worse than today).
  #   --class=ticktick → pin the window identity to a stable "ticktick"
  #     (app_id under Wayland, WM_CLASS under X11) so the SUPER+O scratchpad
  #     rule + bind in home/sway.nix and home/hypr/hyprland.lua have a
  #     deterministic match instead of whatever electron would default to.
  # The package wraps its binary with wrapGAppsHook3, which reads the
  # gappsWrapperArgs array at fixup time — appending there re-wraps
  # bin/ticktick, and the generated .desktop Exec points at that same
  # binary, so launcher, CLI and keybind launches all inherit the flags.
  ticktick = pkgs.ticktick.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      gappsWrapperArgs+=(
        --add-flags "--ozone-platform-hint=auto"
        --add-flags "--class=ticktick"
      )
    '';
  });
in
{
  home.packages = [ ticktick ];
}
