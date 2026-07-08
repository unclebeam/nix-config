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
  # greetd is our display manager (modules/desktop.nix), so the PAM hook goes on
  # its service. pam_kwallet6 creates the wallet on first login if none exists.
  security.pam.services.greetd.kwallet.enable = true;

  # ── Removable media (USB sticks, SD cards, cameras-as-USB-drives) ────────
  # udisks2 is the D-Bus mount daemon Dolphin's Solid backend talks to. Without
  # it, the kernel sees a plugged-in USB stick (usb_storage) but nothing exposes
  # it to Dolphin — no sidebar entry, no way to mount. Enabling it is what makes
  # removable drives appear at all. Its default polkit rules already let an
  # active local-session user mount without a password, so nothing else is
  # needed here. The *automatic* mount-on-insert half is udiskie, a session
  # service in home/dolphin.nix — udisks2 only exposes and permits the mount.
  services.udisks2.enable = true;

  # Let udisks2 actually mount non-native filesystems. FAT is always supported
  # and exfat rides along in the kernel, but NTFS (how most Windows-formatted
  # sticks and plenty of cameras format their storage) needs the ntfs-3g driver
  # — without it such drives fail to mount with a cryptic error. Listing both
  # is explicit and cheap.
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
}
