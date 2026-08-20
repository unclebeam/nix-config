# zsa.nix — udev rules for ZSA keyboards. No app: flashing/training happen in
# the browser via Oryx (WebUSB/WebHID); these rules let a plain user open the
# hidraw/DFU devices — without them Oryx can't see the board.
{ config, lib, pkgs, ... }:

{
  # The packaged rules tag devices with systemd's `uaccess`, so the logged-in
  # user gets access automatically — no plugdev group, despite ZSA's
  # generic-Linux wiki instructions. Replug the keyboard after switching.
  hardware.keyboard.zsa.enable = true;
}
