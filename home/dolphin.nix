# home/dolphin.nix — Dolphin (KDE Files) as THE file manager (also the xdg
# default for opening directories). One file per intent: everything that
# exists because of Dolphin lives here. It replaced Nautilus 2026-07 by
# explicit request — reversing the 2026 "GNOME apps only" decision. The
# session plumbing followed to KDE in 2026-07 (ksecretd keyring in
# modules/kwallet.nix, KDE portals in modules/niri.nix), so "remember
# password" flows KIO → ksecretd natively — no bridge needed. Only
# screencasting stays GNOME (niri's sole capture backend).
#
# The system half (avahi discovery, udisks2, ntfs/exfat) lives in
# modules/dolphin.nix — only NixOS can set those. Removing Dolphin = delete
# both dolphin files + their import lines (and give the mimeApps enable +
# udiskie below a new home, since ark.nix/vlc.nix piggyback on them).
#
# Where Nautilus leaned on system-side gvfs daemons, Dolphin brings its own
# I/O layer as ordinary user packages: KIO workers (kio-extras) for remote
# protocols and kio-fuse to expose them as plain paths. No system service
# needed — the workers are D-Bus/desktop-file activated from the profile.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.dolphin

    # The KIO worker set: smb://, sftp://, mtp://, trash, thumbnails-over-
    # network. This is the gvfs replacement — without it Dolphin can only
    # browse local files and "Network" is an empty shell.
    kdePackages.kio-extras

    # FUSE bridge that exposes open KIO mounts as real paths under
    # /run/user/*/kio-fuse-*, so non-KDE apps can open files you pick from a
    # network share (gvfs's FUSE bridge did this job before). D-Bus-activated
    # on demand; the package just has to be installed.
    kdePackages.kio-fuse

    # keditfiletype6 + kioclient: Dolphin execs these from Properties → the
    # file-type/"Open With" configuration dialogs. Without them those
    # buttons silently do nothing on a non-Plasma session.
    kdePackages.kde-cli-tools

    # Preview thumbnailers, parity with what Nautilus had built in:
    # video frames (ffmpegthumbs) and PDF/RAW/graphics (kdegraphics-).
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers

    # (kdePackages.kwallet — where "remember password" secrets go — is
    # installed system-side by modules/kwallet.nix, as the keyring is its
    # own intent now, not Dolphin fallout.)
  ];

  # udiskie is the piece that makes mounting *automatic*. udisks2 (enabled in
  # modules/dolphin.nix) only exposes removable drives and permits mounting;
  # udiskie runs as a systemd user service in the graphical session, watches for
  # newly-plugged devices, and mounts them the instant they appear under
  # /run/media/unclebeam/<label>. tray = "never" is deliberate: with the
  # default "auto", udiskie waits for a StatusNotifier tray host at startup
  # and silently never automounts if one is slow to appear — "never" keeps
  # automount independent of the DMS bar's tray. notify routes toasts
  # through the notification daemon (the DMS shell) on mount/unmount.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # Make Dolphin the session-wide default for opening directories — file
  # managers register the inode/directory pseudo-MIME type, and this is what
  # xdg-open (and hence every other app) consults. NB: this is the one place
  # xdg.mimeApps is *enabled*; ark.nix and vlc.nix merge their defaults into
  # it without re-setting enable.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "org.kde.dolphin.desktop";
  };

  # ── "Open With" fix for non-Plasma sessions (nixpkgs issue #409986) ──────
  # KService's app cache (kbuildsycoca6) refuses to index ANY .desktop file
  # unless an XDG menu file exists — Plasma ships one, bare niri ships none,
  # and the symptom is a completely empty "Open With" list in Dolphin. This
  # minimal menu just says "index every installed application". Deliberately
  # NOT plasma-workspace's plasma-applications.menu: that would drag Plasma
  # into the closure, and readFile-ing it would force a build during
  # `nix eval` (breaking the Mac-side validation workflow). If Open With ever
  # looks stale after a switch, running `kbuildsycoca6` once refreshes it.
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <Include><All/></Include>
    </Menu>
  '';
}
