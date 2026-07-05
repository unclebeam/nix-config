# solaar.nix — Solaar, the manager for Logitech mice/keyboards
# (Unifying/Bolt receivers and Bluetooth): pair devices, check battery,
# remap buttons, tweak DPI.
{ config, lib, pkgs, ... }:

{
  # One option group covers the whole intent. `enable` installs the udev
  # rules that let a plain user talk to the receiver over hidraw — without
  # them Solaar starts but sees no devices (or demands root). `enableGraphical`
  # adds the Solaar app itself on top of the rules.
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
}
