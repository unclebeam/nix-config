# home/emacs.nix — Doom Emacs: the emacs package + live-symlinked doom config.
#
# Doom is managed the CLASSIC way, mirroring how nvim treats lazy.nvim:
# Nix ships the editor and CLI tools; Doom itself (the framework) is a plain
# git clone in ~/.config/emacs that installs its own elisp packages via
# `doom sync` — never nix-doom-emacs or other Nix-generated equivalents
# (same "editor configs stay plain files" rule as nvim, see CLAUDE.md).
#
# The framework clone into ~/.config/emacs is AUTOMATIC (clone-doom-emacs
# service below). What remains manual, once per machine on first login:
#   doom install                       # builds Doom's packages (~minutes);
#                                      # our tracked home/doom/ already exists,
#                                      # so it skips generating a config
#   doom doctor                        # sanity check (new shell for the PATH entry)
#   systemctl --user restart emacs.service  # the daemon started BARE before
#                                      # install; restart so it loads Doom
#
# Removing emacs = delete this file, home/doom/, the import line in
# default.nix, symbola in modules/desktop.nix, and `rm -rf ~/.config/emacs
# ~/.local/share/doom ~/.emacs.d` for the imperative runtime state.
# (~/.emacs.d is just an eln-cache emacs sometimes recreates — but if it
# exists, emacs prefers it over ~/.config/emacs and boots VANILLA, no Doom.)
{ config, lib, pkgs, ... }:

let
  # emacs-pgtk wrapped with the elisp packages whose NATIVE modules the editor
  # must never build or download itself (the no-Mason rule): :term vterm and
  # :term ghostel each need a dynamic module, and nixpkgs ships both prebuilt —
  # vterm-module.so compiled from C, ghostel-module.so compiled from Zig source.
  # Without this wrapper, first use would try `cmake` in-editor (vterm — fails,
  # no toolchain on PATH) or download a prebuilt binary from GitHub releases
  # (ghostel). ghostel finds its module as a sidecar next to ghostel.el, which
  # is exactly where nixpkgs installs it, so the downloader never fires.
  # Doom is told to use these copies via `:built-in t` in doom/packages.el —
  # straight's `:built-in 'prefer` detection only sees Emacs-core built-ins,
  # never Nix site packages, so the override there is load-bearing.
  emacsWithModules = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages
    (epkgs: [ epkgs.vterm epkgs.ghostel ]);
in
{
  home.packages = [
    # Emacs 30 with the pure-GTK frontend — the build that renders natively
    # on Wayland (the default build runs blurry under Xwayland).
    # Includes native-comp; Doom compiles its packages with it on sync.
    emacsWithModules
    # Doom's other hard requirements — git, ripgrep, fd — are in core.nix.

    # ── Doom module tools as Nix packages, never editor-installed ──
    # (same rule as nvim's no-Mason: `doom doctor` names what a module wants,
    # and enabling a Doom module later = add its external tools HERE first.)
    pkgs.shellcheck # :lang sh — shell script linting
    pkgs.shfmt # :lang sh — shfmt, apheleia formats shell scripts with it
    pkgs.multimarkdown # :lang markdown — compiler for markdown-preview
    # Same server nvim uses (home/neovim.nix); listed here TOO because each
    # editor's file declares its own tools (atomic removal — buildEnv dedupes).
    pkgs.nil # :lang nix +lsp — Nix language server; lsp-mode finds it on PATH
    # The RFC-style formatter is now the default `nixfmt` binary (the old
    # `nixfmt-rfc-style` attr is a deprecated alias that eval-warns). Command
    # name `nixfmt` — exactly what :lang nix's nix-format-buffer invokes.
    pkgs.nixfmt # :lang nix — nixfmt formatter
    # Same server + formatter nvim uses (home/neovim.nix); listed here TOO
    # for the same reason as pkgs.nil above — each editor's file declares its
    # own tools. Enabled here because the compositor config is Lua now
    # (home/hypr/*.lua), so Emacs edits it as often as nvim does.
    # lsp-mode's lua client resolves the binary with `executable-find`, so
    # being on PATH is the whole wiring — nothing to pin by hand the way
    # tailwind's server-path is pinned in doom/config.el.
    pkgs.lua-language-server # :lang (lua +lsp) — LuaLS
    # apheleia maps lua-mode → `stylua -` out of the box, so :editor
    # (format +onsave) formats lua the moment this is on PATH. It reads the
    # nearest stylua.toml: home/nvim's (2 spaces) for the nvim config,
    # stylua's defaults (tabs) for home/hypr/*.lua — which is exactly how
    # those files are already formatted, so this reformats nothing.
    pkgs.stylua # :lang lua — formatter

    # ── Next.js/TypeScript stack (:lang (javascript +lsp +tree-sitter)) ──
    # lsp-mode's ts-ls client for js/ts/tsx modes — no elisp config needed,
    # it just has to be on PATH. (nvim's LazyVim extra wants vtsls instead;
    # different servers, so nothing to promote/share between the editors.)
    pkgs.typescript-language-server
    # Fallback tsserver for the server above; real projects win — it prefers
    # the workspace's own node_modules/typescript when one exists.
    pkgs.typescript
    # vscode-json-language-server for :lang (json +lsp)
    # (package.json/tsconfig.json schema completion); the css/html/eslint
    # servers ride along, css serving (web +lsp).
    pkgs.vscode-langservers-extracted
    # Tailwind class completion in className= and css — lsp-mode's built-in
    # Tailwind client runs it as an ADD-ON server alongside ts-ls/css-ls
    # (doom/config.el points lsp-tailwindcss-server-path at this binary).
    pkgs.tailwindcss-language-server
    pkgs.prettier # :editor (format +onsave) — apheleia formats ts/tsx/css/json with it

    # :checkers (spell +flyspell) — Doom probes PATH for aspell → hunspell →
    # enchant and prefers aspell (its config tunes it: --sug-mode=ultra, a
    # personal dictionary under doom-data-dir). aspellWithDicts because the
    # bare aspell package ships ZERO dictionaries — on PATH but dictionary-less
    # it fails at first use instead of at startup, a quieter breakage than
    # today's "Can't find ispell" warning.
    (pkgs.aspellWithDicts (ds: with ds; [ en ]))
    # :checkers grammar — langtool's detection order tries the
    # `languagetool-commandline` binary FIRST (the branch is literally
    # commented "for nixpkgs.languagetool" upstream), which is exactly what
    # this package puts on PATH, JRE-wrapped so no Java setup needed.
    # writegood-mode, the module's other half, needs no external tool.
    pkgs.languagetool
  ];

  # ── Emacs daemon + client workflow ──────────────────────────────────────
  # The daemon pays Doom's startup cost once per session; every open after
  # that is `emacsclient -c` popping a frame instantly. NB: the daemon loads
  # the same ~/.config/emacs Doom clone — if the bootstrap above is missing,
  # it silently starts as BARE emacs (same dangle mode as the doom symlink).
  services.emacs = {
    enable = true;
    package = emacsWithModules; # same build as home.packages — one Emacs
    # Scope to the graphical session, not default.target: the pgtk build
    # needs WAYLAND_DISPLAY to create frames, and that only exists (and is
    # only imported into the systemd user environment) once hyprland is up.
    # hyprland-session.target BindsTo graphical-session.target
    # (home/hyprland.nix), so the daemon starts with the session and stops
    # at logout.
    startWithUserSession = "graphical";
    # Installs an "Emacs Client" launcher entry running emacsclient. The
    # stock "Emacs" entry is hidden below — a plain `emacs` launch would
    # silently spawn a SECOND full instance beside the daemon.
    client.enable = true;
    # -c: new frame per launch. Deliberately NO `-a ""` fallback: when the
    # daemon is down, `-a ""` makes emacsclient spawn its OWN `emacs --daemon`
    # outside systemd — a rogue that inherits the caller's env, survives
    # session teardown, and keeps the server socket, so the real emacs.service
    # then crash-loops with "Another instance of Emacs is running the server"
    # (this exact collision broke first activation on 2026-07-18). The service
    # auto-restarts on failure, so a down daemon should be a loud error here,
    # not a silent second daemon.
    client.arguments = [ "-c" ];
  };

  # Shadow emacs-pgtk's own emacs.desktop so the app launcher shows only
  # "Emacs Client" (xdg.desktopEntries installs with hiPrio precisely so it
  # can override a package's entry). The `emacs` binary itself stays on PATH.
  xdg.desktopEntries.emacs = {
    name = "Emacs";
    noDisplay = true;
  };

  # Tree-sitter grammars as Nix-built .so's, NOT Doom's runtime auto-install.
  # That auto-install cannot work here: tsx-ts-mode is registered with no
  # fallback mode, and Doom's ensure-grammar logic short-circuits for such
  # modes ("push forward anyway, even if a missing grammar results in a
  # broken state" — tools/tree-sitter/config.el), so the tsx grammar is
  # never installed and .tsx buffers open unhighlighted. Nix-built grammars
  # also fit the no-Mason rule (native tools come from Nix, not the editor).
  # The helper names each lib exactly as treesit dlopens it
  # (lib/libtree-sitter-<lang>.so); doom/config.el points
  # treesit-extra-load-path at this symlink, which exists so the plain-file
  # elisp config never has to reference a store path. The four grammars are
  # exactly what :lang (javascript +lsp +tree-sitter) registers.
  xdg.dataFile."emacs-tree-sitter-grammars".source =
    "${pkgs.emacsPackages.treesit-grammars.with-grammars (g: [
      g.tree-sitter-typescript
      g.tree-sitter-tsx
      g.tree-sitter-javascript
      g.tree-sitter-jsdoc
    ])}/lib";

  # Doom's framework clone is the one bootstrap half a fresh install can't
  # get from the repo (imperative state, like ~/nix-config itself — see
  # modules/nix-config.nix for the system-level twin of this pattern). This
  # oneshot clones it on the first login where it's missing;
  # ConditionPathExists makes it a permanent no-op afterwards, so it can
  # never touch a live install. If the clone fails (no network yet), git
  # deletes the half-made dir, the condition stays true, and Restart
  # retries every 15s until network is up — the same hardening as the
  # nix-config clone (whose fail-once version burned a first boot,
  # 2026-07-21; before 2026-08 this unit still had that gap and a
  # networkless first login meant no Doom until the NEXT login).
  # `doom install` stays MANUAL (header comment): it
  # builds Doom's ~300 packages for minutes and is upstream's supported
  # interactive path — an activation script is the wrong place for an
  # interactive, minutes-long bootstrap. No sha pin, latest Doom at
  # install time: Doom pins its
  # own package commits, so only the framework itself drifts (same
  # trade-off as the nix-config clone). %h is systemd for $HOME, and the
  # absolute store path to git means no PATH dependence at all.
  systemd.user.services.clone-doom-emacs = {
    Unit = {
      Description = "Clone Doom Emacs on first login (bootstrap target of doom install)";
      ConditionPathExists = "!%h/.config/emacs";
      # No start-rate limit: may retry for as long as the machine sits
      # without network (same reasoning as clone-nix-config).
      StartLimitIntervalSec = 0;
    };
    Service = {
      # `simple`, not `oneshot`, for the same reason as clone-nix-config:
      # a oneshot's start job holds default.target (login startup) until
      # the process exits — fine for one fast failure, minutes of blocked
      # session once we retry. simple completes the job on spawn.
      Type = "simple";
      ExecStart = "${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs %h/.config/emacs";
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Doom's CLI lives inside the clone; put it on PATH so `doom sync`,
  # `doom upgrade`, `doom doctor` work from any shell.
  home.sessionPath = [ "${config.home.homeDirectory}/.config/emacs/bin" ];

  # `doomreload` — the two-step ritual after editing home/doom/*.el, as one
  # command. `doom sync` rebuilds Doom's autoloads and packages; the daemon
  # must THEN be restarted or every `emacsclient -c` frame keeps serving the
  # old state (home/doom is an out-of-store symlink, so the .el edits
  # themselves are already live — it's the long-lived daemon that goes stale,
  # which is exactly the "I changed config.el and nothing happened" trap).
  #
  # `; or return $status` is load-bearing, not sugar: a failed sync leaves Doom
  # half-built, and restarting onto that swaps a working daemon for a broken
  # one. Fish's `&&` only joins commands on ONE line, so this is its two-line
  # equivalent — and it propagates sync's exit status out of the function.
  #
  # Lives HERE, not in home/fish.nix, because it exists because of Doom and so
  # must die with Doom (the one-file-per-intent rule). programs.fish.functions
  # merges across modules; fish itself is enabled in home/fish.nix. `doom`
  # resolves via the sessionPath entry directly above.
  programs.fish.functions.doomreload = {
    description = "doom sync, then restart the emacs daemon";
    body = ''
      doom sync; or return $status
      systemctl --user restart emacs.service
    '';
  };

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
