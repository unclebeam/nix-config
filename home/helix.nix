# home/helix.nix — Helix editor: package, language servers, plain-file config.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [
    # Helix tracks UNSTABLE for newer editor releases (see flake.nix); the LSPs
    # below stay on stable — only the editor moves.
    pkgs-unstable.helix
    # LSPs/formatters are Nix packages, never editor-installed (no Mason):
    pkgs.nil    # Nix language server — helix picks it up by default, zero config
    pkgs.nixfmt # Nix formatter — wired up in helix/languages.toml
  ];

  # Configs stay PLAIN files — symlinked, not Nix-generated. Edit the TOML
  # directly; never convert this to a programs.helix settings attrset.
  xdg.configFile."helix/config.toml".source = ./helix/config.toml;
  xdg.configFile."helix/languages.toml".source = ./helix/languages.toml;

  # git commit messages, sudoedit, etc. open Helix.
  home.sessionVariables.EDITOR = "hx";
}
