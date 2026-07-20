# dms.nix — DankMaterialShell, the USER half (system half: modules/dms.nix;
# greeter: modules/dms-greeter.nix). This IS the desktop: bar, launcher
# (Spotlight), notifications, lock screen, idle policy, OSD, clipboard
# history, polkit agent, power menu, wallpaper, night mode — one quickshell
# process. It replaced waybar/fuzzel/swaync/gtklock/swayidle/
# plasma-polkit-agent/power.nix in 2026-07.
#
# Interaction happens through `dms ipc call …` — that's what the DMS
# keybinds in ~/.config/hypr/dms/binds.lua (DMS-managed, deployed by
# `dms setup`, required by home/hypr/hyprland.lua) run. Configuration
# happens in the DMS
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
    # matching how waybar/swaync ran before, and the same rule hyprland.lua
    # documents at its startup hook: services outlive compositor config
    # reloads and restart on failure. NEVER also spawn "dms run" from
    # hyprland.lua — upstream warns the shell must not run twice.
    systemd.enable = true;
    # Scope to the hyprland session (home/hyprland.nix's
    # hyprland-session.target), not any graphical session — same reasoning
    # as swayidle before it: the shell is this session's policy, a future
    # second session brings its own.
    systemd.target = "hyprland-session.target";

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

  # First-boot bootstrap for files dms writes IMPERATIVELY. None of these
  # may ever become xdg.configFile entries — a read-only store symlink
  # would block dms from writing the real content.
  #  * alacritty: home/alacritty.nix imports a theme file dms rewrites on
  #    every wallpaper change; an empty placeholder keeps alacritty from
  #    starting against a dangling import before the shell's first run.
  #  * hypr/dms/*.lua: the seven DMS-owned fragments hyprland.lua
  #    require()s (colors from matugen; outputs/cursor/binds-user/
  #    windowrules from the Settings GUI; binds/layout from `dms setup`).
  #    Unlike niri's `include optional=true`, Lua's require() HARD-FAILS on
  #    a missing file and takes the whole compositor config with it — an
  #    empty Lua chunk loads fine.
  #
  # For the six fragments `dms setup` knows how to deploy, don't stop at an
  # empty placeholder: run the setup itself, so a FRESH INSTALL boots with
  # DMS's real defaults (keybinds above all — without binds.lua there is no
  # way to even open a terminal) instead of requiring a manual first-login
  # `dms setup`. This stays on the right side of "DMS owns these files":
  # the content comes from the dms binary, never from Nix, and the
  # missing-or-EMPTY guard ([ -s ]) means a file the GUI/matugen has since
  # written is never touched again — the seed runs exactly once per file.
  # binds-user.lua has no setup subcommand (it exists only for GUI-made
  # overrides), so it keeps the plain empty placeholder.
  #
  # Two env quirks, both load-bearing:
  #  * alacritty must be on PATH: dms detects the terminal for the
  #    SUPER+T bind by scanning PATH and otherwise falls back to a
  #    hardcoded `ghostty` — not installed here, i.e. a dead keybind.
  #  * DMS_PRIVESC=sudo skips the CLI's interactive "which privilege
  #    escalation tool" prompt (it only records the name, nothing runs
  #    elevated); </dev/null backstops any other prompt.
  # `|| …` + the touch fallback keep a failed setup from ever leaving a
  # missing file behind (see the require() hard-fail above).
  home.activation.dmsPlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/alacritty
    [ -e ~/.config/alacritty/dank-theme.toml ] || touch ~/.config/alacritty/dank-theme.toml
    mkdir -p ~/.config/hypr/dms
    [ -e ~/.config/hypr/dms/binds-user.lua ] || touch ~/.config/hypr/dms/binds-user.lua
    for f in binds colors cursor layout outputs windowrules; do
      if [ ! -s ~/.config/hypr/dms/$f.lua ]; then
        run env PATH="${lib.makeBinPath [ config.programs.alacritty.package ]}:$PATH" DMS_PRIVESC=sudo \
          ${lib.getExe config.programs.dank-material-shell.package} setup $f < /dev/null \
          || verboseEcho "dms setup $f failed — leaving empty placeholder"
        [ -e ~/.config/hypr/dms/$f.lua ] || touch ~/.config/hypr/dms/$f.lua
      fi
    done
  '';
}
