# home/satty.nix — screenshot annotator (Print / Ctrl+Print in sway).
# Owns everything satty: the package, config.toml, and its palette colors.
# The keybind itself stays in home/sway.nix: keybindings there are one
# attrset wrapped in mkOptionDefault, and a second definition from this
# file would OVERRIDE that set (higher priority wins), not merge into it.
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
        # Sway would tile satty into whatever gap is free — fullscreen it
        # so there's actually room to annotate.
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
