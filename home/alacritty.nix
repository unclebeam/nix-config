# home/alacritty.nix — terminal, themed by DMS.
{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    # `settings` is written out as alacritty.toml.
    settings = {
      # Colors come from DMS: dms (re)writes dank-theme.toml from the
      # wallpaper's matugen palette on every wallpaper change, and alacritty
      # live-reloads imports — so the terminal recolors the moment the
      # wallpaper does. home/dms.nix guarantees an (initially empty)
      # placeholder exists so the import never dangles before the shell's
      # first run.
      general.import = [ "~/.config/alacritty/dank-theme.toml" ];

      font = {
        normal.family = "IosevkaTerm Nerd Font Mono";
        size = 12.0;
      };

      window.padding = {
        x = 6;
        y = 6;
      };

      # The one translucent surface in the setup. (No blur behind it —
      # niri draws whatever is underneath straight through.)
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
