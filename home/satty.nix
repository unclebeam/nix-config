# home/satty.nix — screenshot annotator. No keybind launches it anymore:
# the Print binds run `dms screenshot` (DMS's built-in capture UI, in the
# DMS-managed ~/.config/hypr/dms/binds.lua), saving to ~/Pictures/Screenshots,
# and satty is run BY HAND on a saved file when a shot needs arrows/text:
#   satty --filename ~/Pictures/Screenshots/<shot>.png
# Owns everything satty: the package and config.toml.
{ config, lib, pkgs, ... }:

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
      # Toolbar quick-pick colors: satty's stock palette. (The old melange
      # override left with colors.nix in the DMS migration — annotation
      # colors want to be legible on any screenshot, not to match a theme.)
    };
  };
}
