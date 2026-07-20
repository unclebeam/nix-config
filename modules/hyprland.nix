# hyprland.nix — the SYSTEM half of the hyprland session. (Second trial:
# hyprland lost to niri once and was removed 2026-07-11; this branch re-runs
# the comparison on hyprland 0.55's new Lua config, as a FULL replacement
# this time — the niri modules are gone, not parked.) Fonts and Wayland-wide
# env stay in modules/desktop.nix (compositor-agnostic); the greeter is DMS
# on greetd (modules/dms-greeter.nix). The USER half (hyprland.lua glue)
# lives in home/hyprland.nix; the desktop shell — bar, lock screen, idle
# policy — is DMS (home/dms.nix).
{ config, lib, pkgs, ... }:

{
  # System-level enable does things home-manager can't:
  #  * installs the wayland-session .desktop files the greeter menu finds.
  #    ⚠ The package unconditionally ships TWO entries: "Hyprland" (plain
  #    exec — the one to use) and "Hyprland (uwsm-managed)", which is a trap
  #    here: withUWSM stays off (see below), so the uwsm entry has no units
  #    behind it and bounces back to the greeter.
  #  * a cap_sys_nice security wrapper for the Hyprland binary.
  #  * xdg-desktop-portal-hyprland — THE screencast/screenshot backend now
  #    (rerouted onto explicitly below).
  #  * real XWayland built in (xwayland.enable defaults true) — no
  #    xwayland-satellite needed, unlike niri.
  #  * polkit, dconf, the GTK portal, and /share/hypr on the system path
  #    (hyprland's Lua API stubs live there).
  # Window-manager *configuration* comes from home-manager.
  programs.hyprland.enable = true;
  # withUWSM deliberately OFF: DMS's recommended session plumbing replaces
  # it — hyprland.lua's startup hook pushes the session env into the systemd
  # user manager and starts hyprland-session.target itself (the same
  # explicit-anchor design niri-session.target had). uwsm would fight that
  # by managing graphical-session.target on its own.

  # ── Portal routing: KDE for dialogs, hyprland for capture ───────────────
  # The KDE portal serves everything interactive: file dialogs (KIO,
  # matching Dolphin), notifications (forwarded to org.freedesktop.
  # Notifications, i.e. the DMS shell), Access prompts, and Settings — apps
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

  # The polkit authentication agent is built into the DMS shell
  # (home/dms.nix) — it replaced plasma-polkit-agent in the 2026-07 DMS
  # migration.
}
