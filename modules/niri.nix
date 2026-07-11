# niri.nix — the SYSTEM half of the niri session. (Niri started as a
# side-by-side trial next to hyprland — same playbook as the sway→hyprland
# move — and won; hyprland was removed 2026-07.) The greeter, fonts, and
# Wayland-wide env stay in modules/desktop.nix (compositor-agnostic). The
# USER half (config.kdl glue, swaylock, swayidle) lives in home/niri.nix.
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
  #    (the ONLY screencast backend niri supports) and writes a
  #    niri-portals.conf routing default→gnome,gtk / Secret→gnome-keyring.
  #    Portal routing is per-desktop (picked by XDG_CURRENT_DESKTOP at
  #    login), so it composes with the generic GTK portal in desktop.nix.
  #  * enables gnome-keyring (the Secret portal backend, and where Nautilus
  #    saves SMB passwords — the PAM auto-unlock half is in
  #    modules/nautilus.nix) so the gnome portal's FileChooser works.
  #  * swaylock PAM (security.pam.services.swaylock) — set by this module
  #    directly. Unlocking would silently fail without it; lock/idle config
  #    itself is user-side in home/niri.nix.
  # Window-manager *configuration* comes from home-manager.
  programs.niri.enable = true;

  # niri 26.04 has xwayland-satellite integration built in: it creates the
  # X11 sockets, exports $DISPLAY, and spawns xwayland-satellite ON DEMAND
  # the moment an X11 client connects (and restarts it if it dies). All it
  # needs is the binary (>= 0.7; nixpkgs has 0.8.1) on $PATH — without it
  # X11 apps just fail to connect, nothing crashes.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Deliberately NO polkit authentication agent, even though upstream
  # suggests plasma-polkit-agent: the old hyprland session ran without one
  # (1Password ships its own polkit policy and nothing else has needed GUI
  # auth), and niri has needed none since. If auth prompts ever go missing,
  # plasma-polkit-agent is the upstream-recommended fix.
}
