# modules/nautilus.nix — the SYSTEM half of Nautilus (the app itself lives
# in home/nautilus.nix). Everything here is here because only NixOS — not
# home-manager — can set it. (Replaced modules/dolphin.nix 2026-08 when the
# file manager went back to GNOME; the keyring followed later that month —
# gnome-keyring (modules/gnome-keyring.nix) owns org.freedesktop.secrets,
# and gvfs's "remember password" lands there via libsecret. The pre-Dolphin
# version of this file carried its own gnome-keyring PAM line — still do
# not resurrect it here: keyring wiring lives in the keyring module, one
# file per intent, not in the file manager's.)
{ config, lib, pkgs, ... }:

{
  # gvfs is what gives Nautilus anything beyond the local filesystem:
  # smb:// and sftp:// browsing, trash://, MTP devices — plus the FUSE
  # bridge (/run/user/*/gvfs) that exposes those mounts as plain paths so
  # non-GTK apps can open files picked off a network share. This is the
  # whole job KIO + kio-extras + kio-fuse did as user packages under
  # Dolphin, in one switch. It must be system-side: the module installs the
  # daemons AND their D-Bus/systemd activation units — a bare package in
  # home.packages would put binaries on PATH that nothing ever activates.
  # (The default package is the full gnome build: SMB compiled in, and
  # libsecret for saved share credentials — which flow to gnome-keyring,
  # unlocked at login by pam_gnome_keyring (modules/gnome-keyring.nix), so
  # "remember password" survives relogin with no extra wiring.)
  services.gvfs.enable = true;

  # mDNS/DNS-SD discovery: Nautilus's "Other Locations" view lists SMB
  # servers that announce themselves via mDNS (Linux/macOS/NAS boxes).
  # Typing smb://host/share directly works even without this — avahi is
  # only for discovery. openFirewall defaults to true, so UDP 5353 is
  # opened. (modules/printing.nix leans on this block too: cups-browsed's
  # default is `config.services.avahi.enable` — if the file manager ever
  # moves again, avahi needs a new home, not deletion.)
  services.avahi = {
    enable = true;
    nssmdns4 = true; # also resolve <host>.local names system-wide via NSS
  };

  # ── Removable media (USB sticks, SD cards, cameras-as-USB-drives) ────────
  # udisks2 is the D-Bus mount daemon that Nautilus's sidebar (via gvfs's
  # volume monitor) and udiskie both talk to. Without it, the kernel sees a
  # plugged-in USB stick (usb_storage) but nothing exposes it — no sidebar
  # entry, no way to mount. Its default polkit rules already let an active
  # local-session user mount without a password, so nothing else is needed
  # here. The *automatic* mount-on-insert half is udiskie, a session service
  # in home/nautilus.nix — udisks2 only exposes and permits the mount.
  # (services.gvfs would enable udisks2 anyway; kept explicit because
  # udiskie depends on udisks2 directly, not on gvfs.)
  services.udisks2.enable = true;

  # Let udisks2 actually mount non-native filesystems. FAT is always supported
  # and exfat rides along in the kernel, but NTFS (how most Windows-formatted
  # sticks and plenty of cameras format their storage) needs the ntfs-3g driver
  # — without it such drives fail to mount with a cryptic error. Listing both
  # is explicit and cheap.
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
}
