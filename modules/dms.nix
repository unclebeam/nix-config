# dms.nix — DankMaterialShell, THE shell module (user-side glue lives in
# home/dms.nix; the login greeter is its own intent in modules/dms-greeter.nix).
# DMS is back (2026-08, second era): it replaced Noctalia v5, which had
# replaced the first DMS era 2026-07, which had itself replaced the whole
# hand-rolled component stack (waybar, fuzzel, swaync, gtklock, swayidle,
# plasma-polkit-agent, power.nix). Same coverage, one shell: bar, launcher,
# notifications, lock screen, idle policy, OSD, clipboard history, polkit
# agent, power menu, wallpaper, screenshots. This time it runs on niri —
# DMS's original home-turf compositor.
#
# DMS is a Go daemon (`dms run`) that spawns quickshell (QML) as a child;
# interaction from keybinds/scripts is `dms ipc call <target> <fn>` (see
# home/niri/config.kdl's binds; `dms ipc list` enumerates everything).
# Upstream's docs offer a NixOS module OR home-manager modules and say to
# pick ONE — this is the one; home/ imports NO DMS module at all (the
# first DMS era briefly ran both, which installed every DMS package twice
# and left a standing risk of two dms.service definitions — upstream warns
# the shell must never run twice; single-module is the structural
# guarantee, carried through the noctalia era and back). The flake's
# homeModules.niri is doubly forbidden: its "includes hack" force-takes-over
# ~/.config/niri/config.kdl, which is our out-of-store symlink.
{ config, lib, pkgs, ... }:

{
  # DMS's NixOS module (wired into mkHost from the dank-material-shell
  # flake input). What enabling this provides:
  #   - environment.systemPackages: quickshell + the dms binary + the
  #     optional-feature deps (dgop for the process list, matugen for
  #     wallpaper-derived Material You theming, cava, and friends — the
  #     enable* toggles default true and stay that way).
  #   - Service defaults (all mkDefault true), and what each replaces:
  #     * services.power-profiles-daemon: DMS's battery widget drives it.
  #       (The noctalia era set this explicitly; now it's back to the
  #       module's default. Harmless on the PC — it just exposes
  #       "balanced" — load-bearing on the thinkpad.)
  #     * services.accounts-daemon: avatar/real-name source for greeter
  #       and lock screen.
  #     * services.geoclue2: location for night-mode sunset times and the
  #       weather widget.
  #     * security.polkit: the policy engine (programs.niri also sets it);
  #       the AGENT (the prompt UI) is built into the DMS shell itself —
  #       always on, no config needed (unlike noctalia's opt-in
  #       polkit_agent toggle). No other polkit agent may ever join the
  #       session bus.
  #
  # No binary cache exists for DMS (unlike noctalia.cachix.org) — which is
  # exactly why the flake input DOES set `inputs.nixpkgs.follows` (see
  # flake.nix): quickshell comes prebuilt from cache.nixos.org against our
  # nixpkgs, and only the small Go daemon compiles from source, once per
  # input bump. If a rebuild ever compiles quickshell itself, the follows
  # wiring regressed.
  programs.dank-material-shell = {
    enable = true;

    # The ONE dms.service — a system-defined user unit (lands in
    # /etc/systemd/user): `dms run`, Restart=on-failure, restarted on
    # every switch. NEVER also spawn `dms run` from config.kdl — same
    # never-run-twice rule as noctalia.service before it.
    systemd.enable = true;
    # Scope to the niri session (home/niri.nix's niri-session.target), not
    # the module's graphical-session.target default — same reasoning as
    # every shell before it: the shell is this session's policy, a future
    # second session brings its own.
    systemd.target = "niri-session.target";
  };

  # UPower — the D-Bus battery/AC state source. The DMS module enables
  # power-profiles-daemon etc. but NOT upower, and DMS's battery widget is
  # hard-wired to it (BatteryService: `isPluggedIn: !UPower.onBattery`) —
  # without the daemon the bar reports "Plugged In" forever, even on
  # battery. Both hosts get it: on the PC it's what surfaces Bluetooth
  # mouse/keyboard battery levels in the same widget.
  services.upower.enable = true;

  # The shell's UI fonts. The DMS module does NOT install them: Inter for
  # UI text, Fira Code for mono, Material Symbols for every icon in the
  # bar/menus — without it the shell renders tofu boxes everywhere (the
  # noctalia era dropped fira-code/material-symbols; both are load-bearing
  # again). Inter is ALSO hard-required by home/qt.nix (the qt6ct seed
  # pins it as the Qt UI font) — if DMS ever leaves again, Inter stays.
  fonts.packages = with pkgs; [
    inter
    fira-code
    material-symbols
  ];

  # DMS's evdev manager reads /dev/input directly (keybind recorder in the
  # Settings GUI etc.); NixOS udev tags those nodes for the `input` group,
  # so without membership the shell logs "Failed to initialize evdev
  # manager: insufficient permissions" on every start and those features
  # are dead. extraGroups lists merge across modules (same pattern as
  # docker.nix), so this belongs here — the group exists because of DMS.
  users.users.unclebeam.extraGroups = [ "input" ];

  # PAM note: the DMS lock screen does NOT get a hand-rolled PAM service.
  # Its password path authenticates against /etc/pam.d/login (upstream's
  # documented NixOS behavior — same as noctalia before it), which is why
  # modules/fprintd.nix keeps `login` password-only; the fingerprint path
  # talks to fprintd directly, outside PAM. Never declare a
  # security.pam.services entry for the shell.
}
