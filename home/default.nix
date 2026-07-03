# home/default.nix — home-manager entrypoint, shared by BOTH hosts
# (imported from flake.nix as home-manager.users.unclebeam).
# Same user environment, same look, on every machine.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./sway.nix      # window manager config + swaylock + swayidle
    ./waybar.nix    # status bar
    ./fuzzel.nix    # launcher
    ./mako.nix      # notifications
    ./alacritty.nix # terminal
    ./fish.nix      # shell + prompt
  ];

  home.username = "unclebeam";
  home.homeDirectory = "/home/unclebeam";

  # Like system.stateVersion: the home-manager release this config was
  # born under. Set once, never bump casually.
  home.stateVersion = "26.05";

  # Let home-manager manage itself (provides the `home-manager` CLI).
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    # `settings` is written to ~/.config/git/config verbatim (sections.keys).
    settings = {
      user.name = "unclebeam";
      user.email = "patompong.beam@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
