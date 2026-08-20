# dms.nix — DMS user-side glue. The shell itself is enabled by the NixOS
# module in modules/dms.nix; this file imports NO DMS module (single-module
# rule) and only holds what genuinely belongs to the user's home.
#
# Config is GUI-owned by upstream design: everything the Settings GUI
# (SUPER+Shift+comma) touches lands in ~/.config/DankMaterialShell/
# settings.json — never manage it from Nix. ~/.config/niri/dms/ is DMS's
# machine-local fragment dir, generated/GUI-owned, deliberately untracked
# (colors.kdl from the wallpaper; outputs.kdl/layout.kdl/windowrules.kdl
# from Settings; binds.kdl unused — our keybinds live in the tracked
# config.kdl). config.kdl pulls the fragments in via trailing includes,
# every one `optional=true` — load-bearing: a missing non-optional include
# fails the whole config, and on a fresh install that's a deadlock (built-in
# defaults → no spawn-at-startup → dms.service never starts → fragments
# never written). Never wire a new fragment in without optional=true.
#
# Fresh install: no `dms setup`. First login: pick a wallpaper (SUPER+Y) so
# matugen writes colors.kdl + app themes, then the Settings pass (idle
# timeouts, Apply GTK/Qt Themes, Displays). Careful with Displays' "fix
# include" button: it writes THROUGH the config.kdl symlink into the tracked
# repo file — an unexplained include in `git diff` means DMS thought ours
# didn't match; check the exact spelling before reverting. If colors.kdl
# never appears, `dms setup colors` is safe (only writes missing/empty
# files); re-set the wallpaper after.
{ config, lib, pkgs, ... }:

{
  # The GTK3/4 theme built to be recolored by DMS's "Apply GTK Themes"
  # toggle; without it the toggle can only set the color-scheme.
  home.packages = [ pkgs.adw-gtk3 ];

  # Idempotent seeds ([ -e ] = an existing file, even empty, is never
  # touched): the matugen target dir, and alacritty's dank-theme.toml — the
  # one template output whose consumer errors on a dangling import; an empty
  # TOML is valid, so the terminal starts unthemed instead of failing before
  # the first wallpaper. Must never be xdg.configFile — DMS writes the real
  # file imperatively and a store symlink would block it with EROFS.
  home.activation.dmsPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/niri/dms
    mkdir -p ~/.config/alacritty
    [ -e ~/.config/alacritty/dank-theme.toml ] || touch ~/.config/alacritty/dank-theme.toml
  '';
}
