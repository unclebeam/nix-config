# home/neovim.nix — Neovim + LazyVim: package, external tools, live-symlinked
# config. home/nvim/ is the official LazyVim starter as PLAIN lua files —
# never nixvim. Local deviations: rocks disabled in lua/config/lazy.lua,
# Mason disabled in lua/plugins/mason.lua.
{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.neovim

    # ── LazyVim runtime tools ──
    pkgs.gcc # nvim-treesitter compiles parsers at runtime
    pkgs.tree-sitter # CLI, required by nvim-treesitter's main branch

    # ── LSPs/formatters as Nix packages, never editor-installed (no Mason) ──
    pkgs.lua-language-server
    pkgs.stylua
    pkgs.nil
    # Enabling a LazyVim language extra later = add its server HERE first
    # (trap: the TypeScript extra wants vtsls, not typescript-language-server).
  ];

  # Out-of-store symlink: LazyVim writes INTO its config dir (lazy-lock.json,
  # lazyvim.json — those belong in git), and lua edits should be live without
  # a rebuild. The path is a contract (~/nix-config on every machine); a
  # wrong path dangles SILENTLY and nvim just runs with no config.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-config/home/nvim";

  # git commit messages, sudoedit, etc. open Neovim.
  home.sessionVariables.EDITOR = "nvim";
}
