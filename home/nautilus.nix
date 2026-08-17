# home/nautilus.nix — Nautilus (GNOME Files) as THE file manager (also the
# xdg default for opening directories). One file per intent: everything that
# exists because of Nautilus lives here. It replaced Dolphin 2026-08 by
# explicit request — "Nautilus is the default for everything about files" —
# and the file-DIALOG story rides on it too: modules/niri.nix pins
# programs.niri.useNautilus = true, which puts Nautilus on the session bus
# so xdg-desktop-portal-gnome serves every app's open/save dialog with
# Nautilus's picker, and Nautilus claims org.freedesktop.FileManager1
# ("reveal in folder"). The keyring is GNOME too (since 2026-08): secrets
# live in gnome-keyring (modules/gnome-keyring.nix), which gvfs reaches via
# org.freedesktop.secrets — saved SMB passwords survive relogin through the
# pam_gnome_keyring unlock at login.
#
# The system half (gvfs, avahi discovery, udisks2, ntfs/exfat) lives in
# modules/nautilus.nix — only NixOS can set those. Removing Nautilus =
# delete both nautilus files + their import lines (and give udiskie below a
# new home — it's file-manager-agnostic and just lives here).
#
# Where Dolphin needed a pile of KIO user packages to function, Nautilus
# needs almost nothing here: remote protocols, trash and MTP are the
# system-side gvfs daemons. (The KService applications.menu workaround the
# Dolphin file carried is gone WITH the last KF6 app — nothing runs
# kbuildsycoca6 anymore, and GTK apps read mimeapps.list directly.)
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus

    # Video thumbnails: Nautilus discovers *.thumbnailer files via
    # XDG_DATA_DIRS, and nixpkgs patches this one's Exec to an absolute
    # store path so it works without the binary on PATH. Parity with the
    # ffmpegthumbs Dolphin had — without it video files show a generic
    # icon. (Image and PDF previews are built in via gdk-pixbuf.)
    ffmpegthumbnailer
  ];

  # udiskie is the piece that makes mounting *automatic*. udisks2 (enabled in
  # modules/nautilus.nix) only exposes removable drives and permits mounting;
  # udiskie runs as a systemd user service in the graphical session, watches for
  # newly-plugged devices, and mounts them the instant they appear under
  # /run/media/unclebeam/<label>. tray = "never" is deliberate: with the
  # default "auto", udiskie waits for a StatusNotifier tray host at startup
  # and silently never automounts if one is slow to appear — "never" keeps
  # automount independent of the shell bar's tray. notify routes toasts
  # through the notification daemon (the DMS shell) on mount/unmount.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Make Nautilus the session-wide default for opening directories — file
  # managers register the inode/directory pseudo-MIME type, and this is what
  # xdg-open (and hence every other app) consults. (xdg.mimeApps itself is
  # enabled in home/default.nix — shared infrastructure, since file-roller/
  # vlc/mpv/chrome all merge defaults into it; this file only contributes
  # its entry.)
  xdg.mimeApps.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";
}
