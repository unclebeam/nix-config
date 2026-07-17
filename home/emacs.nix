# home/emacs.nix — Doom Emacs: the emacs package + live-symlinked doom config.
#
# Doom is managed the CLASSIC way, mirroring how nvim treats lazy.nvim:
# Nix ships the editor and CLI tools; Doom itself (the framework) is a plain
# git clone in ~/.config/emacs that installs its own elisp packages via
# `doom sync` — never nix-doom-emacs or other Nix-generated equivalents
# (same "editor configs stay plain files" rule as nvim, see CLAUDE.md).
#
# One-time bootstrap on each machine (imperative state Nix can't create):
#   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#   ~/.config/emacs/bin/doom install   # writes init/config/packages.el through
#                                      # the symlink below into home/doom/
#   doom doctor                        # sanity check (new shell for the PATH entry)
#
# Removing emacs = delete this file, home/doom/, the import line in
# default.nix, symbola in modules/desktop.nix, and `rm -rf ~/.config/emacs
# ~/.local/share/doom ~/.emacs.d` for the imperative runtime state.
# (~/.emacs.d is just an eln-cache emacs sometimes recreates — but if it
# exists, emacs prefers it over ~/.config/emacs and boots VANILLA, no Doom.)
{ config, lib, pkgs, ... }:

{
  home.packages = [
    # Emacs 30 with the pure-GTK frontend — the build that renders natively
    # on Wayland/niri (the default build runs blurry under Xwayland).
    # Includes native-comp; Doom compiles its packages with it on sync.
    pkgs.emacs-pgtk
    # Doom's other hard requirements — git, ripgrep, fd — are in core.nix.

    # ── Doom module tools as Nix packages, never editor-installed ──
    # (same rule as nvim's no-Mason: `doom doctor` names what a module wants,
    # and enabling a Doom module later = add its external tools HERE first.)
    pkgs.shellcheck # :lang sh — shell script linting
    pkgs.multimarkdown # :lang markdown — compiler for markdown-preview
  ];

  # Doom's CLI lives inside the clone; put it on PATH so `doom sync`,
  # `doom upgrade`, `doom doctor` work from any shell.
  home.sessionPath = [ "${config.home.homeDirectory}/.config/emacs/bin" ];

  # Same out-of-store contract as nvim (see home/neovim.nix for the full
  # story): the repo checkout lives at ~/nix-config on EVERY machine, and a
  # wrong path dangles SILENTLY (emacs just starts with Doom's defaults…
  # actually with nothing, since Doom refuses to run without a DOOMDIR).
  # Out-of-store because Doom writes back into this dir (custom.el, and
  # `doom install` generates the initial files) and the .el files get edited
  # constantly — a store symlink would mean rebuild+switch per edit.
  xdg.configFile."doom".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-config/home/doom";

  # EDITOR stays nvim (home/neovim.nix owns it) — emacs is launched as an app.
}
