# home/satty.nix — screenshot annotator. No keybind launches it anymore:
# niri's built-in screenshot UI (Print) saves to ~/Pictures/Screenshots,
# and satty is run BY HAND on a saved file when a shot needs arrows/text:
#   satty --filename ~/Pictures/Screenshots/<shot>.png
# Owns everything satty: the package, config.toml, and its palette colors.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
in
{
  programs.satty = {
    enable = true;
    # Rendered to ~/.config/satty/config.toml.
    settings = {
      general = {
        # A tiling compositor would squeeze satty into whatever gap is
        # free — fullscreen it so there's actually room to annotate.
        fullscreen = true;
        early-exit = true; # close after the first save/copy
        copy-command = "wl-copy"; # wayland clipboard
        # Copying ALSO writes the file below, so every screenshot lands on
        # both the clipboard AND disk in one action.
        save-after-copy = true;
        initial-tool = "arrow";
        # strftime placeholders expanded by satty. The "annotated-" prefix is
        # just a readable marker on the saved filenames.
        output-filename = "${config.home.homeDirectory}/Pictures/Screenshots/annotated-%Y%m%d-%H%M%S.png";
        actions-on-enter = [ "save-to-clipboard" ]; # Enter = copy(+save)+exit
        actions-on-escape = [ "exit" ];
      };
      color-palette = {
        # Toolbar quick-pick colors — the melange vivid accents.
        palette = with colors.b; [ red yellow green cyan blue magenta ];
      };
    };
  };
}
