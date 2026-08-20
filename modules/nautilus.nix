# modules/nautilus.nix — system half of Nautilus (the app lives in
# home/nautilus.nix); everything here only NixOS can set. Keyring wiring
# stays in modules/gnome-keyring.nix — one file per intent.
{ config, lib, pkgs, ... }:

{
  # gvfs gives Nautilus everything beyond the local filesystem: smb://,
  # sftp://, trash://, MTP, plus the FUSE bridge (/run/user/*/gvfs) that lets
  # non-GTK apps open files from network shares. Must be system-side: the
  # module installs daemons AND their D-Bus/systemd activation units — a bare
  # package in home.packages would never be activated. "Remember password"
  # lands in gnome-keyring via libsecret, unlocked at login.
  services.gvfs.enable = true;

  # mDNS/DNS-SD discovery for "Other Locations"; direct smb://host/share works
  # without it. openFirewall defaults true (UDP 5353). NB: cups-browsed's
  # default keys off services.avahi.enable and modules/printing.nix leans on
  # this block — if the file manager ever moves, avahi needs a new home, not
  # deletion.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # resolve <host>.local system-wide via NSS
  };

  # D-Bus mount daemon for removable media; without it a plugged-in stick is
  # never exposed. Default polkit rules already let an active local user mount
  # without a password. Auto-mount-on-insert is udiskie (home/nautilus.nix).
  # gvfs would enable this anyway; explicit because udiskie depends on udisks2
  # directly, not on gvfs.
  services.udisks2.enable = true;

  # NTFS needs ntfs-3g or Windows-formatted sticks fail with a cryptic error;
  # exfat listed for explicitness.
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
}
