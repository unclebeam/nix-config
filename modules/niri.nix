# niri.nix — the SYSTEM half of the niri session. (Third act of the
# compositor story: sway → hyprland → niri → hyprland again → niri again.
# The 2026-07 hyprland re-trial ran on 0.55's new Lua config; it ends here
# with niri back as a FULL replacement — the hyprland modules are gone, not
# parked, same as last time in the other direction.) Fonts and Wayland-wide
# env stay in modules/desktop.nix (compositor-agnostic); the greeter is
# Noctalia's on greetd (modules/noctalia-greeter.nix). The USER half
# (config.kdl glue) lives in home/niri.nix; the desktop shell — bar, lock
# screen, idle policy — is Noctalia (modules/noctalia.nix, whose v5 has a
# first-class niri backend: NIRI_SOCKET IPC for workspaces/windows/layout,
# plus niri-only extras like the overview backdrop).
{ config, lib, pkgs, ... }:

{
  # System-level enable does things home-manager can't — and the nixpkgs
  # module tracks upstream's "Important Software" recommendations exactly:
  #  * installs the wayland-session .desktop file (the greeter menu finds
  #    "Niri"). Its Exec is `niri-session`, which is systemd-NATIVE: niri
  #    runs as a user unit (niri.service, Type=notify), imports
  #    WAYLAND_DISPLAY into the user manager itself, and only then reaches
  #    readiness and activates graphical-session.target. No uwsm anywhere —
  #    niri needs no external session manager, and the package ships exactly
  #    ONE session file, so the sessionPackages force-filter the hyprland
  #    era needed (its package unconditionally shipped a second, broken
  #    hyprland-uwsm.desktop) has nothing to filter. The lesson stands:
  #    audit `ls $(nix build --print-out-paths .#...)/share/wayland-sessions`
  #    whenever a compositor package changes — every entry the greeter
  #    lists must actually boot.
  #  * portals per upstream recommendation: adds xdg-desktop-portal-gnome
  #    and writes a niri-portals.conf routing default→gnome,gtk /
  #    Secret→gnome-keyring. We REROUTE most of that below: every dialog-ish
  #    interface goes to the KDE portal, and only the capture family stays
  #    GNOME — it has to, because xdg-desktop-portal-gnome is the ONLY
  #    screencast backend niri supports (niri implements
  #    org.gnome.Mutter.ScreenCast; xdp-kde's capture code speaks KWin's
  #    private zkde_screencast protocol instead). Portal routing is
  #    per-desktop (picked by XDG_CURRENT_DESKTOP at login), so it composes
  #    with the fallback GTK portal in desktop.nix. Unlike the hyprland/xdph
  #    pair there is NO version-coupling hazard here: the gnome portal talks
  #    to niri over a public D-Bus API, not the compositor's own protocol
  #    versions — which is also why niri needs no unstable pin (26.05's
  #    26.04 is current) and this module takes no pkgs-unstable arg.
  #  * enables gnome-keyring (mkDefault) — overridden back OFF in
  #    modules/kwallet.nix, where ksecretd (KDE) is the session keyring.
  #    That guard is LIVE again (programs.hyprland never touched keyrings;
  #    this module does).
  #  * swaylock PAM (security.pam.services.swaylock) — generated
  #    unconditionally via wayland-session.nix. Unused (the locker is
  #    Noctalia's, authenticating against /etc/pam.d/login) but harmless;
  #    modules/fprintd.nix still opts its fprintAuth off.
  #  * polkit (security.polkit, the ENGINE) — also from wayland-session.nix.
  #    The AGENT half is the Noctalia shell's, switched on in
  #    home/noctalia/config.toml (polkit_agent).
  # Window-manager *configuration* comes from home-manager.
  programs.niri.enable = true;

  # The nixpkgs niri module defaults useNautilus=true: it puts the full
  # Nautilus package on the session bus so xdg-desktop-portal-gnome can use
  # Nautilus's dialog as the FileChooser. Two problems since the file manager
  # went to Dolphin (2026-07): every app's open/save dialog would secretly
  # be Nautilus, and Nautilus's D-Bus dir also claims
  # org.freedesktop.FileManager1 — so "reveal in folder" (1Password etc.)
  # would open Nautilus, not Dolphin. false = keeps Nautilus out of the
  # closure and Dolphin the only FileManager1 provider. (The FileChooser→gtk
  # route it writes is overridden to kde just below.)
  programs.niri.useNautilus = false;

  # ── Portal routing: KDE for dialogs, GNOME only for capture ─────────────
  # The KDE portal serves everything interactive: file dialogs (KIO,
  # matching Dolphin), notifications (forwarded to org.freedesktop.
  # Notifications, i.e. the Noctalia shell), Access prompts, and Settings —
  # apps read the color-scheme preference from kdeglobals, not gsettings.
  # The niri module hard-sets its keys as plain coerced strings, so
  # overriding the SAME keys needs mkForce (a second plain definition is an
  # eval conflict) — unlike programs.hyprland, which wrote no portal-config
  # keys at all. The gnome pins are NEW keys — today they fall through
  # default=gnome — and merge without force. They exist because the whole
  # capture family in xdg-desktop-portal-kde is hard-wired to KWin's
  # zkde_screencast: routed to kde they wouldn't just be untested, they'd
  # be certainly broken. GNOME capture is the permanent exception to the
  # KDE plumbing — do not "finish" the migration by flipping these.
  # GlobalShortcuts is deliberately UNROUTED: xdph's implementation left
  # with hyprland and neither the gnome nor kde impl works here; the
  # interface simply isn't served, which no current consumer misses.
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
  # (Screenshots via Print don't touch these portals at all: Noctalia
  # captures natively over wlr-screencopy — which niri implements — and
  # pipes into satty. The gnome routes above serve app screencast: OBS,
  # browser screenshare, vesktop. One behavior change vs xdph: the
  # restore-token auto-grant tuning lived in hypr/xdph.conf, so re-sharing
  # to the same site re-opens the picker each time now — accepted.)

  # niri 26.04 has xwayland-satellite integration built in: it creates the
  # X11 sockets, exports $DISPLAY, and spawns xwayland-satellite ON DEMAND
  # the moment an X11 client connects (and restarts it if it dies). All it
  # needs is the binary (>= 0.7; nixpkgs has 0.8.1) on $PATH — without it
  # X11 apps just fail to connect, nothing crashes. This replaces hyprland's
  # built-in XWayland (Steam and other X11 clients — see modules/gaming.nix
  # for the scaling caveat).
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # With one session in the list this is belt-and-braces (nothing else to
  # fall back to), but it keeps the greeter's preselection deterministic
  # and is required if autoLogin is ever enabled.
  services.displayManager.defaultSession = "niri";
}
