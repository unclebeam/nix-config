# niri.nix — the SYSTEM half of the niri session. (Third act of the
# compositor story: sway → hyprland → niri → hyprland again → niri again.
# The 2026-07 hyprland re-trial ran on 0.55's new Lua config; it ends here
# with niri back as a FULL replacement — the hyprland modules are gone, not
# parked, same as last time in the other direction.) Fonts and Wayland-wide
# env stay in modules/desktop.nix (compositor-agnostic); the greeter is
# DMS's on greetd (modules/dms-greeter.nix). The USER half (config.kdl
# glue) lives in home/niri.nix; the desktop shell — bar, lock screen, idle
# policy — is DMS (modules/dms.nix; niri is DMS's original home-turf
# compositor — NIRI_SOCKET IPC for workspaces/windows, plus the overview
# backdrop layer-rule in config.kdl).
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
  #    Access→gtk / Notification→gtk / Secret→gnome-keyring. Since the
  #    2026-08 Dolphin→Nautilus revert we KEEP that routing (the KDE portal
  #    and its mkForce'd reroutes left with Dolphin, and the Secret key
  #    became correct as-is when the keyring followed to gnome-keyring —
  #    modules/gnome-keyring.nix) — the only overrides are the capture pins
  #    below. xdg-desktop-portal-gnome is also the ONLY screencast backend
  #    niri supports (niri implements org.gnome.Mutter.ScreenCast;
  #    xdp-kde's capture code speaks KWin's private zkde_screencast
  #    protocol instead). Portal routing is per-desktop (picked by
  #    XDG_CURRENT_DESKTOP at login), so it composes with the fallback GTK
  #    portal in desktop.nix. Unlike the hyprland/xdph
  #    pair there is NO version-coupling hazard here: the gnome portal talks
  #    to niri over a public D-Bus API, not the compositor's own protocol
  #    versions — which is also why niri needs no unstable pin (26.05's
  #    26.04 is current) and this module takes no pkgs-unstable arg.
  #  * enables gnome-keyring (mkDefault) — and since 2026-08 we AGREE:
  #    modules/gnome-keyring.nix pins it true and adds the PAM unlock on
  #    greetd. (The kwallet era overrode this to false to run ksecretd
  #    instead; that fight is over — auth is GNOME now.)
  #  * swaylock PAM (security.pam.services.swaylock) — generated
  #    unconditionally via wayland-session.nix. Unused (the locker is
  #    DMS's, authenticating against /etc/pam.d/login) but harmless;
  #    modules/fprintd.nix still opts its fprintAuth off.
  #  * polkit (security.polkit, the ENGINE) — also from wayland-session.nix.
  #    The AGENT half is built into the DMS shell — always on, no config.
  # Window-manager *configuration* comes from home-manager.
  programs.niri.enable = true;

  # Upstream defaults useNautilus=true; pinned explicitly because it IS the
  # file-dialog story now (belt-and-braces like defaultSession below —
  # guards against an upstream default flip). It puts Nautilus on the
  # session bus (D-Bus activation, not systemPackages — the app itself is
  # installed by home/nautilus.nix) so xdg-desktop-portal-gnome serves
  # every app's open/save dialog with Nautilus's picker, and Nautilus's
  # D-Bus dir claims org.freedesktop.FileManager1 — "reveal in folder"
  # (1Password, Chrome downloads) opens Nautilus. The Dolphin era set this
  # false to keep Nautilus off the bus; that inversion left with Dolphin
  # (2026-08).
  programs.niri.useNautilus = true;

  # ── Portal routing: upstream's gnome/gtk, capture pinned gnome ──────────
  # Since the 2026-08 Nautilus revert we no longer fight the niri module's
  # routing. What's in effect: default=gnome;gtk, Access/Notification→gtk
  # (the gtk portal forwards notifications to org.freedesktop.
  # Notifications, i.e. the DMS shell), FileChooser deliberately UNWRITTEN
  # by upstream when useNautilus is on — it falls through default to
  # gnome, whose dialog is Nautilus's picker — and Settings falls through
  # to gnome too, so apps read the color-scheme preference from gsettings,
  # which DMS's "Apply GTK Themes" toggle writes. The KDE portal package
  # and its mkForce'd routes are GONE (they existed for Dolphin/KIO
  # dialogs), and Secret stays on upstream's gnome-keyring — the keyring
  # followed to GNOME 2026-08 (modules/gnome-keyring.nix), retiring the
  # repo's last mkForce'd portal key (kwallet's Secret reroute; the
  # mkForce was needed because this module hard-sets Secret as a plain
  # coerced string — remember that if a key ever needs overriding again).
  # The three pins below are REDUNDANT today (upstream never writes these
  # keys, and they'd fall through default=gnome anyway) and kept on
  # purpose as the executable form of a hard rule: xdg-desktop-portal-kde's
  # capture code is hard-wired to KWin's private zkde_screencast and can
  # NEVER work here — xdg-desktop-portal-gnome is niri's only screencast
  # backend (org.gnome.Mutter.ScreenCast). If routing is ever touched
  # again, the capture family stays gnome.
  # GlobalShortcuts is deliberately UNROUTED: xdph's implementation left
  # with hyprland and no working impl exists here; the interface simply
  # isn't served, which no current consumer misses.
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.ScreenCast" = "gnome";
    "org.freedesktop.impl.portal.Screenshot" = "gnome";
    "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
  };
  # (Screenshots via Print don't touch these portals at all: DMS's
  # screenshot UI captures natively — niri implements the wlr protocols it
  # needs — and the screenshot-annotate wrapper hands the image to satty.
  # The gnome routes above serve app screencast: OBS,
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
