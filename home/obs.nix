# home/obs.nix — OBS Studio. No modules/ half needed: screen capture goes
# through the GNOME portal (modules/niri.nix), audio rides PipeWire — so OBS
# is a plain user package. Deliberately not included until needed: virtual
# camera (needs the v4l2loopback kernel module, a system-level change) and
# programs.obs-studio (only earns its keep for wrapping plugins). Settings
# are app-owned in ~/.config/obs-studio.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ obs-studio ];
}
