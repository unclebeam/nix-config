# home/wallpapers.nix — tracked wallpaper images, so a fresh install has
# them in the SUPER+Y picker without a manual copy (~7.5M of PNGs is fine in
# git; no LFS). Per-file store symlinks, not a directory link, so
# ~/Pictures/Wallpapers stays writable for ad-hoc machine-local additions.
# Only the images are declared — the wallpaper *choice* is DMS GUI state and
# picking one is a first-login step.
{ config, lib, pkgs, ... }:

{
  home.file."Pictures/Wallpapers/abandoned_buildings_1.png".source =
    ./wallpapers/abandoned_buildings_1.png;
  home.file."Pictures/Wallpapers/japanese_pedestrian_street.png".source =
    ./wallpapers/japanese_pedestrian_street.png;
}
