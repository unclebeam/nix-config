# noctalia.nix — Noctalia v5, THE shell module (config + templates live in
# home/noctalia.nix + home/noctalia/; the login greeter is its own intent in
# modules/noctalia-greeter.nix). Noctalia replaced DMS 2026-07, which had
# itself replaced the hand-rolled component stack (waybar, fuzzel, swaync,
# gtklock, swayidle, plasma-polkit-agent, power.nix). Same coverage, one
# process: bar, launcher, notifications, lock screen, idle policy, OSD,
# clipboard history, polkit agent, power menu, wallpaper, screenshots.
#
# v5 is a native C++ Wayland shell — NOT the old v4 Quickshell app that
# nixpkgs ships as `noctalia-shell`; never use that package. The flake also
# offers a home-manager module — we deliberately use the NixOS module ONLY
# (single-module rule carried over from DMS: two modules meant everything
# installed twice and a standing risk of two shell services on one bus).
{ config, lib, pkgs, ... }:

{
  # Noctalia's NixOS module (wired into mkHost from the noctalia flake
  # input). Enabling it installs the `noctalia` binary into
  # environment.systemPackages; interaction from keybinds/scripts is
  # `noctalia msg <command>` (see home/niri/config.kdl's binds). v5 has a
  # first-class niri backend — workspaces/windows/keyboard-layout over the
  # NIRI_SOCKET IPC, plus niri-only extras (overview backdrop,
  # type-to-launch) the hyprland era never had.
  programs.noctalia = {
    enable = true;

    # The ONE noctalia.service — a system-defined user unit,
    # Restart=on-failure (the safety net while v5 is Beta), restarted on
    # every switch. NEVER also spawn `noctalia` from config.kdl — same
    # never-run-twice rule as dms.service before it.
    systemd.enable = true;
    # Scope to the niri session (home/niri.nix's niri-session.target), not
    # the module's graphical-session.target default — same reasoning as
    # swayidle → dms before it: the shell is this session's policy, a
    # future second session brings its own.
    systemd.target = "niri-session.target";
  };

  # The binary cache for the flake input. Without it every bump of the
  # noctalia inputs compiles the whole C++ shell on both machines; with it
  # the build is a download — but ONLY because the inputs in flake.nix skip
  # `inputs.nixpkgs.follows` (the cache holds upstream's-nixpkgs builds;
  # following ours would change the hash and quietly fall back to source).
  # If a rebuild ever visibly COMPILES noctalia, this wiring regressed.
  # Note: substituter settings apply to builds that start AFTER they land
  # in /etc/nix/nix.conf, so the very first switch adding this block still
  # builds from source once.
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # UPower — the D-Bus battery/AC state source for the shell's battery
  # widget (an optional dependency upstream; the module does not force it).
  # Both hosts get it: on the PC it's what surfaces Bluetooth mouse/keyboard
  # battery levels in the same widget.
  services.upower.enable = true;

  # power-profiles-daemon — the shell's power-profile widget drives it
  # (powerprofilesctl still works too). Under DMS this came implicitly from
  # the upstream module's mkDefault; Noctalia's module only bundles it via
  # recommendedServices.enable, which we deliberately DON'T set — it would
  # also enable NetworkManager and Bluetooth, and those belong to
  # core.nix/bluetooth.nix (one file per intent). Harmless on the PC (it
  # just exposes "balanced"), load-bearing on the thinkpad.
  services.power-profiles-daemon.enable = true;

  # UI fonts. Noctalia renders via Fontconfig (its font_family defaults to
  # "sans-serif"), so nothing here is hard-required by the shell itself —
  # but Inter IS hard-required by home/qt.nix (the qt6ct seed pins it as
  # the Qt UI font). (fira-code was removed 2026-08: its comment claimed
  # it was "the mono font across the desktop", but nothing referenced it —
  # alacritty uses IosevkaTerm NF, Doom IosevkaTermNerdFont, qt.nix's
  # fixed font JetBrainsMono NF, all installed by modules/desktop.nix.)
  # material-symbols (DMS's icon font) left with DMS: v5 draws its own
  # icons. If any shell UI renders tofu boxes, that call was wrong —
  # re-add it here.
  fonts.packages = with pkgs; [
    inter
  ];

  # PAM note: the Noctalia lock screen does NOT get a hand-rolled PAM
  # service. Its password path authenticates against /etc/pam.d/login
  # (upstream's documented behavior — same as DMS before it), which is why
  # modules/fprintd.nix keeps `login` password-only. Never declare a
  # security.pam.services entry for the shell.
  #
  # Polkit note: security.polkit (the engine) comes from programs.niri;
  # the AGENT (the prompt UI) is built into the shell but OFF by default
  # upstream — home/noctalia/config.toml switches it on (polkit_agent).
  # No other polkit agent may ever join the session bus.
  #
  # Group note: DMS needed `input` group membership for its evdev keybind
  # recorder; Noctalia manages no compositor keybinds and needs no /dev/input
  # access. If the journal ever shows noctalia input-permission errors,
  # re-add `users.users.unclebeam.extraGroups = [ "input" ];` here.
}
