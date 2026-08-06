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

  # The Bolt receiver's USB remote-wakeup is on by kernel default, and the
  # receiver fires spurious wake events (RF noise / mouse micro-motion) —
  # on 2026-08-05 the PC resumed seconds after Lock & Suspend with the
  # receiver as the only wakeup source showing active_count > 0, leaving
  # the lock screen burning on the OLED. Disable wake-by-mouse; the ZSA
  # keyboard and the power button still wake the machine. Keyed on
  # vendor:product (not USB path) so it survives replugging elsewhere.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';
}
