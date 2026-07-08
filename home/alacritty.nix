# home/alacritty.nix — terminal, themed from colors.nix.
#
# The color mapping below reproduces the OFFICIAL melange Alacritty port
# (melange-nvim repo, term/alacritty/melange_dark.toml) exactly — but
# generated from our one palette attrset instead of vendoring the file:
#   normal colors = the muted "c" row (+ UI tones for black/white)
#   bright colors = the vivid "b" row
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
in
{
  programs.alacritty = {
    enable = true;
    # `settings` is written out as alacritty.toml.
    settings = {
      colors = {
        primary = {
          background = colors.a.bg;
          foreground = colors.a.fg;
        };
        normal = {
          black   = colors.a.float;
          red     = colors.c.red;
          green   = colors.c.green;
          yellow  = colors.c.yellow;
          blue    = colors.c.blue;
          magenta = colors.c.magenta;
          cyan    = colors.c.cyan;
          white   = colors.a.com;
        };
        bright = {
          black   = colors.a.ui;
          red     = colors.b.red;
          green   = colors.b.green;
          yellow  = colors.b.yellow;
          blue    = colors.b.blue;
          magenta = colors.b.magenta;
          cyan    = colors.b.cyan;
          white   = colors.a.fg;
        };
      };

      font = {
        normal.family = "IosevkaTerm Nerd Font Mono";
        size = 12.0;
      };

      window.padding = {
        x = 6;
        y = 6;
      };

      # The one translucent surface in the setup — hyprland's blur
      # (home/hypr/hyprland.lua, decoration.blur) shows through here.
      # Under the sway fallback session there's no blur, so the
      # terminal is just faintly transparent there; acceptable.
      window.opacity = 0.92;

      # Shift+Enter normally sends the exact same bytes as plain Enter, so
      # TUI apps (Claude Code) can't tell them apart and submit the prompt
      # instead of inserting a newline. Send ESC+CR instead — the alt+enter
      # sequence, which Claude Code (and most readline-style inputs) treat
      # as "newline, don't submit".
      #
      # The string must contain the LITERAL ESC character (home-manager's
      # TOML writer then escapes it correctly); Nix has no \u escape, so we
      # conjure ESC via fromJSON. Writing "\\u001b" here would make the key
      # type the six characters \u001b instead.
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = (builtins.fromJSON ''"\u001b"'') + "\r";
        }
      ];
    };
  };
}
