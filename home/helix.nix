# home/helix.nix — Helix editor: package, language servers, plain-file config.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [
    # Helix tracks UNSTABLE for newer editor releases (see flake.nix); the LSPs
    # below stay on stable — only the editor moves.
    pkgs-unstable.helix
    # LSPs/formatters are Nix packages, never editor-installed (no Mason):
    pkgs.nil    # Nix language server — helix picks it up by default, zero config
    pkgs.nixfmt # Nix formatter — wired up in helix/languages.toml

    # ─── TypeScript / React / Node stack (Next.js + NestJS, e.g. the bdi monorepo) ───
    # Command names below match helix's bundled defaults; installing the binary is
    # what makes each server work. All wired in helix/languages.toml.
    pkgs.typescript-language-server   # .ts/.tsx/.js completion, diagnostics, go-to-def
    pkgs.vscode-langservers-extracted # bundles json + css + html + eslint language servers
    pkgs.tailwindcss-language-server  # Tailwind v4 class completion & linting
    pkgs.prisma-language-server       # .prisma schema LSP
    pkgs.emmet-language-server        # Emmet expansion inside JSX/TSX/HTML
    # prettierd runs the PROJECT's own prettier from node_modules (falling back to
    # its bundled one), so a repo's .prettierrc + plugins like prettier-plugin-
    # tailwindcss are honored — a global prettier could not load those plugins.
    pkgs.prettierd
  ];

  # Configs stay PLAIN files — symlinked, not Nix-generated. Edit the TOML
  # directly; never convert this to a programs.helix settings attrset.
  xdg.configFile."helix/config.toml".source = ./helix/config.toml;
  xdg.configFile."helix/languages.toml".source = ./helix/languages.toml;

  # git commit messages, sudoedit, etc. open Helix.
  home.sessionVariables.EDITOR = "hx";
}
