# home/obs.nix — OBS Studio, screen recording / streaming.
# One file per intent: everything that exists because of OBS lives here.
# Removing OBS = delete this file + its import line in default.nix.
#
# No system-side (modules/) half needed: screen capture on niri goes through
# xdg-desktop-portal-gnome (pulled in by programs.niri.enable in
# modules/niri.nix — the only screencast backend niri supports; capture is
# the one interface that deliberately stayed GNOME through the 2026-07
# KDE-plumbing migration), and audio
# capture rides the PipeWire stack from modules/audio.nix. Both are already
# there for other reasons, so OBS is a plain user package.
#
# Deliberately NOT included until actually needed:
#   - virtual camera: needs the v4l2loopback kernel module (a system-level
#     change in the host/module layer), so it can't be flipped on from here.
#   - programs.obs-studio (home-manager module): only earns its keep for
#     wrapping OBS with plugins; with zero plugins it's just indirection.
# OBS's own settings live in ~/.config/obs-studio, managed by the app itself,
# not Nix — same rule as the editor configs.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ obs-studio ];
}
