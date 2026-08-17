# home/alacritty.nix — terminal, themed by DMS.
{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    # `settings` is written out as alacritty.toml.
    settings = {
      # Colors come from DMS: its matugen alacritty template rewrites
      # dank-theme.toml from the wallpaper palette on every palette change,
      # and alacritty live-reloads imports — so the terminal recolors the
      # moment the wallpaper does. home/dms.nix seeds an (initially empty)
      # placeholder so the import never dangles before the first render.
      # (dank-theme.toml is DMS's fixed output path — machine-local and
      # imperatively written, so never an xdg.configFile.)
      general.import = [ "~/.config/alacritty/dank-theme.toml" ];

      # IBM Plex Mono, on trial since 2026-08-09 (was "Lilex Nerd Font Mono" —
      # revert to that one string to back it out; the package is still
      # installed either way, kept for exactly that in modules/desktop.nix).
      # Doom is on the same family now (home/doom/config.el). "BlexMono" is
      # Nerd Fonts' patch of Plex Mono — same outlines, renamed around IBM's
      # trademark; the patched build rather than the plain one because the
      # prompt and TUIs need nerd glyphs in the font itself (modules/desktop.nix
      # has the long version). The *Mono* variant, not plain "BlexMono Nerd
      # Font": the Mono patch constrains the added glyphs to a single cell,
      # which is what a terminal grid needs.
      # The size carries over from Lilex unchanged — Lilex IS Plex Mono with
      # ligatures added, so the metrics are the same font's.
      # NB: alacritty falls back silently on an unknown family — it only
      # warns on stderr — so a typo here looks like "nothing changed".
      font = {
        normal.family = "BlexMono Nerd Font Mono";
        size = 12.0;
      };

      window.padding = {
        x = 6;
        y = 6;
      };

      # The one translucent surface in the setup. (The hyprland era blurred
      # what showed through; niri has no blur, so this is now plain
      # see-through onto the wallpaper — kept at 0.92 deliberately, bump to
      # 1.0 if legibility over busy wallpapers suffers.)
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
