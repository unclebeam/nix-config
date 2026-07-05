# zsa.nix — udev rules for ZSA keyboards (Voyager, Moonlander, ErgoDox EZ).
# No app is installed: flashing and live training happen in the browser via
# Oryx (https://configure.zsa.io), which talks WebUSB/WebHID — works in Brave.
# These rules are what let a plain user open the keyboard's hidraw and DFU
# devices; without them Oryx can't see the board and flashing would need root.
{ config, lib, pkgs, ... }:

{
  # Installs zsa-udev-rules (50-oryx.rules + 50-wally.rules) into udev.
  # The packaged rules tag the devices with systemd's `uaccess`, so the
  # physically logged-in user is granted access automatically — no plugdev
  # group needed, despite what ZSA's generic-Linux wiki instructions say
  # (those predate the uaccess rules). Replug the keyboard after switching.
  hardware.keyboard.zsa.enable = true;
}
