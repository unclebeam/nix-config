# sway.nix — the SYSTEM half of the desktop: the sway session itself,
# the greeter that starts it, screen-sharing portals, and fonts.
# The USER half (sway keybinds, colors, waybar…) lives in home/.
{ config, lib, pkgs, ... }:

{
  # ── Sway ───────────────────────────────────────────────────────────────
  # System-level enable does things home-manager can't:
  #  * installs a wayland-session .desktop file (greetd finds "sway")
  #  * PAM integration for swaylock (unlocking actually works)
  #  * enables polkit and provides the portal config for the sway namespace
  # Window-manager *configuration* still comes from home-manager.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # fixes GTK apps (themes, portals) under sway
  };

  # ── Screen sharing / portals ───────────────────────────────────────────
  # xdg-desktop-portal is how sandbox-ish desktop APIs work on Wayland:
  # screen sharing, screenshots, file pickers. wlroots compositors use the
  # wlr portal for ScreenCast/Screenshot; GTK portal covers the rest
  # (file chooser…). programs.sway.enable already ships the portals.conf
  # that routes each interface to the right backend, and home-manager's
  # sway module exports WAYLAND_DISPLAY into the systemd user session, so
  # portal services find the compositor without any manual wiring.
  xdg.portal.wlr.enable = true; # implies xdg.portal.enable
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Chromium-based apps (Brave) run native Wayland instead of XWayland when
  # this is set. Electron apps honor it too.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ── greetd + tuigreet ──────────────────────────────────────────────────
  # greetd is a tiny display manager; tuigreet is its console UI.
  # After login it execs sway directly — no desktop-manager layer at all.
  services.greetd = {
    enable = true;
    # New in 26.05: proper TTY handling for text greeters (stops kernel
    # messages from scribbling over the UI). The VT is fixed to VT1.
    useTextGreeter = true;
    settings.default_session = {
      # --remember: pre-fill last username. --time: clock in the greeter.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
      user = "greeter";
    };
  };

  # ── Fonts ──────────────────────────────────────────────────────────────
  # Mono fonts (JetBrainsMono for the UI, IosevkaTerm for the terminal),
  # Sarabun for Thai text, Noto for everything else.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka-term # alacritty's terminal font (home/alacritty.nix)
    sarabun-font # Thai text font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
