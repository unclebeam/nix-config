# home/nautilus.nix — Nautilus as THE file manager and xdg default for
# directories. The file-dialog story rides on modules/niri.nix's
# useNautilus = true (portal picker + org.freedesktop.FileManager1 "reveal
# in folder"); saved share passwords land in gnome-keyring. System half
# (gvfs, avahi, udisks2, ntfs/exfat): modules/nautilus.nix. Removing
# Nautilus = both nautilus files + import lines (and udiskie below needs a
# new home — it's file-manager-agnostic).
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus

    # Video thumbnails: Nautilus discovers *.thumbnailer files via
    # XDG_DATA_DIRS (nixpkgs patches the Exec to a store path). Without it
    # video files show a generic icon; image/PDF previews are built in.
    ffmpegthumbnailer
  ];

  # udisks2 only exposes and permits mounting; udiskie is what makes it
  # automatic (mounts under /run/media/unclebeam/<label> on plug).
  # tray = "never" is deliberate: with "auto", udiskie waits for a
  # StatusNotifier tray host and silently never automounts if one is slow —
  # "never" keeps automount independent of the shell bar. notify routes
  # toasts through DMS.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Session-wide default for opening directories (what xdg-open consults).
  # xdg.mimeApps.enable lives in home/default.nix.
  xdg.mimeApps.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";
}
