# dms.nix — DankMaterialShell, the USER-side glue. The shell itself is
# enabled by the flake's NixOS module in modules/dms.nix (upstream's docs
# offer a NixOS module OR a home-manager module and say to pick one; the
# NixOS module won, so this file imports NO DMS module — it only holds the
# theming glue and config placeholders that genuinely belong to the user's
# home). The greeter is modules/dms-greeter.nix.
#
# The shell IS the desktop: bar, launcher (Spotlight), notifications, lock
# screen, idle policy, OSD, clipboard history, polkit agent, power menu,
# wallpaper, night mode — one quickshell process, run by the system-defined
# dms.service user unit. It replaced waybar/fuzzel/swaync/gtklock/swayidle/
# plasma-polkit-agent/power.nix in 2026-07.
#
# Interaction happens through `dms ipc call …` — that's what the DMS
# keybinds in ~/.config/hypr/dms/binds.lua (DMS-managed, deployed by
# `dms setup`, required by home/hypr/hyprland.lua) run. Configuration
# happens in the DMS Settings GUI (Mod+Comma): wallpaper, idle/lock
# timeouts (NB: idle lock starts UNSET — configure it on first login,
# swayidle is gone), the "Apply GTK/Qt Themes" toggles, widgets. Settings
# are deliberately NOT declared in Nix via the module's `settings` option:
# managing settings.json from Nix makes the GUI read-only, and the GUI is
# the point.
#
# ⚠ FRESH INSTALL: one manual step. Per upstream's documented flow, run
#   `dms setup` once (then `hyprctl reload`) after first login — it deploys
#   the default keybinds/layout/colors/… fragments below. Until then there
#   are NO keybinds (binds.lua is an empty placeholder), so do it from a
#   TTY (Ctrl+Alt+F2). It's safe to re-run anytime: the CLI refuses to
#   touch any file that already has content.
#   We deliberately do NOT run `dms setup` from the activation script
#   anymore. Two attempts both broke fresh installs in different ways
#   (`env VAR=… <store-path>` parsed the '=' inside the dms store path as
#   an assignment; and the CLI's privilege-escalation preflight fatals
#   unless sudo is on PATH, which activation's PATH isn't) — the CLI is
#   built for an interactive session, and upstream's manual step is the
#   supported path.
{ config, lib, pkgs, ... }:

{
  # The GTK3/4 theme that DMS's "Apply GTK Themes" toggle targets: DMS
  # generates matugen colors as gtk.css, and adw-gtk3 is the theme built to
  # be recolored that way. Without it the toggle has nothing to skin.
  home.packages = [ pkgs.adw-gtk3 ];

  # The seven DMS-owned Lua fragments hyprland.lua require()s (colors from
  # matugen; outputs/cursor/binds-user/windowrules from the Settings GUI;
  # binds/layout from `dms setup`). DMS writes them IMPERATIVELY, so a
  # read-only STORE symlink is forbidden here — but an OUT-OF-STORE symlink
  # (same rule and same hardcoded ~/nix-config base path as hypr/hyprland.lua
  # and home/neovim.nix) stays writable: dms writes land *through* the link
  # in the git working tree, where they're version-controlled like
  # hyprland.lua's. Expect churn: matugen rewrites colors.lua on every
  # wallpaper change — review/commit it like any other edit. Never generate
  # these files' CONTENT from Nix; the Settings GUI stays the editor.
  #
  # Tracking the fragments in git also replaces the old activation-script
  # `touch` placeholders: Lua's require() HARD-FAILS on a missing file
  # (unlike niri's `include optional=true`) and takes the whole compositor
  # config with it, but a fresh clone now already contains real content.
  # (`dms setup` refuses to touch files that already have content, so a
  # fresh install inherits these instead of the stock templates.)
  xdg.configFile."hypr/dms".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/hypr/dms";

  # Empty placeholder for the one remaining file dms writes imperatively
  # OUTSIDE the symlinked dir: home/alacritty.nix imports a theme file dms
  # rewrites on every wallpaper change; an empty placeholder keeps alacritty
  # from starting against a dangling import before the shell's first run.
  # (`[ -e ]` means a file that exists — even empty — is never touched
  # again.)
  home.activation.dmsPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/alacritty
    [ -e ~/.config/alacritty/dank-theme.toml ] || touch ~/.config/alacritty/dank-theme.toml
  '';
}
