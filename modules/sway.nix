# sway.nix — the SYSTEM half of the SWAY session only. The greeter, fonts,
# and Wayland-wide env moved to modules/desktop.nix when hyprland became the
# second session; hyprland's system half is modules/hyprland.nix.
# The USER half (sway keybinds, colors…) lives in home/sway.nix.
{ config, lib, pkgs, ... }:

{
  # ── Sway ───────────────────────────────────────────────────────────────
  # System-level enable does things home-manager can't:
  #  * installs a wayland-session .desktop file (the greeter menu finds "Sway")
  #  * PAM integration for swaylock (unlocking actually works)
  #  * enables polkit and provides the portal config for the sway namespace
  # Window-manager *configuration* still comes from home-manager.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # fixes GTK apps (themes, portals) under sway
  };

  # ── Screen sharing (sway only) ─────────────────────────────────────────
  # wlroots compositors use the wlr portal for ScreenCast/Screenshot; sway's
  # portals.conf (shipped by programs.sway.enable) routes those interfaces
  # here. Hyprland brings its own backend (see modules/hyprland.nix), and
  # the generic GTK portal (file chooser…) lives in modules/desktop.nix.
  xdg.portal.wlr.enable = true; # implies xdg.portal.enable
}
