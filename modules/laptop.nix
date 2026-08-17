# laptop.nix — ThinkPad power management and lid/backlight behavior.
{ config, lib, pkgs, ... }:

{
  # ── Power management ────────────────────────────────────────────────────
  # power-profiles-daemon (the current best practice for modern Intel
  # laptops — it drives the platform's own EPP profiles instead of
  # micromanaging knobs like TLP) comes from the DMS module's mkDefault
  # (via modules/dms.nix, both hosts): the shell's battery widget is what
  # switches profiles. The CLI still works too:
  #   powerprofilesctl set power-saver|balanced|performance

  # Firmware/microcode for the Intel CPU (Spectre-class fixes, errata).
  hardware.cpu.intel.updateMicrocode = true;

  # ── Lid & suspend ──────────────────────────────────────────────────────
  # logind handles the lid; DMS's idle policy locks the session around
  # suspend (lock-before-suspend + the idle timeouts live in its GUI-owned
  # settings.json — a per-machine first-login step, see CLAUDE.md).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend"; # also suspend when plugged in
    HandleLidSwitchDocked = "ignore";         # external monitor = keep running
  };

  # ── Backlight ──────────────────────────────────────────────────────────
  # The XF86 brightness keys go through `dms ipc call brightness …`
  # (home/niri/config.kdl); brightness handling is built into the shell,
  # which talks to logind — no extra permissions or udev rules needed for
  # users with an active session. (External DDC monitors — including the
  # docked Dell here — are modules/ddc.nix's concern.)

  # ── Firmware updates ───────────────────────────────────────────────────
  # ThinkPads publish firmware on LVFS. When you want firmware updates,
  # uncomment and run: fwupdmgr refresh && fwupdmgr update
  # services.fwupd.enable = true;
}
