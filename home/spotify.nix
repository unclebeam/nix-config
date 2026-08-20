# home/spotify.nix — Spotify desktop client. Unfree (allowUnfree applies to
# user packages via useGlobalPkgs). No mime handlers or theme block; settings
# are app-owned in ~/.config/spotify.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ spotify ];
}
