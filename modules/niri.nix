# niri.nix — system half of the niri session. User half (config.kdl glue) is
# home/niri.nix; the shell is DMS (modules/dms.nix); fonts and Wayland-wide env
# stay in modules/desktop.nix.
{ config, lib, pkgs, ... }:

{
  # The nixpkgs module installs the session .desktop file (Exec=niri-session:
  # niri runs as a systemd user unit, imports WAYLAND_DISPLAY, then activates
  # graphical-session.target — no uwsm), routes portals per upstream
  # recommendation (default→gnome,gtk; Access/Notification→gtk;
  # Secret→gnome-keyring), enables gnome-keyring (mkDefault — pinned true in
  # modules/gnome-keyring.nix), and pulls in polkit + an unused-but-harmless
  # swaylock PAM service. The package ships exactly ONE session file; still
  # audit share/wayland-sessions whenever a compositor package changes — every
  # entry the greeter lists must actually boot.
  programs.niri.enable = true;

  # Upstream's default, pinned against a flip: puts Nautilus on the session bus
  # so the gnome portal serves every open/save dialog with Nautilus's picker,
  # and org.freedesktop.FileManager1 ("reveal in folder") opens Nautilus. The
  # app itself is installed by home/nautilus.nix.
  programs.niri.useNautilus = true;

  # Redundant today (they'd fall through default=gnome anyway) and kept on
  # purpose as the executable form of a hard rule: xdg-desktop-portal-kde's
  # capture code speaks KWin's private zkde_screencast and can NEVER work
  # here — xdg-desktop-portal-gnome is niri's only screencast backend
  # (org.gnome.Mutter.ScreenCast). If overriding one of the module's own
  # portal keys is ever needed again: it hard-sets them as plain coerced
  # strings, so an override needs mkForce.
  # These serve app screencast (OBS, browser screenshare); Print-key
  # screenshots don't touch portals at all (DMS captures natively, satty
  # annotates — home/satty.nix). GlobalShortcuts is deliberately unrouted: no
  # working impl exists here and no current consumer misses it.
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.ScreenCast" = "gnome";
    "org.freedesktop.impl.portal.Screenshot" = "gnome";
    "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
  };

  # niri spawns xwayland-satellite on demand (and exports $DISPLAY) as long as
  # the binary is on $PATH; without it X11 apps just fail to connect. Scaling
  # caveat for X11 games: modules/gaming.nix.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Belt-and-braces with one session installed; keeps the greeter's
  # preselection deterministic and is required if autoLogin is ever enabled.
  services.displayManager.defaultSession = "niri";
}
