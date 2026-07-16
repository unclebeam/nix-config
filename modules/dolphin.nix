# modules/dolphin.nix — the SYSTEM half of Dolphin (the app itself lives in
# home/dolphin.nix). Everything here is here because only NixOS — not
# home-manager — can set it. Notably SMALLER than the old modules/nautilus.nix:
# there is deliberately NO services.gvfs here — Dolphin's remote-protocol
# layer is KIO (kio-extras + kio-fuse), which ships as plain user packages in
# home/dolphin.nix and needs no system daemon. (The keyring PAM unlock that
# used to live here now lives in modules/kwallet.nix with the rest of the
# keyring — it never belonged to the file manager.)
{ config, lib, pkgs, ... }:

{
  # mDNS/DNS-SD discovery: Dolphin's Network view lists SMB servers that
  # announce themselves via mDNS (Linux/macOS/NAS boxes). Typing
  # smb://host/share directly works even without this — avahi is only for
  # discovery. openFirewall defaults to true, so UDP 5353 is opened.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # also resolve <host>.local names system-wide via NSS
  };

  # ── Removable media (USB sticks, SD cards, cameras-as-USB-drives) ────────
  # udisks2 is the D-Bus mount daemon that Dolphin's Places panel (via Solid)
  # and udiskie both talk to. Without it, the kernel sees a plugged-in USB
  # stick (usb_storage) but nothing exposes it — no sidebar entry, no way to
  # mount. Its default polkit rules already let an active local-session user
  # mount without a password, so nothing else is needed here. The *automatic*
  # mount-on-insert half is udiskie, a session service in home/dolphin.nix —
  # udisks2 only exposes and permits the mount.
  services.udisks2.enable = true;

  # Let udisks2 actually mount non-native filesystems. FAT is always supported
  # and exfat rides along in the kernel, but NTFS (how most Windows-formatted
  # sticks and plenty of cameras format their storage) needs the ntfs-3g driver
  # — without it such drives fail to mount with a cryptic error. Listing both
  # is explicit and cheap.
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
}
