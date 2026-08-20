# ddc.nix — external-monitor brightness over DDC/CI (rides the GPU's I2C
# buses; externals have no kernel backlight). i2c-dev provides /dev/i2c-*
# and the group membership lets DMS drive them natively — without either,
# DDC silently doesn't work (no nodes, or EACCES = zero brightness devices).
# ddcutil is a debug tool only (`ddcutil detect` proves the bus works); the
# shell doesn't call it. DDC/CI must also be enabled in the monitor's OSD.
# The ThinkPad's internal panel keeps its kernel backlight (modules/laptop.nix).
{ config, lib, pkgs, ... }:

{
  hardware.i2c.enable = true;
  users.users.unclebeam.extraGroups = [ "i2c" ]; # merges with core.nix's list
  environment.systemPackages = [ pkgs.ddcutil ];
}
