# modules/dolphin.nix — the SYSTEM half of Dolphin (the app itself, its
# packages and theming live in home/dolphin.nix). Only two things here,
# because only NixOS — not home-manager — can set them:
{ config, lib, pkgs, ... }:

{
  # mDNS/DNS-SD discovery: Dolphin's Network view lists SMB servers that
  # announce themselves via mDNS (Linux/macOS/NAS boxes; Windows machines
  # appear via WS-Discovery, which kio-extras speaks on its own). Typing
  # smb://host/share directly works even without this — avahi is only for
  # discovery. openFirewall defaults to true, so UDP 5353 is opened for us.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # also resolve <host>.local names system-wide via NSS
  };

  # Auto-unlock KWallet at login with the login password, so Dolphin's saved
  # SMB credentials don't trigger a second password prompt every session.
  # greetd is our display manager (modules/sway.nix), so the PAM hook goes on
  # its service. pam_kwallet6 creates the wallet on first login if none exists.
  security.pam.services.greetd.kwallet.enable = true;
}
