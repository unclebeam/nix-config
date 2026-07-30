# ddc.nix — external-monitor brightness over DDC/CI.
#
# External monitors have no kernel backlight — brightness is set over
# DDC/CI, which rides the GPU's I2C buses. hardware.i2c loads the i2c-dev
# module and udev-tags /dev/i2c-* into the "i2c" group; the membership
# below plus the ddcutil package let Noctalia (which shells out to
# ddcutil, unlike dms's native DDC) talk to the monitors, so the shell's
# brightness slider / `noctalia msg brightness-*` drive them. Without
# any of the three halves, DDC silently doesn't work: no i2c-dev = no
# /dev/i2c-* nodes at all, no group = EACCES and zero brightness devices,
# no ddcutil = nothing for the shell to call. DDC/CI must also be
# enabled in each monitor's own OSD menu (usually is by default).
#
# Started host-level on the PC (two DDC monitors, no panel); promoted to a
# shared module when the ThinkPad's docked Dell became the second consumer.
# DDC only covers externals — the ThinkPad's internal panel keeps using its
# kernel backlight via logind (see modules/laptop.nix), no DDC involved.
{ config, lib, pkgs, ... }:

{
  hardware.i2c.enable = true;
  users.users.unclebeam.extraGroups = [ "i2c" ]; # merges with core.nix's list
  environment.systemPackages = [ pkgs.ddcutil ];
}
