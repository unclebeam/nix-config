# modules/nautilus.nix — the SYSTEM half of Nautilus (the app itself lives
# in home/nautilus.nix). Everything here is here because only NixOS — not
# home-manager — can set it:
{ config, lib, pkgs, ... }:

{
  # gvfs is what gives Nautilus anything beyond the local filesystem:
  # smb:// and sftp:// browsing, the trash:// backend, MTP devices. It's a
  # set of D-Bus-activated user daemons plus a FUSE bridge (/run/user/*/gvfs)
  # that exposes those mounts as plain paths, so non-GTK apps can open files
  # you pick from a network share. This is KIO+kio-fuse's whole job, in one
  # switch. NB: must be system-side — the NixOS module installs the daemons
  # AND their D-Bus/systemd service files; a bare package in home.packages
  # would put binaries on PATH that nothing ever activates.
  services.gvfs.enable = true;

  # mDNS/DNS-SD discovery: Nautilus's "Other Locations" view lists SMB
  # servers that announce themselves via mDNS (Linux/macOS/NAS boxes).
  # Typing smb://host/share directly works even without this — avahi is only
  # for discovery. openFirewall defaults to true, so UDP 5353 is opened.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # also resolve <host>.local names system-wide via NSS
  };

  # Auto-unlock gnome-keyring at login with the login password, so the SMB
  # credentials Nautilus saves there ("remember password") don't trigger a
  # second prompt every session. The keyring daemon itself is already
  # enabled by programs.niri (it backs the Secret portal); this is only the
  # PAM half, and it goes on sddm because that's our display manager
  # (modules/desktop.nix). Same job pam_kwallet6 did for Dolphin.
  security.pam.services.sddm.enableGnomeKeyring = true;

  # ── Removable media (USB sticks, SD cards, cameras-as-USB-drives) ────────
  # udisks2 is the D-Bus mount daemon gvfs's volume monitor talks to. Without
  # it, the kernel sees a plugged-in USB stick (usb_storage) but nothing
  # exposes it to Nautilus — no sidebar entry, no way to mount. Its default
  # polkit rules already let an active local-session user mount without a
  # password, so nothing else is needed here. The *automatic* mount-on-insert
  # half is udiskie, a session service in home/nautilus.nix — udisks2 only
  # exposes and permits the mount.
  services.udisks2.enable = true;

  # Let udisks2 actually mount non-native filesystems. FAT is always supported
  # and exfat rides along in the kernel, but NTFS (how most Windows-formatted
  # sticks and plenty of cameras format their storage) needs the ntfs-3g driver
  # — without it such drives fail to mount with a cryptic error. Listing both
  # is explicit and cheap.
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
}
