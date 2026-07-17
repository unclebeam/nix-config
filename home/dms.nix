# dms.nix — DankMaterialShell, the USER half (system half: modules/dms.nix;
# greeter: modules/dms-greeter.nix). This IS the desktop: bar, launcher
# (Spotlight), notifications, lock screen, idle policy, OSD, clipboard
# history, polkit agent, power menu, wallpaper, night mode — one quickshell
# process. It replaced waybar/fuzzel/swaync/gtklock/swayidle/
# plasma-polkit-agent/power.nix in 2026-07.
#
# Interaction happens through `dms ipc call …` — that's what all the DMS
# keybinds in home/niri/config.kdl spawn. Configuration happens in the DMS
# Settings GUI (Mod+Comma): wallpaper, idle/lock timeouts (NB: idle lock
# starts UNSET — configure it on first login, swayidle is gone), the
# "Apply GTK/Qt Themes" toggles, widgets. Settings are deliberately NOT
# declared here via the module's `settings` option: managing settings.json
# from Nix makes the GUI read-only, and the GUI is the point.
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  # The DMS home-manager module comes from the flake input (reachable here
  # because flake.nix passes `inputs` through extraSpecialArgs — imports
  # can only be resolved from specialArgs).
  imports = [ inputs.dank-material-shell.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;

    # Run the shell as a systemd user service (`dms run --session`) —
    # matching how waybar/swaync ran before, and the same rule config.kdl
    # documents at its lone spawn-at-startup: services outlive compositor
    # config reloads and restart on failure. NEVER also spawn "dms" "run"
    # from config.kdl — upstream warns the shell must not run twice.
    systemd.enable = true;
    # Scope to the niri session (home/niri.nix's niri-session.target), not
    # any graphical session — same reasoning as swayidle before it: the
    # shell is this session's policy, a future second session brings its own.
    systemd.target = "niri-session.target";

    # The toggles that pull in optional dependencies all default to true
    # and stay that way: enableSystemMonitoring (dgop — the Mod+M process
    # list), enableDynamicTheming (matugen — wallpaper-derived Material You
    # colors, the replacement for the old home/colors.nix melange palette),
    # enableAudioWavelength (cava), enableVPN, enableCalendarEvents (khal).
    # Brightness/clipboard/night-mode/color-picker are built into the dms
    # binary itself — no brightnessctl or cliphist needed.
  };

  # The GTK3/4 theme that DMS's "Apply GTK Themes" toggle targets: DMS
  # generates matugen colors as gtk.css, and adw-gtk3 is the theme built to
  # be recolored that way. Without it the toggle has nothing to skin.
  home.packages = [ pkgs.adw-gtk3 ];

  # First-boot bootstrap: home/alacritty.nix imports a theme file that dms
  # writes IMPERATIVELY (and rewrites on every wallpaper change). Until the
  # shell has run once, it doesn't exist — touch an empty placeholder so
  # alacritty never starts against a dangling import. It must NOT be an
  # xdg.configFile entry — a read-only store symlink would block dms from
  # writing the real content. (niri's dms include needs no placeholder:
  # config.kdl uses `include optional=true` there.)
  home.activation.dmsPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/alacritty
    [ -e ~/.config/alacritty/dank-theme.toml ] || touch ~/.config/alacritty/dank-theme.toml
  '';
}
