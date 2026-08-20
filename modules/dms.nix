# dms.nix — DankMaterialShell, THE shell module: bar, launcher, notifications,
# lock screen, idle policy, OSD, clipboard history, polkit agent, power menu,
# wallpaper, screenshots. User-side glue in home/dms.nix; greeter in
# modules/dms-greeter.nix. DMS is a Go daemon (`dms run`) that spawns
# quickshell; keybinds talk to it via `dms ipc call` (home/niri/config.kdl).
#
# Upstream says pick NixOS module OR home-manager modules — this is the one;
# home/ imports NO DMS module (two modules = every package twice + risk of two
# dms.service definitions, and the shell must never run twice). The flake's
# homeModules.niri is doubly forbidden: it force-takes-over
# ~/.config/niri/config.kdl, our out-of-store symlink.
{ config, lib, pkgs, ... }:

{
  # Enabling installs quickshell + dms + optional-feature deps (dgop, matugen,
  # cava…) and mkDefault-enables power-profiles-daemon (battery widget drives
  # it), accounts-daemon (greeter/lock avatar), geoclue2 (night mode, weather),
  # and polkit — the polkit AGENT is built into the shell, always on; no other
  # agent may ever join the session bus.
  # If a rebuild ever compiles quickshell from source, the follows wiring in
  # flake.nix regressed.
  programs.dank-material-shell = {
    enable = true;

    # The ONE dms.service (a system-defined user unit). NEVER also spawn
    # `dms run` from config.kdl — the shell must not run twice.
    systemd.enable = true;
    # Scoped to the niri session, not graphical-session.target: the shell is
    # this session's policy, a future second session brings its own.
    systemd.target = "niri-session.target";
  };

  # The DMS module does NOT enable upower, but the battery widget is
  # hard-wired to it — without the daemon the bar reports "Plugged In"
  # forever. On the PC it also surfaces BT mouse/keyboard battery levels.
  services.upower.enable = true;

  # The module does not install the shell's fonts; without Material Symbols
  # every icon renders as tofu. Inter is ALSO pinned as the Qt UI font by
  # home/qt.nix — if DMS ever leaves, Inter stays.
  fonts.packages = with pkgs; [
    inter
    fira-code
    material-symbols
  ];

  # DMS's evdev manager reads /dev/input directly (Settings' keybind recorder
  # etc.); udev tags those nodes for `input`, so without membership those
  # features are dead ("Failed to initialize evdev manager"). extraGroups
  # merge across modules — this line belongs to DMS.
  users.users.unclebeam.extraGroups = [ "input" ];

  # PAM: the DMS lock screen authenticates against /etc/pam.d/login (upstream
  # behavior) — that's why modules/fprintd.nix keeps `login` password-only;
  # its fingerprint path talks to fprintd directly, outside PAM. Never declare
  # a security.pam.services entry for the shell.
}
