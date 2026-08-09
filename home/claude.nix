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
  # Both are OUT-OF-STORE symlinks into the live checkout (same
  # ~/nix-config path contract as neovim.nix): edits — including Claude
  # Code's own writes from /model and /config, which used to fail against
  # the read-only store — land directly in the tracked repo file and
  # apply on the next launch, no rebuild. On a fresh install the links
  # dangle harmlessly until modules/nix-config.nix clones the checkout.
  # Caveat: if Claude Code ever saves via temp-file+rename instead of
  # writing in place, that clobbers the symlink into a plain file; the
  # next switch backs it up (*.backup, see flake.nix) and re-links:
  # self-healing, but the clobbered edit stays only in the backup.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/settings.json";
  # No `executable = true` here: through an out-of-store symlink the bit
  # lives on the repo file itself (kept +x in git); home-manager can't
  # set it. Invoked as `bash <path>` anyway, so it's only for debugging.
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/statusline.sh";
  # Deliberately NOT managed: ~/.claude/.credentials.json (written by
  # `claude login`) and statusline-usage-cache.json (a 60s API cache the
  # script writes). The dir itself stays a normal writable directory —
  # home-manager only symlinks the two files above into it.
}
