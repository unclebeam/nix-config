# home/helix.nix — Helix editor: package, language servers, plain-file config.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    helix
    # LSPs/formatters are Nix packages, never editor-installed (no Mason):
    nil    # Nix language server — helix picks it up by default, zero config
    nixfmt # Nix formatter — wired up in helix/languages.toml
  ];

  # Configs stay PLAIN files — symlinked, not Nix-generated. Edit the TOML
  # directly; never convert this to a programs.helix settings attrset.
  xdg.configFile."helix/config.toml".source = ./helix/config.toml;
  xdg.configFile."helix/languages.toml".source = ./helix/languages.toml;

  # git commit messages, sudoedit, etc. open Helix.
  home.sessionVariables.EDITOR = "hx";
}
