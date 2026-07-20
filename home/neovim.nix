# home/neovim.nix — Neovim + LazyVim: package, external tools, live-symlinked config.
#
# The config under home/nvim/ is the official LazyVim starter
# (github.com/LazyVim/starter), vendored as PLAIN lua files — never nixvim
# (see CLAUDE.md). Local deviations from the starter: rocks disabled in
# lua/config/lazy.lua, and lua/plugins/mason.lua disabling Mason.
{ config, lib, pkgs, ... }:

{
  home.packages = [
    # Moved here from modules/core.nix — it grew per-user config (LazyVim),
    # and apps with per-user config live in home/. Stable's 0.12.x satisfies
    # LazyVim's >= 0.11.2 requirement, so no unstable needed.
    pkgs.neovim

    # ── LazyVim runtime tools (exist ONLY because of LazyVim) ──
    # (fd was here, but Doom Emacs became a second consumer — promoted to
    # core.nix next to ripgrep/fzf, which pickers also use from there.)
    pkgs.gcc # nvim-treesitter compiles parsers at runtime into ~/.local/share/nvim
    pkgs.tree-sitter # tree-sitter CLI, required by nvim-treesitter's main branch

    # ── LSPs/formatters as Nix packages, never editor-installed (no Mason) ──
    pkgs.lua-language-server # LazyVim's default lua tooling (edits this very config)
    pkgs.stylua # lua formatter, ditto
    pkgs.nil # Nix LSP — lspconfig finds it on PATH (moved here when helix was removed)
    # Enabling a LazyVim language extra later = add its server HERE first
    # (trap: the TypeScript extra wants vtsls, not typescript-language-server).
  ];

  # DELIBERATE deviation from the store-symlink pattern (hyprland.lua & co):
  # ~/.config/nvim is an out-of-store symlink to this repo checkout, because
  # (a) LazyVim writes INTO its config dir (lazy-lock.json plugin lockfile,
  #     lazyvim.json extras state) and those belong in git for reproducible
  #     plugin versions — a read-only store symlink would break them, and
  # (b) lua config gets edited constantly while learning LazyVim — a store
  #     symlink would force a rebuild+switch per edit; this way edits are live.
  # Cost: the path below is a CONTRACT — the repo checkout lives at
  # ~/nix-config on EVERY machine (recorded in CLAUDE.md's invariants).
  # This once pointed at a ghq-style ~/repositories/... path that didn't
  # exist, and the failure is silent: the link dangles without error and
  # nvim just runs with no config at all. On a fresh install it dangles
  # the same way (harmlessly) until the repo is cloned into place.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-config/home/nvim";

  # git commit messages, sudoedit, etc. open Neovim.
  home.sessionVariables.EDITOR = "nvim";
}
