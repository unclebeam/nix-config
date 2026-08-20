# solaar.nix — Solaar, manager for Logitech mice/keyboards (Unifying/Bolt
# receivers and Bluetooth): pairing, battery, button remaps, DPI.
{ config, lib, pkgs, ... }:

{
  # `enable` installs the udev rules that let a plain user talk to the
  # receiver over hidraw — without them Solaar sees no devices;
  # `enableGraphical` adds the app.
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # The Bolt receiver fires spurious USB remote-wakeup events (RF noise /
  # mouse micro-motion), resuming the PC seconds after suspend and leaving
  # the lock screen burning on the OLED. Disable wake-by-mouse; keyboard and
  # power button still wake. Keyed on vendor:product so it survives
  # replugging elsewhere.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';
}
