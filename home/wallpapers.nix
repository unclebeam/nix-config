# home/wallpapers.nix — the wallpaper images, tracked in the repo.
# One file per intent: the images live in home/wallpapers/ and this module
# places them; removing wallpapers = delete this file, home/wallpapers/,
# and the import line in default.nix.
#
# Why track binary images in a Nix repo at all: a fresh nixos-anywhere
# install (or the other machine) should have the same wallpapers available
# in the SUPER+Y picker without a manual copy step. ~7.5M of PNGs is fine
# to carry in git directly — no LFS.
#
# Store symlinks (same rule as tmux.conf): images never change in place,
# so read-only is fine and adding/replacing one goes through a rebuild.
# Deliberately PER-FILE, not a recursive link of the whole directory:
# ~/Pictures/Wallpapers itself stays an ordinary writable dir, so ad-hoc
# machine-local wallpapers can still be dropped in by hand next to these.
#
# NOTE: only the images are declared here. The wallpaper *choice* is
# machine-local GUI state (~/.local/state/noctalia/settings.toml) — picking
# one via SUPER+Y remains the documented first-login step.
{ config, lib, pkgs, ... }:

{
  home.file."Pictures/Wallpapers/abandoned_buildings_1.png".source =
    ./wallpapers/abandoned_buildings_1.png;
  home.file."Pictures/Wallpapers/japanese_pedestrian_street.png".source =
    ./wallpapers/japanese_pedestrian_street.png;
}
