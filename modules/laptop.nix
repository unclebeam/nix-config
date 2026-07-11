# laptop.nix — ThinkPad power management and lid/backlight behavior.
{ config, lib, pkgs, ... }:

{
  # ── Power management ────────────────────────────────────────────────────
  # power-profiles-daemon is the current best practice for modern Intel
  # laptops (Core Ultra / Lunar Lake): it drives the platform's own power
  # profiles (EPP) instead of micromanaging knobs like TLP does. The two
  # conflict — NixOS asserts you only enable one.
  # Switch profiles with: powerprofilesctl set power-saver|balanced|performance
  services.power-profiles-daemon.enable = true;

  # Firmware/microcode for the Intel CPU (Spectre-class fixes, errata).
  hardware.cpu.intel.updateMicrocode = true;

  # ── Lid & suspend ──────────────────────────────────────────────────────
  # logind handles the lid; swayidle (home/niri.nix, before-sleep hook)
  # locks the session before the suspend actually happens.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend"; # also suspend when plugged in
    HandleLidSwitchDocked = "ignore";         # external monitor = keep running
  };

  # ── Backlight ──────────────────────────────────────────────────────────
  # brightnessctl (installed in home/niri.nix, bound to the XF86
  # brightness keys) talks to logind — no extra permissions or udev rules
  # needed for users with an active session.

  # ── Firmware updates ───────────────────────────────────────────────────
  # ThinkPads publish firmware on LVFS. When you want firmware updates,
  # uncomment and run: fwupdmgr refresh && fwupdmgr update
  # services.fwupd.enable = true;
}
