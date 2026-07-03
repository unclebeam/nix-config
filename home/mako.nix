# home/mako.nix — notification daemon. D-Bus activated: starts on the
# first notification, no exec line needed anywhere.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
in
{
  services.mako = {
    enable = true;
    # 26.05 schema: everything lives under `settings` with mako's own
    # kebab-case key names (rendered to ~/.config/mako/config).
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      background-color = colors.a.float;
      text-color = colors.a.fg;
      border-color = colors.a.com;
      border-size = 2;
      padding = "10";
      margin = "10";
      default-timeout = 8000; # ms; 0 would mean "stay until dismissed"
      max-visible = 5;

      # Section syntax: an attr named "urgency=critical" becomes the
      # [urgency=critical] criteria section in mako's config file.
      "urgency=low" = {
        border-color = colors.a.ui;
        text-color = colors.a.com;
      };
      "urgency=critical" = {
        border-color = colors.b.red;
        default-timeout = 0; # critical notifications stay until dismissed
      };
    };
  };
}
