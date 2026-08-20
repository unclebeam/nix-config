# laptop.nix — ThinkPad power management and lid/backlight behavior.
# power-profiles-daemon comes from the DMS module's mkDefault; the shell's
# battery widget switches profiles (CLI: powerprofilesctl).
{ config, lib, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = true;

  # logind handles the lid; DMS's idle policy locks around suspend (timeouts
  # live in its GUI-owned settings.json).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend"; # also suspend when plugged in
    HandleLidSwitchDocked = "ignore";         # external monitor = keep running
  };

  # Backlight: XF86 keys go through `dms ipc call brightness …`
  # (home/niri/config.kdl); the shell talks to logind, no udev rules needed.
  # External DDC monitors are modules/ddc.nix's concern.

  # ThinkPads publish firmware on LVFS. When wanted, uncomment and run:
  # fwupdmgr refresh && fwupdmgr update
  # services.fwupd.enable = true;
}
