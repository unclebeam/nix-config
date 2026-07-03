# home/fish.nix — fish shell + starship prompt.
# (modules/core.nix enables fish system-wide and sets it as login shell;
# this file owns the per-user config.)
{ config, lib, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # fish ships a default welcome banner; silence it
      set -g fish_greeting
    '';
    shellAbbrs = {
      # abbreviations expand inline (you SEE the real command before enter)
      nrs = "sudo nixos-rebuild switch --flake .";
      nfc = "git add -A && nix flake check"; # flakes only see tracked files!
    };
  };

  # Prompt. Starship's defaults are good; tweak via programs.starship.settings
  # later if you want. Fish integration (init hook) is enabled by default.
  programs.starship.enable = true;
}
