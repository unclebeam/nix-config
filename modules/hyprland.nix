# hyprland.nix — the SYSTEM half of the HYPRLAND session. The greeter,
# fonts, and Wayland-wide env are shared with sway in modules/desktop.nix.
# The USER half (the lua config, hyprlock, hypridle) lives in home/hyprland.nix.
{ config, lib, pkgs, ... }:

{
  # System-level enable does things home-manager can't:
  #  * installs a wayland-session .desktop file (the greeter menu finds
  #    "Hyprland"; the default_session --cmd uses it too)
  #  * a cap_sys_nice security wrapper ("Hyprland" on $PATH) so the
  #    compositor can raise its own scheduling priority
  #  * xdg-desktop-portal-hyprland (ScreenCast/Screenshot) plus the
  #    portals.conf that routes those interfaces to it under hyprland
  #  * polkit + xwayland, same as programs.sway does
  # withUWSM stays off — no systemd-managed session layer, matching how
  # sway is run here. Window-manager *configuration* comes from home-manager.
  programs.hyprland.enable = true;

  # PAM for hyprlock so unlocking actually works — the mirror of what
  # programs.sway sets up for swaylock. Deliberately NOT the NixOS
  # programs.hyprlock module: that one force-enables a SYSTEM-level hypridle
  # bound to graphical-session.target, which would run hypridle inside the
  # sway session too and fight swayidle. Lock/idle instead live in
  # home/hyprland.nix, scoped to hyprland-session.target.
  security.pam.services.hyprlock = { };
}
