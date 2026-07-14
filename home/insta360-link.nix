# home/insta360-link.nix — control tools for the Insta360 Link 2 Pro webcam.
# One file per intent: everything that exists because of this camera lives here.
# Removing it = delete this file + its import line in default.nix.
#
# The camera (USB 2e1a:4c06) is a standard UVC device — Insta360 officially
# supports Linux via UVC/UAC, they just don't ship their Link Controller app
# for it. So there is deliberately NO modules/ half:
#   - driver: uvcvideo is in-tree and auto-loads, nothing to enable
#   - permissions: logind's uaccess tag grants the seated user /dev/video*,
#     and the user is in the "video" group anyway (modules/core.nix)
#   - udev rules: none needed
# That also means these are plain user packages, fine to share across hosts —
# on a machine without the camera they're inert.
#
# The gimbal is exposed as standard UVC controls, so both tools below drive
# it directly. Units cheat-sheet for v4l2-ctl (UVC pan/tilt are arc-seconds):
#   1 degree = 3600            pan range ±522000 (±145°)
#   v4l2-ctl -d /dev/video0 --set-ctrl pan_absolute=36000    # +10°
#   v4l2-ctl -d /dev/video0 --set-ctrl tilt_absolute=-18000  # −5°
#   v4l2-ctl -d /dev/video0 --set-ctrl zoom_absolute=150     # 1.5× (100–400)
#   v4l2-ctl -d /dev/video0 --list-ctrls-menus               # everything
#
# What Nix/Linux can't reach: app-only toggles (HDR, tracking-target choice,
# virtual backgrounds) live in the Windows/Mac app but persist on-camera once
# set. Tracking itself runs ONBOARD — palm gesture toggles it, touch key
# recenters — and firmware updates work OS-agnostically via the camera's
# U-Disk mode (triple-tap + hold → mounts as USB storage).
#
# Quirk to know: ~10 s after the last app closes the stream, the camera
# enters privacy mode (lens points down). It wakes when any app reopens it.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    v4l-utils # v4l2-ctl: scriptable pan/tilt/zoom + control inspection
    # GTK4 GUI: PTZ sliders, saveable presets, optional restore-on-reconnect
    # daemon. Generic UVC (no Insta360-specific code) — exactly the protocol
    # this camera speaks.
    cameractrls-gtk4
  ];
}
