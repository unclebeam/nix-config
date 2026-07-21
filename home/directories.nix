# directories.nix — the home-directory skeleton, so a fresh install lands in
# a usable $HOME instead of a bare one. Two mechanisms, one intent:
#
#  * xdg.userDirs for the standard folders: besides `mkdir`ing them on every
#    activation (createDirectories), it writes ~/.config/user-dirs.dirs, which
#    is what file dialogs (the KDE portal's FileChooser), browsers' download
#    prompts, and `xdg-user-dir` actually consult — so declaring the dir HERE
#    also points every app at it.
#  * a plain activation script for the two non-XDG dirs (~/org, ~/.ssh),
#    following the dmsPlaceholders pattern in home/dms.nix.
{ config, lib, pkgs, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = true; # mkdir -p on every activation — idempotent

    # Only these three exist by decision (2026-07-21): Documents and
    # Downloads for the obvious reasons, Pictures because screenshots
    # (DMS/satty) and wallpapers conventionally land there.
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";

    # Everything else explicitly null: the module's DEFAULTS are the full
    # conventional set (Desktop, Music, …), so merely omitting them would
    # create all the clutter we're avoiding. null keeps the entry out of
    # user-dirs.dirs entirely; per the xdg-user-dirs spec, apps asking for
    # an unset dir fall back to $HOME. (`projects` is this home-manager
    # release's nonstandard extra, nulled for the same reason.)
    desktop = null;
    music = null;
    projects = null;
    publicShare = null;
    templates = null;
    videos = null;
  };

  # The non-XDG pair. `[ -e ]`-free on purpose: mkdir -p and chmod are both
  # idempotent, and re-asserting 700 on ~/.ssh every activation is a
  # feature — ssh silently ignores keys under a group/world-readable dir,
  # a failure mode that presents as "my key stopped working".
  home.activation.homeSkeleton = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/org  # org-mode notes — matches Doom's org-directory (home/doom/config.el)
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
  '';
}
