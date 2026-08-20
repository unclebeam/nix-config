# home/claude.nix — Claude Code CLI: package, user settings, statusline.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [
    # Tracks unstable — releases far faster than the NixOS branch, and the
    # built-in auto-updater can't write into the read-only store.
    pkgs-unstable.claude-code
    # statusline.sh parses its stdin JSON with jq on every render; jq isn't
    # in the system packages. curl (its other dep) is, via core.nix.
    pkgs.jq
  ];

  # Configs stay PLAIN files — hand-copied to the Mac's ~/.claude too, so
  # keep them portable (tilde paths, no Nix interpolation). ~/.claude is not
  # under XDG, hence home.file. Out-of-store symlinks into the checkout:
  # edits — including Claude Code's own writes from /model and /config —
  # land in the tracked repo file, no rebuild. Caveat: a temp-file+rename
  # save would clobber the symlink into a plain file; the next switch backs
  # it up (*.backup) and re-links, keeping the clobbered edit only in the
  # backup.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/settings.json";
  # No `executable = true`: through an out-of-store symlink the bit lives on
  # the repo file itself (kept +x in git). Invoked as `bash <path>` anyway.
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/statusline.sh";
  # Links the skill DIRECTORY, not the files inside — the point: SKILL.md is
  # a thin router over references/, so adding a calculation is a new file in
  # the checkout, no rebuild, live on the next `claude` launch (skills are
  # read at startup). Plain markdown, hand-copies to the Mac unchanged.
  # ~/.claude/skills stays a normal writable dir — untracked skills can sit
  # beside this one.
  home.file.".claude/skills/gridfinity".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/claude/skills/gridfinity";

  # Deliberately NOT managed: .credentials.json (`claude login`) and
  # statusline-usage-cache.json (the script's 60s API cache).
}
