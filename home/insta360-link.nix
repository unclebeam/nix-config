# home/insta360-link.nix — control tools for the Insta360 Link 2 Pro webcam,
# a standard UVC device. Deliberately NO modules/ half: uvcvideo auto-loads,
# logind's uaccess tag grants /dev/video* (plus the "video" group), no udev
# rules needed — so these are plain user packages, inert on a machine
# without the camera.
#
# The gimbal is standard UVC controls; v4l2-ctl units are arc-seconds
# (1 degree = 3600, pan range ±522000):
#   v4l2-ctl -d /dev/video0 --set-ctrl pan_absolute=36000    # +10°
#   v4l2-ctl -d /dev/video0 --set-ctrl tilt_absolute=-18000  # −5°
#   v4l2-ctl -d /dev/video0 --set-ctrl zoom_absolute=150     # 1.5× (100–400)
#   v4l2-ctl -d /dev/video0 --list-ctrls-menus               # everything
#
# App-only toggles (HDR, tracking target, virtual backgrounds) persist
# on-camera once set from the Windows/Mac app; tracking runs onboard (palm
# gesture toggles, touch key recenters); firmware updates via U-Disk mode
# (triple-tap + hold → USB storage). Quirk: ~10 s after the last app closes
# the stream, the camera enters privacy mode (lens down); reopening wakes it.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    v4l-utils # v4l2-ctl: scriptable pan/tilt/zoom + control inspection
    # GTK4 GUI: PTZ sliders, saveable presets, optional restore-on-reconnect
    # daemon. Generic UVC — exactly the protocol this camera speaks.
    cameractrls-gtk4
  ];
}
