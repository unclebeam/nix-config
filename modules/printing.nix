# modules/printing.nix — CUPS printing + SANE scanning for a network
# multifunction printer. Everything is driverless: modern (post-~2010) network
# printers announce themselves over mDNS and speak IPP Everywhere, so CUPS
# needs no vendor driver — it creates a temporary queue the moment a print
# dialog enumerates destinations. The discovery layer this rides on (avahi +
# nssmdns4, UDP 5353 open) is already enabled in modules/dolphin.nix.
# Removing printing = delete this file + its import line in both hosts.
{ config, lib, pkgs, ... }:

{
  # ── Printing (CUPS) ────────────────────────────────────────────────────────
  services.printing.enable = true;

  # cups-browsed would default to ON here — its default is
  # config.services.avahi.enable, and dolphin.nix enables avahi. All it would
  # add is a permanent local queue for every printer it ever sees (unnecessary
  # with driverless temporary queues), and it was the vector for
  # CVE-2024-47176: an unauthenticated UDP 631 listener that accepted printer
  # announcements from anyone. Discovery works without it, so keep it off.
  services.printing.browsed.enable = false;

  # No services.printing.drivers: IPP Everywhere needs none. If a legacy
  # printer ever appears, add its driver package (hplip, brlaser, …) here.
  # Permanent queues / admin live in the CUPS web UI at http://localhost:631.

  # ── Scanning (SANE) ────────────────────────────────────────────────────────
  # sane-airscan is the scanning counterpart of driverless printing: eSCL
  # (Apple AirScan) + WSD over the same mDNS discovery. Covers the scanner
  # half of essentially every network multifunction printer; without it,
  # SANE's stock backends only know USB-attached and vendor-protocol devices.
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.sane-airscan ];

  # SANE gates device access on the "scanner" group ("lp" too, for
  # multifunction devices reached through the printer side). extraGroups
  # lists merge across modules (same pattern as hosts/unclebeam-pc's "i2c").
  users.users.unclebeam.extraGroups = [ "scanner" "lp" ];

  # Scanning GUI — the KDE app, matching the Dolphin/Ark app layer. It is
  # config-less, so it lives here with the rest of the printing/scanning
  # intent instead of a home/ file (one file per intent; nothing user-level
  # to split out).
  environment.systemPackages = [ pkgs.kdePackages.skanlite ];
}
