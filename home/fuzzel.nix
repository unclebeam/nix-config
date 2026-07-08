# home/fuzzel.nix — application launcher (SUPER+D, bound in home/hypr/hyprland.lua).
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
  # fuzzel wants rrggbbaa WITHOUT the leading '#'; palette entries carry
  # one, so strip it and append full opacity.
  rgba = c: lib.removePrefix "#" c + "ff";
in
{
  programs.fuzzel = {
    enable = true;
    # Rendered to ~/.config/fuzzel/fuzzel.ini — see fuzzel.ini(5).
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        terminal = "alacritty"; # for .desktop entries marked Terminal=true
        layer = "overlay";
        prompt = "\"❯ \"";
        lines = 12;
        width = 40;
      };
      colors = {
        background = rgba colors.a.float;
        text = rgba colors.a.fg;
        match = rgba colors.b.yellow;          # highlighted matching chars
        selection = rgba colors.a.sel;
        selection-text = rgba colors.a.fg;
        selection-match = rgba colors.b.yellow;
        border = rgba colors.a.com;
      };
      border = {
        width = 2;
        radius = 0; # square corners — the launcher stays plain on purpose
      };
    };
  };
}
