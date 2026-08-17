# ddc.nix — external-monitor brightness over DDC/CI.
#
# External monitors have no kernel backlight — brightness is set over
# DDC/CI, which rides the GPU's I2C buses. hardware.i2c loads the i2c-dev
# module and udev-tags /dev/i2c-* into the "i2c" group; the membership
# below is what lets DMS — which speaks DDC NATIVELY over those device
# nodes (no ddcutil shell-out, unlike noctalia before it) — drive the
# monitors from its brightness slider / `dms ipc call brightness …`.
# Without either kernel half, DDC silently doesn't work: no i2c-dev = no
# /dev/i2c-* nodes at all, no group = EACCES and zero brightness devices.
# ddcutil is demoted to a debug tool (`ddcutil detect` is still the
# fastest way to prove the bus works when a monitor won't dim) — the
# shell no longer calls it. DDC/CI must also be enabled in each monitor's
# own OSD menu (usually is by default).
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
