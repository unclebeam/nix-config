# home/emacs.nix — Doom Emacs: the emacs package + live-symlinked doom config.
# Doom is managed the classic way (same "editor configs stay plain files"
# rule as nvim): Nix ships the editor and CLI tools; Doom itself is a plain
# git clone in ~/.config/emacs (automated below) that installs its own elisp
# via `doom sync` — never nix-doom-emacs.
#
# Manual, once per machine on first login:
#   doom install                       # builds Doom's packages (~minutes)
#   doom doctor                        # sanity check (new shell for PATH)
#   systemctl --user restart emacs.service  # daemon started bare pre-install
#
# Removing emacs = this file, home/doom/, the import line, symbola in
# modules/desktop.nix, and `rm -rf ~/.config/emacs ~/.local/share/doom
# ~/.emacs.d` (if ~/.emacs.d exists, emacs prefers it and boots vanilla).
{ config, lib, pkgs, ... }:

let
  # emacs-pgtk wrapped with the elisp packages whose NATIVE modules the
  # editor must never build or download itself (the no-Mason rule): vterm
  # and ghostel each need a dynamic module, and nixpkgs ships both prebuilt.
  # ghostel finds its module as a sidecar next to ghostel.el — exactly where
  # nixpkgs installs it, so its GitHub downloader never fires. Doom is told
  # to use these copies via `:built-in t` in doom/packages.el — load-bearing:
  # straight's `:built-in 'prefer` only detects Emacs-core built-ins, never
  # Nix site packages.
  emacsWithModules = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages
    (epkgs: [ epkgs.vterm epkgs.ghostel ]);
in
{
  home.packages = [
    # The pure-GTK build — renders natively on Wayland (default build is
    # blurry under Xwayland). Includes native-comp.
    emacsWithModules
    # Doom's other hard requirements — git, ripgrep, fd — are in core.nix.

    # ── Doom module tools as Nix packages, never editor-installed ──
    # (enabling a Doom module later = add its external tools here first;
    # `doom doctor` names what a module wants.)
    pkgs.shellcheck # :lang sh
    pkgs.shfmt # :lang sh — apheleia formats shell scripts with it
    pkgs.multimarkdown # :lang markdown — compiler for markdown-preview
    # nil/nixfmt/LuaLS/stylua are also in home/neovim.nix — each editor's
    # file declares its own tools (atomic removal; buildEnv dedupes).
    pkgs.nil # :lang nix +lsp
    # The RFC-style formatter is now the default `nixfmt` binary; command
    # name `nixfmt` is exactly what nix-format-buffer invokes.
    pkgs.nixfmt # :lang nix
    # lsp-mode resolves lua-language-server via executable-find, so being on
    # PATH is the whole wiring.
    pkgs.lua-language-server # :lang (lua +lsp)
    # apheleia maps lua-mode → `stylua -` out of the box; reads the nearest
    # stylua.toml (home/nvim's), so this reformats nothing.
    pkgs.stylua # :lang lua

    # ── Next.js/TypeScript stack (:lang (javascript +lsp +tree-sitter)) ──
    # ts-ls just has to be on PATH. (nvim uses vtsls — different servers,
    # nothing to share.)
    pkgs.typescript-language-server
    # Fallback tsserver; real projects win — it prefers the workspace's own
    # node_modules/typescript.
    pkgs.typescript
    # json/css/html/eslint servers for :lang (json +lsp) and (web +lsp).
    pkgs.vscode-langservers-extracted
    # Add-on Tailwind server alongside ts-ls/css-ls; doom/config.el pins
    # lsp-tailwindcss-server-path at this binary.
    pkgs.tailwindcss-language-server
    pkgs.prettier # :editor (format +onsave) — ts/tsx/css/json

    # :checkers spell — Doom prefers aspell. aspellWithDicts because bare
    # aspell ships ZERO dictionaries: on PATH but dictionary-less it fails at
    # first use instead of at startup.
    (pkgs.aspellWithDicts (ds: with ds; [ en ]))
    # :checkers grammar — langtool's detection tries the
    # `languagetool-commandline` binary first, which is exactly what this
    # package puts on PATH (JRE-wrapped, no Java setup).
    pkgs.languagetool
  ];

  # Daemon + client: Doom's startup cost paid once per session; every open is
  # an instant `emacsclient -c` frame. NB: if the Doom clone is missing the
  # daemon silently starts as BARE emacs.
  services.emacs = {
    enable = true;
    package = emacsWithModules; # same build as home.packages — one Emacs
    # Graphical scope, not default.target: pgtk needs WAYLAND_DISPLAY, which
    # only exists in the user manager once niri is up.
    startWithUserSession = "graphical";
    # "Emacs Client" launcher entry; the stock entry is hidden below.
    client.enable = true;
    # -c: new frame per launch. Deliberately NO `-a ""` fallback: with the
    # daemon down it would spawn a rogue daemon outside systemd that keeps
    # the server socket and crash-loops the real emacs.service ("Another
    # instance of Emacs is running the server"). A down daemon should be a
    # loud error, not a silent second daemon.
    client.arguments = [ "-c" ];
  };

  # Hide emacs-pgtk's own emacs.desktop so the launcher shows only "Emacs
  # Client" — a plain `emacs` launch would spawn a second full instance
  # beside the daemon. The binary stays on PATH.
  xdg.desktopEntries.emacs = {
    name = "Emacs";
    noDisplay = true;
  };

  # Tree-sitter grammars as Nix-built .so's, NOT Doom's runtime auto-install:
  # tsx-ts-mode registers with no fallback mode and Doom's ensure-grammar
  # short-circuits for such modes, so the tsx grammar would never install and
  # .tsx buffers open unhighlighted. The helper names each lib exactly as
  # treesit dlopens it; doom/config.el points treesit-extra-load-path at this
  # symlink so the plain-file elisp never references a store path. Exactly
  # the four grammars :lang (javascript +lsp +tree-sitter) registers.
  xdg.dataFile."emacs-tree-sitter-grammars".source =
    "${pkgs.emacsPackages.treesit-grammars.with-grammars (g: [
      g.tree-sitter-typescript
      g.tree-sitter-tsx
      g.tree-sitter-javascript
      g.tree-sitter-jsdoc
    ])}/lib";

  # Clone Doom's framework on the first login where it's missing (imperative
  # state a fresh install can't get from the repo — system-level twin:
  # modules/nix-config.nix). ConditionPathExists makes it a permanent no-op
  # afterwards; a failed clone (no network) leaves the condition true and
  # Restart retries every 15s. `doom install` stays manual: an interactive,
  # minutes-long bootstrap doesn't belong in an activation script. No sha
  # pin — Doom pins its own package commits, only the framework drifts. %h
  # is systemd for $HOME.
  systemd.user.services.clone-doom-emacs = {
    Unit = {
      Description = "Clone Doom Emacs on first login (bootstrap target of doom install)";
      ConditionPathExists = "!%h/.config/emacs";
      # May retry for as long as the machine sits without network.
      StartLimitIntervalSec = 0;
    };
    Service = {
      # `simple`, not `oneshot`: a oneshot's start job would hold login
      # startup for minutes of retries; simple completes the job on spawn.
      Type = "simple";
      ExecStart = "${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs %h/.config/emacs";
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Doom's CLI lives inside the clone; `doom sync/upgrade/doctor` from any
  # shell.
  home.sessionPath = [ "${config.home.homeDirectory}/.config/emacs/bin" ];

  # The two-step ritual after editing home/doom/*.el as one command: the .el
  # edits are already live (out-of-store symlink), but the long-lived daemon
  # goes stale until restarted — the "I changed config.el and nothing
  # happened" trap. `; or return $status` is load-bearing: a failed sync
  # leaves Doom half-built, and restarting onto that swaps a working daemon
  # for a broken one (fish's && only joins one line; this is the two-line
  # equivalent). Lives here, not fish.nix: it must die with Doom
  # (one-file-per-intent; programs.fish.functions merges across modules).
  programs.fish.functions.doomreload = {
    description = "doom sync, then restart the emacs daemon";
    body = ''
      doom sync; or return $status
      systemctl --user restart emacs.service
    '';
  };

  # Same out-of-store contract as nvim (see home/neovim.nix): wrong path
  # dangles silently — Doom refuses to run without a DOOMDIR. Out-of-store
  # because Doom writes back into this dir and the .el files are edited
  # constantly.
  xdg.configFile."doom".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-config/home/doom";

  # EDITOR stays nvim (home/neovim.nix owns it) — emacs is launched as an app.
}
