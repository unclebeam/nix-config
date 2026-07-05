# home/zellij.nix — terminal multiplexer, themed from colors.nix.
#
# Zellij's theme colors are UI chrome (tab bar, status bar, pane frames),
# NOT the terminal colors — those still come from alacritty.nix. The theme
# uses zellij's classic 11-color spec: bg/black are ribbon & status-bar
# backgrounds, fg/white their text, green the "selected" ribbon.
{ config, lib, pkgs, pkgs-unstable, ... }:

let
  colors = import ./colors.nix;
in
{
  programs.zellij = {
    enable = true;
    # Fast-moving; track unstable (see flake.nix). Only swaps which build
    # home-manager installs — the settings/theme below are unaffected.
    package = pkgs-unstable.zellij;

    # `settings` becomes ~/.config/zellij/config.kdl via home-manager's
    # KDL generator. The theme is defined INLINE here on purpose: the
    # separate programs.zellij.themes option writes themes/<name>.kdl
    # without the `themes { name { ... } }` wrapper zellij requires,
    # so it would silently produce a broken theme file.
    settings = {
      theme = "melange";
      themes.melange = {
        fg = colors.a.fg;
        bg = colors.a.sel;      # selection / highlight surface
        black = colors.a.float; # status-bar bg — one step lighter than
                                # the terminal bg so the bar reads as a
                                # panel, not a hole
        white = colors.a.fg;
        red = colors.b.red;
        green = colors.b.green; # also the active-tab ribbon color
        yellow = colors.b.yellow;
        blue = colors.b.blue;
        magenta = colors.b.magenta;
        cyan = colors.b.cyan;
        orange = colors.c.yellow; # melange has no orange; its muted
                                  # yellow (#E49B5D) is an orange tone
      };
    };

    # Deliberately OFF (the default): enableFishIntegration would make
    # every interactive fish shell auto-start zellij. We launch it
    # explicitly. attachExistingSession / exitShellOnExit are no-ops
    # without that integration, so they're omitted too.
  };
}
