# dms.nix — DMS, the USER-side glue. The shell itself is enabled by the
# flake's NixOS module in modules/dms.nix (the flake also ships home-manager
# modules; single-module rule — this file imports NO DMS module, it only
# holds the few pieces that genuinely belong to the user's home). The
# greeter is modules/dms-greeter.nix.
#
# The shell IS the desktop: bar, launcher, notifications, lock screen, idle
# policy, OSD, clipboard history, polkit agent, power menu, wallpaper,
# screenshots — one shell, run by the system-defined dms.service user unit.
# It replaced Noctalia in 2026-08 (second DMS era; the first ran 2026-07 on
# hyprland).
#
# CONFIG: GUI-owned, by upstream design. DMS persists everything the
# Settings GUI (SUPER+Shift+comma) touches in
# ~/.config/DankMaterialShell/settings.json — there is no tracked-baseline
# layer like noctalia's config.toml (the home module's `settings` option
# exists but would make the GUI fight Nix; the first DMS era already
# rejected it). Accepted regression, listed in CLAUDE.md: idle/lock
# timeouts and the GTK/Qt theme toggles are per-machine FIRST-LOGIN GUI
# steps (idle defaults to 0 = never locks!), not repo state.
#
# ~/.config/niri/dms/ is DMS's fragment dir on niri — machine-local,
# DO-NOT-EDIT, generated territory (matugen rewrites colors.kdl on every
# wallpaper change), deliberately NOT tracked or symlinked. This is the
# opposite of both prior eras on purpose: the hyprland-DMS era tracked its
# Lua fragments (they carried keybinds), and noctalia's config dir was our
# tracked TOML — but here every fragment we'd track is either generated
# (colors) or unused (binds/layout/etc. — our keybinds live in the tracked
# home/niri/config.kdl, stock-niri philosophy). The ONE consumed fragment,
# colors.kdl, is pulled in by config.kdl's trailing `include optional=true`,
# which tolerates absence natively.
#
# Interaction happens through `dms ipc call <target> <fn>` — that's what
# the keybinds in home/niri/config.kdl run (`dms ipc list` shows all).
#
# FRESH INSTALL: no `dms setup` needed (the hyprland-era ritual is dead —
# it existed to write compositor config we now keep in git). First-login
# steps: pick a wallpaper (SUPER+Y) so matugen writes colors.kdl + the app
# themes, then the Settings GUI pass (idle timeouts, Apply GTK/Qt Themes).
# If colors.kdl never appears after a wallpaper pick, the safe fallback is
# a one-time `dms setup colors` (it only writes files that are missing or
# empty) and re-setting the wallpaper.
{ config, lib, pkgs, ... }:

{
  # The GTK3/4 theme DMS's "Apply GTK Themes" toggle recolors (via its
  # matugen gtk templates + gsettings): adw-gtk3 is the theme built to be
  # recolored that way. Without it the toggle can only set the
  # color-scheme, not the widget theme.
  home.packages = [ pkgs.adw-gtk3 ];

  # Two seeds, both idempotent ([ -e ] = a file that exists — even empty —
  # is never touched again):
  #   - ~/.config/niri/dms: matugen's colors.kdl target dir. DMS creates
  #     it itself in practice; the mkdir is cheap insurance so the very
  #     first wallpaper write can never fail on a missing dir.
  #   - alacritty's dank-theme.toml: the one template output whose
  #     consumer can't tolerate a missing file — home/alacritty.nix
  #     imports it, and alacritty errors out on a dangling import. An
  #     empty TOML is valid, so the terminal starts unthemed instead of
  #     failing before the first wallpaper. (Must never be xdg.configFile —
  #     DMS writes the real file imperatively, and a store symlink would
  #     block the write with EROFS.)
  home.activation.dmsPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/niri/dms
    mkdir -p ~/.config/alacritty
    [ -e ~/.config/alacritty/dank-theme.toml ] || touch ~/.config/alacritty/dank-theme.toml
  '';
}
