# home/nautilus.nix — Nautilus (GNOME Files) as THE file manager (also the
# xdg default for opening directories). One file per intent: everything that
# exists because of Nautilus lives here. It replaced Dolphin when the KDE
# stack left with hyprland — niri's portal routing already points at the
# GNOME portal (modules/niri.nix), so the file manager now matches the rest
# of the session's plumbing.
#
# The system half (gvfs for smb://, avahi for discovery, udisks2, keyring
# PAM unlock) lives in modules/nautilus.nix — only NixOS can set those.
# Removing Nautilus = delete both nautilus files + their import lines.
#
# Where Dolphin needed a pile of KIO workers to function outside Plasma,
# Nautilus needs nothing beyond the package: network/trash/MTP access comes
# from gvfs daemons (system-side), and saved share passwords go to
# gnome-keyring, which programs.niri already runs for the Secret portal.
{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.nautilus ];

  # udiskie is the piece that makes mounting *automatic*. udisks2 (enabled in
  # modules/nautilus.nix) only exposes removable drives and permits mounting;
  # udiskie runs as a systemd user service in the graphical session, watches for
  # newly-plugged devices, and mounts them the instant they appear under
  # /run/media/unclebeam/<label>. tray = "never" because this minimal Waybar has
  # no StatusNotifier tray host — with the default "auto", udiskie would sit
  # waiting for a tray icon and silently never automount. notify routes toasts
  # through the notification daemon (home/swaync.nix) on mount/unmount.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Make Nautilus the session-wide default for opening directories — file
  # managers register the inode/directory pseudo-MIME type, and this is what
  # xdg-open (and hence every other app) consults.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";
  };
}
