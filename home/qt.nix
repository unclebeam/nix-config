# home/qt.nix — the ONE Qt look, for every Qt app in the session.
#
# This started life inside dolphin.nix ("one file per intent"), but Qt
# theming now has a second consumer beyond Dolphin: hyprland-share-picker,
# the Qt6 dialog xdg-desktop-portal-hyprland spawns when a browser asks to
# share the screen. Ark and kwalletmanager ride along too. Per CLAUDE.md,
# a second consumer is exactly when settings get promoted to a shared
# file — so here it lives.
#
# Two halves, and BOTH are needed:
#  1. qt.enable + style "breeze" — home-manager installs the breeze style
#     package and exports QT_STYLE_OVERRIDE + Qt plugin paths session-wide.
#     Without it every Qt app falls back to bare grey Fusion.
#  2. kdeglobals — the Breeze *style* draws the widgets, but it takes its
#     COLORS from KColorScheme, which reads ~/.config/kdeglobals directly
#     (works standalone: no Plasma, no platformTheme needed). Without this
#     file Breeze uses its stock LIGHT palette — which is how the share
#     picker ended up glaring white in a melange session.
#
# Deliberately NOT setting platformTheme = "kde": it drags in
# plasma-integration and systemsettings for marginal gain.
#
# Colors are read at app START (KConfig parses the file on construction),
# not from the environment — after a rebuild, simply reopening an app shows
# the new scheme. No re-login, no portal restart.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;

  # kdeglobals wants decimal "r,g,b" triples; the palette carries "#rrggbb".
  # "#292522" -> "41,37,34".
  rgb = hex:
    let
      h = lib.removePrefix "#" hex;
      at = i: toString (lib.fromHexString (builtins.substring i 2 h));
    in
    "${at 0},${at 2},${at 4}";

  # One KColorScheme "color set" (Window/View/Button/...). Only the two
  # backgrounds differ between sets; the semantic foregrounds and the
  # focus/hover decorations are the same everywhere:
  #   - inactive text  = a.ui   (same role it plays everywhere in the repo)
  #   - error/warn/ok  = b.red / b.yellow / b.green
  #   - links          = b.blue, visited = b.magenta
  #   - focus ring     = b.yellow (matches fuzzel's match highlight)
  #   - hover glow     = a.com   (matches sway's focused border)
  colorSet = bg: alt: {
    BackgroundNormal = rgb bg;
    BackgroundAlternate = rgb alt;
    ForegroundNormal = rgb colors.a.fg;
    ForegroundInactive = rgb colors.a.ui;
    ForegroundActive = rgb colors.b.yellow;
    ForegroundLink = rgb colors.b.blue;
    ForegroundVisited = rgb colors.b.magenta;
    ForegroundNegative = rgb colors.b.red;
    ForegroundNeutral = rgb colors.b.yellow;
    ForegroundPositive = rgb colors.b.green;
    DecorationFocus = rgb colors.b.yellow;
    DecorationHover = rgb colors.a.com;
  };
in
{
  qt = {
    enable = true;
    style.name = "breeze";
  };

  # NOTE: this makes ~/.config/kdeglobals a read-only store symlink. KDE
  # apps that try to persist state into it (systemsettings, "recent colors"
  # pickers) will silently fail to save — acceptable here, since nothing
  # installed writes to kdeglobals (Dolphin/Ark keep their state in
  # dolphinrc/arkrc). If a future switch ever aborts with "existing file is
  # in the way", something clobbered the symlink: delete the file and
  # re-switch.
  xdg.configFile."kdeglobals".text = lib.generators.toINI { } {
    # Purely informational — KColorScheme reads the [Colors:*] groups below
    # directly; this name is just what scheme-aware tools report.
    General.ColorScheme = "MelangeDark";

    # Surface layering, same logic as the rest of the session: content
    # areas (file lists, text fields) sit on the main bg, window chrome /
    # toolbars / dialogs sit on the slightly lighter "float" panel color
    # (exactly like fuzzel), and buttons rise one more step to "sel".
    "Colors:Window" = colorSet colors.a.float colors.a.sel;
    "Colors:View" = colorSet colors.a.bg colors.a.float;
    "Colors:Button" = colorSet colors.a.sel colors.a.float;
    "Colors:Selection" = colorSet colors.a.sel colors.a.sel;
    "Colors:Tooltip" = colorSet colors.a.float colors.a.float;
    # Header = the toolbar strip in newer KDE Gear apps; Complementary = the
    # odd full-bleed surface (some sidebars/OSDs). Cover both so no widget
    # falls back to stock light.
    "Colors:Header" = colorSet colors.a.float colors.a.sel;
    "Colors:Complementary" = colorSet colors.a.bg colors.a.float;
  };
}
