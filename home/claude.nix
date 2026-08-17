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
  # Skills — the /gridfinity calculator, and the pattern for any future one.
  # This links the skill DIRECTORY, not the files inside it, and that is the
  # whole point: `gridfinity/SKILL.md` is a thin router that reads one file
  # out of `references/` per calculation, so adding a calculation is a new
  # file in the checkout and nothing here — no rebuild, live on the next
  # `claude` launch (skills are read at startup, so an already-running
  # session won't see an edit). Linking each file instead would cost a
  # rebuild per file. Same out-of-store rule and same hardcoded ~/nix-config
  # base path as the two files above; the tree is plain markdown so it
  # hand-copies to the Mac's ~/.claude/skills unchanged.
  #
  # ~/.claude/skills itself stays a normal writable directory — home-manager
  # only drops this one symlink into it, so an untracked skill can sit
  # beside it.
  home.file.".claude/skills/gridfinity".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/skills/gridfinity";

  # Deliberately NOT managed: ~/.claude/.credentials.json (written by
  # `claude login`) and statusline-usage-cache.json (a 60s API cache the
  # script writes). The dir itself stays a normal writable directory —
  # home-manager only symlinks the files above into it.
}
