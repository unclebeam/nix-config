;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; BlexMono = Nerd Fonts' patch of IBM Plex Mono, matching alacritty. The
;; *Mono* variant deliberately: one-cell nerd glyphs keep the modeline/dired
;; grid aligned. Revert target: "Lilex Nerd Font Mono" (package stays
;; installed via modules/desktop.nix).
(setq doom-font (font-spec :family "BlexMono Nerd Font Mono" :size 16))
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; org expands a directory entry NON-recursively, so files in the PARA
;; subfolders were invisible to the agenda — list every non-hidden
;; subdirectory alongside ~/org. New FILES appear immediately (dirs re-scan
;; per agenda build); a brand-new top-level FOLDER needs a daemon restart.
;; "^[^.]" also keeps Syncthing's .stfolder out. after! because Doom's own
;; default assignment runs when org loads.
(after! org
  (setq org-agenda-files
        (cons org-directory
              (seq-filter #'file-directory-p
                          (directory-files org-directory t "^[^.]")))))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! lsp-mode
  ;; no-Mason: servers come from Nix (home/emacs.nix), never editor-downloaded.
  (setq lsp-enable-suggest-server-download nil)
  ;; The built-in Tailwind client runs as an ADD-ON server alongside ts-ls
  ;; in .tsx buffers (the multi-server ability eglot lacks — why this config
  ;; uses lsp-mode). Empty server-path would mean an lsp-managed download;
  ;; point it at the Nix binary instead.
  (setq lsp-tailwindcss-server-path
        (executable-find "tailwindcss-language-server")))

;; Tree-sitter grammars come from Nix (home/emacs.nix symlinks them here) —
;; Doom's runtime auto-install can never install the tsx grammar (its ensure
;; logic short-circuits for ts-modes with no fallback mode). expand-file-name
;; because treesit concatenates dir + libname for dlopen; after! treesit
;; because the var is defined there.
(after! treesit
  (add-to-list 'treesit-extra-load-path
               (expand-file-name "~/.local/share/emacs-tree-sitter-grammars")))

;; TRIAL: vterm vs ghostel side-by-side; the loser gets deleted. Both Doom
;; modules bind SPC o t / SPC o T and vterm silently wins, so ghostel gets
;; its own keys. When the trial ends: delete this block, the losing module's
;; line in init.el, and its package! lines in packages.el.
(map! :leader
      (:prefix-map ("o" . "open")
       :desc "Toggle ghostel popup" "g" #'+ghostel/toggle
       :desc "Open ghostel here"    "G" #'+ghostel/here))
