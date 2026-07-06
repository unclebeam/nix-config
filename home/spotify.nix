# home/spotify.nix — Spotify desktop client.
# One file per intent: everything that exists because of Spotify lives here.
# Removing Spotify = delete this file + its import line in default.nix.
#
# Unfree package — covered by the allowUnfree set in modules/core.nix
# (home-manager runs with useGlobalPkgs, so the system nixpkgs config
# applies here too; no per-file allowUnfree needed).
#
# No mime handlers and no Qt block: Spotify is Electron-based (runs fine
# under XWayland) and doesn't own any file types worth claiming. Login
# and playback settings live in ~/.config/spotify, managed by the app
# itself, not Nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ spotify ];
}
