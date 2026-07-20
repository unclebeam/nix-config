# laptop.nix — ThinkPad power management and lid/backlight behavior.
{ config, lib, pkgs, ... }:

{
  # ── Power management ────────────────────────────────────────────────────
  # power-profiles-daemon (the current best practice for modern Intel
  # laptops — it drives the platform's own EPP profiles instead of
  # micromanaging knobs like TLP) now comes from the DMS module
  # (modules/dms.nix, both hosts): DMS's battery widget is what switches
  # profiles. The CLI still works too:
  #   powerprofilesctl set power-saver|balanced|performance

  # Firmware/microcode for the Intel CPU (Spectre-class fixes, errata).
  hardware.cpu.intel.updateMicrocode = true;

  # ── Lid & suspend ──────────────────────────────────────────────────────
  # logind handles the lid; DMS (home/dms.nix) listens for the suspend
  # signal and locks the session before the sleep actually happens.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend"; # also suspend when plugged in
    HandleLidSwitchDocked = "ignore";         # external monitor = keep running
  };

  # ── Backlight ──────────────────────────────────────────────────────────
  # The XF86 brightness keys go through `dms ipc` (the DMS-managed binds in
  # ~/.config/hypr/dms/binds.lua);
  # brightness handling is built into the dms binary, which talks to logind
  # — no extra permissions or udev rules needed for users with an active
  # session.

  # ── Firmware updates ───────────────────────────────────────────────────
  # ThinkPads publish firmware on LVFS. When you want firmware updates,
  # uncomment and run: fwupdmgr refresh && fwupdmgr update
  # services.fwupd.enable = true;
}
