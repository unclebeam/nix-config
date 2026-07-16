# home/dolphin.nix — Dolphin (KDE Files) as THE file manager (also the xdg
# default for opening directories). One file per intent: everything that
# exists because of Dolphin lives here. It replaced Nautilus 2026-07 by
# explicit request — reversing the 2026 "GNOME apps only" decision — while
# the session plumbing deliberately stays GNOME (gnome-keyring + GNOME
# portals; niri's only screencast backend is the GNOME portal, so that side
# can't follow).
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

    # NOT here for local wallet storage: since the 2025 KWallet refactor,
    # kwalletd6 is a thin wrapper that translates KWallet API calls (KIO's
    # password server = Dolphin's "remember password" for smb://sftp) into
    # Secret Service calls. Combined with the kwalletrc below, saved share
    # passwords land in gnome-keyring — the session's one real keyring.
    kdePackages.kwallet
  ];

  # udiskie is the piece that makes mounting *automatic*. udisks2 (enabled in
  # modules/dolphin.nix) only exposes removable drives and permits mounting;
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

  # ── Route KWallet API traffic into gnome-keyring ─────────────────────────
  # [KSecretD] Enabled=false stops KWallet's own Secret Service daemon from
  # ever starting, so it can't fight gnome-keyring over the
  # org.freedesktop.secrets D-Bus name (gnome-keyring backs niri's Secret
  # portal and is auto-unlocked at login via PAM — modules/niri.nix).
  # [Migration] MigrateTo3rdParty=true tells the kwalletd6 wrapper to hand
  # secrets to whatever Secret Service provider is running instead —
  # i.e. gnome-keyring. First Use=false suppresses KWallet's first-run
  # wizard (the "Basic (Blowfish) vs Advanced (GPG)" dialog): with the
  # bridge no local wallet is ever created, so the wizard is pure noise,
  # and this guarantees it can't appear even on a fallback path.
  # This bridge is new (Plasma 6.4-era, 2025); its failure mode is a
  # password prompt or an unsaved password — never data loss. If it
  # misbehaves, deleting this file just means passwords aren't remembered.
  xdg.configFile."kwalletrc".text = ''
    [Wallet]
    First Use=false

    [Migration]
    MigrateTo3rdParty=true

    [KSecretD]
    Enabled=false
  '';
}
