# home/claude.nix — Claude Code CLI: package, user settings, statusline.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [
    # Tracks UNSTABLE — Claude Code releases far faster than the NixOS
    # release branch; updates arrive via `nix flake update` moving the
    # unstable pin + rebuild (its built-in auto-updater can't write into
    # the read-only Nix store). Moved here from modules/core.nix so
    # removing the app is atomic: this file + one import line.
    pkgs-unstable.claude-code
    # statusline.sh parses its stdin JSON with jq on every render; jq
    # isn't in the system packages. curl (its other dep) is, via core.nix.
    pkgs.jq
  ];

  # Configs stay PLAIN files — the same files are hand-copied to the
  # Mac's ~/.claude, so keep them portable (tilde paths, no Nix
  # interpolation). ~/.claude is NOT under XDG, hence home.file rather
  # than xdg.configFile.
  #
  # settings.json is a read-only store symlink: in-app `/config` edits
  # will fail — edit the repo file and rebuild instead. If Claude Code
  # ever replaces the symlink with a real file, the next switch backs it
  # up (*.backup, see flake.nix) and re-links: self-healing.
  home.file.".claude/settings.json".source = ./claude/settings.json;
  home.file.".claude/statusline.sh" = {
    source = ./claude/statusline.sh;
    # Invoked as `bash <path>` so the bit isn't required — set anyway so
    # the script can be run directly when debugging.
    executable = true;
  };
  # Deliberately NOT managed: ~/.claude/.credentials.json (written by
  # `claude login`) and statusline-usage-cache.json (a 60s API cache the
  # script writes). The dir itself stays a normal writable directory —
  # home-manager only symlinks the two files above into it.
}
