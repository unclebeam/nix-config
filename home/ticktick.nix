# home/ticktick.nix — TickTick task-management client.
# One file per intent: everything that exists because of TickTick lives here.
# Removing TickTick = delete this file + its import line in default.nix.
#
# Unfree package — covered by the allowUnfree set in modules/core.nix
# (home-manager runs with useGlobalPkgs, so the system nixpkgs config
# applies here too; no per-file allowUnfree needed).
#
# No mime handlers and no Qt block: TickTick is Electron-based (runs fine
# under XWayland) and doesn't own any file types worth claiming. Login
# and task data live in ~/.config/TickTick, managed by the app itself,
# not Nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ ticktick ];
}
