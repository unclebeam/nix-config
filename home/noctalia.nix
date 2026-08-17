# noctalia.nix — Noctalia, the USER-side glue. The shell itself is enabled
# by the flake's NixOS module in modules/noctalia.nix (the flake also ships
# a home-manager module; single-module rule — this file imports NO noctalia
# module, it only wires the config dir and placeholders that genuinely
# belong to the user's home). The greeter is modules/noctalia-greeter.nix.
#
# The shell IS the desktop: bar, launcher, notifications, lock screen, idle
# policy, OSD, clipboard history, polkit agent, power menu, wallpaper,
# screenshots — one native process, run by the system-defined
# noctalia.service user unit. It replaced DMS in 2026-07 (which had
# replaced waybar/fuzzel/swaync/gtklock/swayidle/plasma-polkit-agent).
#
# CONFIG LAYERING (the reason this setup is nicer than DMS's): noctalia
# reads, in order of increasing priority,
#   1. built-in defaults
#   2. ~/.config/noctalia/config.toml — OUR tracked file (symlinked below),
#      hot-reloaded via inotify on every edit, no rebuild, no reload cmd
#   3. ~/.local/state/noctalia/settings.toml — written by the Settings GUI
#      (SUPER+comma), loads last so GUI tweaks win
# So the repo TOML is the curated baseline (the must-haves that make a
# fresh install work: polkit agent, satty screenshot pipe, idle policy,
# theme templates) and the GUI stays fully usable for everything else —
# unlike DMS, where a managed settings.json would have bricked the GUI.
# GUI overrides are machine-local by design; promote one into config.toml
# when it should apply to both machines.
#
# Interaction happens through `noctalia msg <command>` — that's what the
# keybinds in home/niri/config.kdl run (`noctalia msg --help` lists all).
#
# FRESH INSTALL: no setup command, nothing to run. The tracked config +
# binds boot straight to a working desktop; the only shell-side first-login
# step is picking a wallpaper (SUPER+Y) so the Material-You palette and the
# app templates have a source image.
{ config, lib, pkgs, ... }:

{
  # The GTK3/4 theme the gtk template's apply.sh selects (it runs
  # `gsettings set gtk-theme adw-gtk3(-dark)` after writing noctalia.css):
  # adw-gtk3 is the theme built to be recolored that way. Without it the
  # apply script skips the theme switch and only sets the color-scheme.
  home.packages = [ pkgs.adw-gtk3 ];

  # The whole config dir, OUT-OF-STORE symlinked into the repo (same rule
  # and same hardcoded ~/nix-config base path as niri/config.kdl and
  # home/neovim.nix): config.toml edits hot-reload with no rebuild, and the
  # dir stays writable in case noctalia ever needs to write here (its own
  # writes go to ~/.local/state and ~/.cache, so in practice this is ours).
  xdg.configFile."noctalia".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/noctalia";

  # Empty placeholder for the one template output whose consumer can't
  # tolerate a missing file: alacritty/themes/noctalia.toml is imported by
  # home/alacritty.nix, and alacritty errors out on a dangling import — an
  # empty TOML is valid, so it starts unthemed instead of failing before
  # the shell's first wallpaper. ([ -e ] = a file that exists — even
  # empty — is never touched again; the template writes the real thing.)
  # The niri template needs NO placeholder: home/niri/config.kdl pulls
  # ~/.config/niri/noctalia.kdl in with `include optional=true`, which
  # tolerates absence natively — that's the placeholder pattern's job done
  # in the consumer instead (the hyprland-era hypr/noctalia.lua seed died
  # with the compositor).
  home.activation.noctaliaPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/alacritty/themes
    [ -e ~/.config/alacritty/themes/noctalia.toml ] || touch ~/.config/alacritty/themes/noctalia.toml
  '';
}
