# home/alacritty.nix — terminal, themed by DMS.
{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      # Colors come from DMS: matugen rewrites dank-theme.toml on every
      # palette change and alacritty live-reloads imports. home/dms.nix
      # seeds an empty placeholder so the import never dangles (a dangling
      # import is a startup error). Machine-local, imperatively written —
      # never an xdg.configFile.
      general.import = [ "~/.config/alacritty/dank-theme.toml" ];

      # "BlexMono" is Nerd Fonts' patch of IBM Plex Mono (same family in
      # Doom); the *Mono* variant constrains added glyphs to a single cell,
      # which a terminal grid needs. Revert target: "Lilex Nerd Font Mono"
      # (package kept in modules/desktop.nix). NB: alacritty falls back
      # SILENTLY on an unknown family — a typo looks like "nothing changed".
      font = {
        normal.family = "BlexMono Nerd Font Mono";
        size = 12.0;
      };

      window.padding = {
        x = 6;
        y = 6;
      };

      # The one translucent surface in the setup (niri has no blur — plain
      # see-through). Bump to 1.0 if legibility over busy wallpapers suffers.
      window.opacity = 0.92;

      # Shift+Enter normally sends the same bytes as Enter, so TUI apps
      # (Claude Code) submit instead of inserting a newline; send ESC+CR
      # (alt+enter) instead. The string must contain the LITERAL ESC char —
      # Nix has no \u escape, hence fromJSON; writing "\\u001b" would make
      # the key type six characters.
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
