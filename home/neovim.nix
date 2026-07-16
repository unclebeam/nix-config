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
    pkgs.fd # file finder for pickers (ripgrep/fzf are already in core.nix)
    pkgs.gcc # nvim-treesitter compiles parsers at runtime into ~/.local/share/nvim
    pkgs.tree-sitter # tree-sitter CLI, required by nvim-treesitter's main branch

    # ── LSPs/formatters as Nix packages, never editor-installed (no Mason) ──
    pkgs.lua-language-server # LazyVim's default lua tooling (edits this very config)
    pkgs.stylua # lua formatter, ditto
    # nil (nix LSP) is already on PATH via home/helix.nix — neovim reuses it.
    # If helix ever goes away, nil must move here.
    # Enabling a LazyVim language extra later = add its server HERE first
    # (trap: the TypeScript extra wants vtsls, not typescript-language-server).
  ];

  # DELIBERATE deviation from the niri/helix store-symlink pattern:
  # ~/.config/nvim is an out-of-store symlink to this repo checkout, because
  # (a) LazyVim writes INTO its config dir (lazy-lock.json plugin lockfile,
  #     lazyvim.json extras state) and those belong in git for reproducible
  #     plugin versions — a read-only store symlink would break them, and
  # (b) lua config gets edited constantly while learning LazyVim — a store
  #     symlink would force a rebuild+switch per edit; this way edits are live.
  # Cost: the path below must be where the repo is cloned on every machine.
  # On a fresh install the link dangles (harmlessly) until the repo exists.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/repositories/github.com/unclebeam/nix-config/home/nvim";
}
