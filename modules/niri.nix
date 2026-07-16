# niri.nix — the SYSTEM half of the niri session. (Niri started as a
# side-by-side trial next to hyprland — same playbook as the sway→hyprland
# move — and won; hyprland was removed 2026-07.) The greeter, fonts, and
# Wayland-wide env stay in modules/desktop.nix (compositor-agnostic). The
# USER half (config.kdl glue, swayidle) lives in home/niri.nix; the lock
# screen is gtklock, system-side in modules/gtklock.nix.
{ config, lib, pkgs, ... }:

{
  # System-level enable does things home-manager can't — and the nixpkgs
  # module tracks upstream's "Important Software" recommendations exactly:
  #  * installs the wayland-session .desktop file (the greeter menu finds
  #    "Niri"). Its Exec is `niri-session`, which is systemd-NATIVE: niri
  #    runs as a user unit (niri.service), imports WAYLAND_DISPLAY into the
  #    user manager itself, and only then activates graphical-session.target.
  #    No uwsm anywhere — niri needs no external session manager.
  #  * portals per upstream recommendation: adds xdg-desktop-portal-gnome
  #    and writes a niri-portals.conf routing default→gnome,gtk /
  #    Secret→gnome-keyring. Since the 2026-07 KDE-plumbing migration we
  #    REROUTE most of that below: every dialog-ish interface goes to the
  #    KDE portal, and only the capture family stays GNOME — it has to,
  #    because xdg-desktop-portal-gnome is the ONLY screencast backend niri
  #    supports (niri implements org.gnome.Mutter.ScreenCast; xdp-kde's
  #    capture code speaks KWin's private zkde_screencast protocol instead).
  #    Portal routing is per-desktop (picked by XDG_CURRENT_DESKTOP at
  #    login), so it composes with the fallback GTK portal in desktop.nix.
  #  * enables gnome-keyring — overridden back OFF in modules/kwallet.nix,
  #    where ksecretd (KDE) is the session keyring now.
  #  * swaylock PAM (security.pam.services.swaylock) — set by this module
  #    directly. Unused since the locker became gtklock (whose PAM service
  #    comes from modules/gtklock.nix), but harmless: it's upstream's
  #    unconditional default, not something we can or need to turn off.
  #    Idle/lock invocation is user-side in home/niri.nix.
  # Window-manager *configuration* comes from home-manager.
  programs.niri.enable = true;

  # The nixpkgs niri module defaults useNautilus=true: it puts the full
  # Nautilus package on the session bus so xdg-desktop-portal-gnome can use
  # Nautilus's dialog as the FileChooser. Two problems since the file manager
  # went to Dolphin (2026-07): every app's open/save dialog was secretly
  # Nautilus, and Nautilus's D-Bus dir also claims org.freedesktop.FileManager1
  # — so "reveal in folder" (1Password etc.) opened Nautilus, not Dolphin.
  # false = keeps Nautilus out of the closure and Dolphin the only
  # FileManager1 provider. (The FileChooser→gtk route it writes is
  # overridden to kde just below.)
  programs.niri.useNautilus = false;

  # ── Portal routing: KDE for dialogs, GNOME only for capture ─────────────
  # The KDE portal serves everything interactive: file dialogs (KIO/Breeze,
  # matching Dolphin), notifications (forwarded to org.freedesktop.
  # Notifications, i.e. swaync), Access prompts, and Settings — note that
  # means apps now read the color-scheme preference from kdeglobals, not
  # gsettings (neither is set today; future dark-mode work targets
  # kdeglobals). The niri module hard-sets these keys as plain coerced
  # strings, so overriding same keys needs mkForce (a second plain
  # definition is an eval conflict); the gnome pins are NEW keys — today
  # they fall through `default=gnome` — and merge without force. They exist
  # because the whole capture family (ScreenCast/Screenshot/RemoteDesktop)
  # in xdg-desktop-portal-kde is hard-wired to KWin's private
  # zkde_screencast protocol: routed to kde they wouldn't just be untested,
  # they'd be certainly broken. GNOME capture is the permanent exception to
  # the KDE plumbing — do not "finish" the migration by flipping these.
  # (Secret→kwallet lives in modules/kwallet.nix: one file per intent, so
  # deleting the keyring module deletes its route.)
  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  xdg.portal.config.niri = {
    default = lib.mkForce [ "kde" "gtk" ];
    "org.freedesktop.impl.portal.Access" = lib.mkForce "kde";
    "org.freedesktop.impl.portal.FileChooser" = lib.mkForce "kde";
    "org.freedesktop.impl.portal.Notification" = lib.mkForce "kde";
    "org.freedesktop.impl.portal.ScreenCast" = "gnome";
    "org.freedesktop.impl.portal.Screenshot" = "gnome";
    "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
  };

  # niri 26.04 has xwayland-satellite integration built in: it creates the
  # X11 sockets, exports $DISPLAY, and spawns xwayland-satellite ON DEMAND
  # the moment an X11 client connects (and restarts it if it dies). All it
  # needs is the binary (>= 0.7; nixpkgs has 0.8.1) on $PATH — without it
  # X11 apps just fail to connect, nothing crashes.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # The polkit authentication agent (upstream-recommended
  # plasma-polkit-agent) lives in modules/polkit-agent.nix — added 2026-07
  # with the KDE plumbing, reversing the earlier deliberate no-agent setup.
}
