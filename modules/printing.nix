# modules/printing.nix — driverless CUPS printing + SANE scanning for a
# network multifunction printer (IPP Everywhere / eSCL over the avahi mDNS
# discovery enabled in modules/nautilus.nix).
{ config, lib, pkgs, ... }:

{
  services.printing.enable = true;

  # Would default ON (keys off services.avahi.enable). Adds nothing with
  # driverless temporary queues, and was the vector for CVE-2024-47176 (an
  # unauthenticated UDP 631 listener). Discovery works without it.
  services.printing.browsed.enable = false;

  # No services.printing.drivers: IPP Everywhere needs none. Add a vendor
  # driver package here only if a legacy printer appears. Queue admin:
  # http://localhost:631.

  # eSCL/WSD scanning over the same mDNS discovery — covers the scanner half
  # of essentially every network MFP; stock SANE backends only know USB and
  # vendor protocols.
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.sane-airscan ];

  # SANE gates access on "scanner" ("lp" for MFPs reached via the printer
  # side); extraGroups merge across modules.
  users.users.unclebeam.extraGroups = [ "scanner" "lp" ];

  # Config-less scanning GUI, so it lives with the printing intent.
  environment.systemPackages = [ pkgs.simple-scan ];
}
