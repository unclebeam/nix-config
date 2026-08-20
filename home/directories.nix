# directories.nix — home-directory skeleton for fresh installs. xdg.userDirs
# both creates the standard folders and writes ~/.config/user-dirs.dirs —
# what file dialogs, download prompts and `xdg-user-dir` consult; a plain
# activation script covers the non-XDG dirs.
{ config, lib, pkgs, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = true; # mkdir -p on every activation — idempotent

    # Only these three by decision; Pictures because screenshots and
    # wallpapers land there.
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";

    # Explicitly null, not omitted: the module's defaults are the full
    # conventional set, so omitting would create the clutter. null keeps the
    # entry out of user-dirs.dirs; apps asking for an unset dir fall back to
    # $HOME. (`projects` is home-manager's nonstandard extra.)
    desktop = null;
    music = null;
    projects = null;
    publicShare = null;
    templates = null;
    videos = null;
  };

  # No [ -e ] guards on purpose: mkdir -p and chmod are idempotent, and
  # re-asserting 700 on ~/.ssh every activation is a feature — ssh silently
  # ignores keys under a group/world-readable dir.
  home.activation.homeSkeleton = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/org  # org-mode notes — matches Doom's org-directory (home/doom/config.el)
    # satty's fullscreen filename template writes here (home/satty.nix) and
    # does NOT create parent dirs — without this a fresh install's first
    # annotated screenshot save just fails.
    mkdir -p ~/Pictures/Screenshots
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
  '';
}
