# home/dolphin.nix — Dolphin as THE file manager (also the xdg default for
# opening directories). One file per intent: everything that exists because
# of Dolphin lives here — the KDE package set it needs to function outside
# Plasma, and the wallet that remembers SMB share passwords.
#
# The system half (avahi for SMB discovery, PAM kwallet unlock) lives in
# modules/dolphin.nix — same split as hyprland.nix. The Qt widget style + colors
# used to live here too, but moved to home/qt.nix once the Hyprland share
# picker became a second consumer. Removing Dolphin = delete both dolphin
# files + their import lines (qt.nix stays — other Qt apps use it).
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs.kdePackages; [
    dolphin

    # Since KDE Gear 25.11 the core KIO workers (file/trash/ftp/http) ship
    # as a separate package — without it Dolphin can't even open local dirs.
    kio

    # sftp/smb/fish/mtp/... workers — smb:// browsing comes from here.
    kio-extras

    # Exposes kio URLs (smb://, sftp://) as FUSE paths so non-KDE apps can
    # open files you pick from a network share. D-Bus activated; KIO uses it
    # automatically, no service to wire up.
    kio-fuse

    # Breeze icons are SVGs; without Qt's svg image plugin every icon in
    # Dolphin renders as an empty box.
    qtsvg
    breeze-icons

    # kwalletd6 (D-Bus activated) stores SMB credentials so "remember
    # password" actually works. It's unlocked at login by the PAM hook in
    # modules/dolphin.nix. kwalletmanager is the GUI to inspect the wallet
    # if it ever misbehaves. NOTE: don't create a wallet by hand — pam_kwallet6
    # auto-creates one keyed to the login password on first login, and a
    # manually created (e.g. GPG) wallet silently breaks auto-unlock.
    kwallet
    kwalletmanager
  ];

  # udiskie is the piece that makes mounting *automatic*. udisks2 (enabled in
  # modules/dolphin.nix) only exposes removable drives and permits mounting;
  # udiskie runs as a systemd user service in the graphical session, watches for
  # newly-plugged devices, and mounts them the instant they appear under
  # /run/media/unclebeam/<label>. tray = "never" because this minimal Waybar has
  # no StatusNotifier tray host — with the default "auto", udiskie would sit
  # waiting for a tray icon and silently never automount. notify routes toasts
  # through mako (home/mako.nix) on mount/unmount.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Make Dolphin the session-wide default for opening directories — file
  # managers register the inode/directory pseudo-MIME type, and this is what
  # xdg-open (and hence every other app) consults.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "org.kde.dolphin.desktop";
  };

  # Outside Plasma, Dolphin's "Open With" menu is EMPTY: KDE builds its
  # service cache (sycoca) from an XDG menu definition that only Plasma
  # ships. A minimal applications.menu that simply includes every installed
  # .desktop file is enough (freedesktop menu spec; nixpkgs issue 409986).
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';
}
