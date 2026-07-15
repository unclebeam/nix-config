# colors.nix — THE palette. Single source of truth for every themed app.
#
# Values are verbatim from melange-nvim's dark palette
# (https://github.com/savq/melange-nvim, lua/melange/palettes/dark.lua),
# keeping upstream's group names:
#   a = UI colors (backgrounds → foreground, dark to light)
#   b = vivid accents ("bright" in terminal terms)
#   c = muted accents ("normal" in terminal terms)
#   d = dark accents (backgrounds for diffs/highlights)
#
# This file is a plain attrset, not a module — consumers do
#   colors = import ./colors.nix;
# and interpolate e.g. ${colors.a.bg} into CSS/INI/TOML strings.
# All values carry the leading "#"; strip it where a format demands
# (fuzzel) with lib.removePrefix "#".
{
  a = {
    bg    = "#292522"; # main background — warm dark brown
    float = "#34302C"; # floating window / panel background
    sel   = "#403A36"; # selection background
    ui    = "#867462"; # borders, inactive UI text
    com   = "#C1A78E"; # comments / secondary text
    fg    = "#ECE1D7"; # main foreground — warm cream
  };
  b = {
    red     = "#D47766";
    yellow  = "#EBC06D";
    green   = "#85B695";
    cyan    = "#89B3B6";
    blue    = "#A3A9CE";
    magenta = "#CF9BC2";
  };
  c = {
    red     = "#BD8183";
    yellow  = "#E49B5D";
    green   = "#78997A";
    cyan    = "#7B9695";
    blue    = "#7F91B2";
    magenta = "#B380B0";
  };
  d = {
    red     = "#7D2A2F";
    yellow  = "#8B7449";
    green   = "#233524";
    cyan    = "#253333";
    blue    = "#273142";
    magenta = "#422741";
  };
}
