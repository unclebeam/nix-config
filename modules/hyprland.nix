# hyprland.nix — the SYSTEM half of the hyprland session. (Second trial:
# hyprland lost to niri once and was removed 2026-07-11; this branch re-runs
# the comparison on hyprland 0.55's new Lua config, as a FULL replacement
# this time — the niri modules are gone, not parked.) Fonts and Wayland-wide
# env stay in modules/desktop.nix (compositor-agnostic); the greeter is
# Noctalia's on greetd (modules/noctalia-greeter.nix). The USER half
# (hyprland.lua glue) lives in home/hyprland.nix; the desktop shell — bar,
# lock screen, idle policy — is Noctalia (modules/noctalia.nix).
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  # System-level enable does things home-manager can't:
  #  * installs the wayland-session .desktop files the greeter menu finds
  #    (filtered below — see the sessionPackages override).
  #  * a cap_sys_nice security wrapper for the Hyprland binary.
  #  * xdg-desktop-portal-hyprland — THE screencast/screenshot backend now
  #    (rerouted onto explicitly below).
  #  * real XWayland built in (xwayland.enable defaults true) — no
  #    xwayland-satellite needed, unlike niri.
  #  * polkit, dconf, the GTK portal, and /share/hypr on the system path
  #    (hyprland's Lua API stubs live there).
  # Window-manager *configuration* comes from home-manager.
  programs.hyprland.enable = true;

  # ── The compositor tracks UNSTABLE, not our 26.05 pin ───────────────────
  # Everything else on these machines comes from nixos-26.05; hyprland is one
  # of the curated exceptions that ride nixpkgs-unstable (flake.nix's
  # `pkgs-unstable`, reaching this module via specialArgs — same route as
  # brave/lazygit/starship). The reason is the same reason those packages get
  # the exception, only sharper: 0.55 was the FIRST release of the Lua config
  # this whole setup is built on, upstream ships a release roughly monthly,
  # and a frozen stable branch means sitting on the .0 of a brand-new config
  # format for six months. 26.05 has 0.55.4; unstable has 0.56.1.
  #
  # package and portalPackage MUST move together, and that pairing is the
  # load-bearing part of this block. xdg-desktop-portal-hyprland is not a
  # generic portal — it IS hyprland's screencopy backend, and it speaks the
  # compositor's own wlr-screencopy/hyprland-toplevel protocol versions over
  # hyprland's socket. Leaving xdph on 26.05 (1.3.12) against a 0.56
  # compositor is exactly the skew that yields a BLACK or silently-empty
  # screenshare rather than a loud error — the worst failure shape, because
  # nothing logs. Bump both or neither. (The KDE portal below is unaffected:
  # different process, public portal D-Bus API, no version coupling.)
  #
  # Cost check, so nobody fears a source build: both derivations are fully in
  # cache.nixos.org at the current lock (`nix build --dry-run` says "will be
  # fetched", never "will be built"). And the unstable rev we're locked to is
  # the same one noctalia's flake pins, so this reuses a package set already
  # in the closure instead of adding a third nixpkgs.
  programs.hyprland.package = pkgs-unstable.hyprland;
  programs.hyprland.portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;

  # withUWSM deliberately OFF: our own session plumbing replaces it —
  # hyprland.lua's startup hook pushes the session env into the systemd
  # user manager and starts hyprland-session.target itself (the same
  # explicit-anchor design niri-session.target had). uwsm would fight that
  # by managing graphical-session.target on its own.

  # ── Session list: expose ONLY the plain "Hyprland" entry ────────────────
  # The hyprland package unconditionally ships TWO session files:
  # hyprland.desktop (plain start-hyprland — the working one) and
  # hyprland-uwsm.desktop, whose Exec is a bundled uwsm binary. With
  # withUWSM off, uwsm's systemd user units don't exist, so picking that
  # entry PROVABLY kills the login: journal 2026-07-20 shows uwsm running
  # `systemctl --user start wayland-session-bindpid@….service` → exit
  # status 5 (no such unit) → session closed after ~1s → bounced back to
  # the greeter. The greeter builds its session menu from
  # services.displayManager.sessionPackages (merged into sessionData.
  # desktops, which /etc/pam/environment prepends to every session's
  # XDG_DATA_DIRS), so overriding the list here removes the landmine at
  # the source. The link-farm re-exports just hyprland.desktop from the
  # real package — no Hyprland rebuild (overrideAttrs would compile from
  # source; there's no cache for a modified derivation).
  services.displayManager.sessionPackages = lib.mkForce [
    (pkgs.runCommand "hyprland-session-only"
      { passthru.providedSessions = [ "hyprland" ]; } ''
        mkdir -p $out/share/wayland-sessions
        ln -s ${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop \
          $out/share/wayland-sessions/
      '')
  ];
  # With one session in the list this is belt-and-braces (nothing else to
  # fall back to), but it keeps the greeter's preselection deterministic
  # and is required if autoLogin is ever enabled.
  services.displayManager.defaultSession = "hyprland";

  # ── Portal routing: KDE for dialogs, hyprland for capture ───────────────
  # The KDE portal serves everything interactive: file dialogs (KIO,
  # matching Dolphin), notifications (forwarded to org.freedesktop.
  # Notifications, i.e. the Noctalia shell), Access prompts, and Settings — apps
  # read the color-scheme preference from kdeglobals, not gsettings.
  # Unlike the old niri module — which hard-set portal-config keys, forcing
  # mkForce on every override — programs.hyprland writes NO xdg.portal.config
  # keys. It only ships a default=hyprland;gtk file via configPackages,
  # which /etc-level xdg.portal.config wins over outright. Every key below
  # is therefore a fresh definition: no mkForce anywhere.
  # The capture family goes to xdph (wlr-screencopy — hyprland's native
  # path; the GNOME/Mutter route the niri era used was niri-only and
  # xdg-desktop-portal-gnome is no longer installed). Never route capture
  # to kde: xdg-desktop-portal-kde's capture code is hard-wired to KWin's
  # private zkde_screencast protocol and can never work here.
  # RemoteDesktop is pinned to "none": xdph 1.3.12 doesn't implement it
  # (its .portal file declares Screenshot;ScreenCast;GlobalShortcuts only),
  # and letting it fall through default= would hand it to the KWin-wired
  # KDE impl — certainly broken. "none" makes the gap explicit and silent.
  # (Secret→kwallet lives in modules/kwallet.nix: one file per intent, so
  # deleting the keyring module deletes its route.)
  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  xdg.portal.config.hyprland = {
    default = [ "kde" "gtk" ];
    "org.freedesktop.impl.portal.Access" = "kde";
    "org.freedesktop.impl.portal.FileChooser" = "kde";
    "org.freedesktop.impl.portal.Notification" = "kde";
    "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
    "org.freedesktop.impl.portal.Screenshot" = "hyprland";
    "org.freedesktop.impl.portal.GlobalShortcuts" = "hyprland";
    "org.freedesktop.impl.portal.RemoteDesktop" = "none";
  };

  # The polkit authentication agent is built into the Noctalia shell —
  # off by default upstream, switched on in home/noctalia/config.toml
  # (polkit_agent). It replaced DMS's agent, which had replaced
  # plasma-polkit-agent in the 2026-07 migration.
}
