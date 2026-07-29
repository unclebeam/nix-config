# laptop.nix — ThinkPad power management and lid/backlight behavior.
{ config, lib, pkgs, ... }:

{
  # ── Power management ────────────────────────────────────────────────────
  # power-profiles-daemon (the current best practice for modern Intel
  # laptops — it drives the platform's own EPP profiles instead of
  # micromanaging knobs like TLP) comes from modules/noctalia.nix (both
  # hosts): the shell's power widget is what switches profiles. The CLI
  # still works too:
  #   powerprofilesctl set power-saver|balanced|performance

  # Firmware/microcode for the Intel CPU (Spectre-class fixes, errata).
  hardware.cpu.intel.updateMicrocode = true;

  # ── Lid & suspend ──────────────────────────────────────────────────────
  # logind handles the lid; Noctalia's idle service locks the session
  # around suspend (lock-before-suspend is part of the [idle] policy in
  # home/noctalia/config.toml).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend"; # also suspend when plugged in
    HandleLidSwitchDocked = "ignore";         # external monitor = keep running
  };

  # ── Backlight ──────────────────────────────────────────────────────────
  # The XF86 brightness keys go through `noctalia msg brightness-up/-down`
  # (home/hypr/binds.lua); brightness handling is built into the shell,
  # which talks to logind — no extra permissions or udev rules needed for
  # users with an active session. (External DDC monitors are the PC's
  # concern — see hosts/unclebeam-pc.)

  # ── Firmware updates ───────────────────────────────────────────────────
  # ThinkPads publish firmware on LVFS. When you want firmware updates,
  # uncomment and run: fwupdmgr refresh && fwupdmgr update
  # services.fwupd.enable = true;
}
