# home/satty.nix — screenshot annotator. Every screenshot flows through it:
# the Print binds (home/hypr/binds.lua) run `noctalia msg screenshot-*`,
# and Noctalia's screenshot config (home/noctalia/config.toml,
# [shell.screenshot]) pipes the capture straight into satty on stdin
# (`satty -f -`) with file/clipboard output off — nothing touches disk or
# clipboard until you commit inside satty (Enter); Escape discards. A
# cancelled region select never spawns satty at all.
# Owns everything satty: the package and config.toml.
#
# (History: under DMS this file also carried a `screenshot-annotate`
# wrapper — capture-to-stdout glue plus a clipboard re-own that stopped
# Chromium windows yanking focus when DMS's region UI touched the
# selection during init. Noctalia's pipe design needs no wrapper, and its
# overlay isn't known to touch the clipboard pre-capture — if the
# workspace ever jumps to a browser mid-capture again, that bug is back;
# see git history for the wl-copy re-own trick.)
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
      # Toolbar quick-pick colors: satty's stock palette — annotation
      # colors want to be legible on any screenshot, not to match a theme.
    };
  };
}
