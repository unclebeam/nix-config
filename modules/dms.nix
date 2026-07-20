# dms.nix — DankMaterialShell, THE shell module (the quickshell-based
# desktop shell; theming glue + config placeholders live in home/dms.nix;
# the login greeter is its own intent in modules/dms-greeter.nix). DMS
# replaced the whole hand-rolled component stack in 2026-07: waybar (bar),
# fuzzel (launcher), swaync (notifications), gtklock (lock screen),
# swayidle (idle policy), plasma-polkit-agent (auth prompts) and power.nix
# (power menu) — plus things we never had: OSD, wallpaper, clipboard
# history, night mode.
{ config, lib, pkgs, ... }:

{
  # DMS's NixOS module (wired into mkHost from the dank-material-shell
  # flake input). Upstream's docs offer a NixOS module OR a home-manager
  # module and say to pick ONE — this is the one; home/ imports no DMS
  # module at all (the repo briefly ran both, which installed every DMS
  # package twice and left a standing risk of two dms.service definitions —
  # upstream warns the shell must never run twice; single-module is now the
  # structural guarantee). What enabling this provides:
  #   - environment.systemPackages: quickshell + the dms binary + the
  #     optional-feature deps (dgop for the Mod+M process list, matugen for
  #     wallpaper-derived Material You theming, cava for audio wavelength,
  #     khal for calendar events, glib/networkmanager for the VPN widget) —
  #     all the enable* toggles default true and stay that way.
  #   - Service defaults (all mkDefault true), and what each replaces:
  #     * services.power-profiles-daemon: DMS's battery widget drives it.
  #       Used to be laptop.nix's (thinkpad-only); now both hosts have it,
  #       which is harmless on the PC (it just exposes "balanced").
  #     * services.accounts-daemon: avatar/real-name source for greeter
  #       and lock screen. Used to be modules/gtklock.nix's.
  #     * services.geoclue2: location for night-mode sunset times and the
  #       weather widget.
  #     * security.polkit: the policy engine. Used to be polkit-agent.nix's;
  #       the AGENT (the prompt UI) is built into the DMS shell itself,
  #       replacing plasma-polkit-agent.
  programs.dank-material-shell = {
    enable = true;

    # The ONE dms.service — a system-defined user unit (lands in
    # /etc/systemd/user/dms.service; it used to be home-manager's
    # ~/.config/systemd/user copy): `dms run --session`, Restart=on-failure,
    # and restartIfChanged (default true) restarts the shell on every
    # switch. NEVER also spawn "dms run" from hyprland.lua.
    systemd.enable = true;
    # Scope to the hyprland session (home/hyprland.nix's
    # hyprland-session.target), not the module's graphical-session.target
    # default — same reasoning as swayidle before it: the shell is this
    # session's policy, a future second session brings its own.
    systemd.target = "hyprland-session.target";
  };

  # UPower — the D-Bus battery/AC state source. The DMS module enables
  # power-profiles-daemon etc. but NOT upower, and DMS's battery widget is
  # hard-wired to it (BatteryService: `isPluggedIn: !UPower.onBattery`) —
  # without the daemon the bar reports "Plugged In" forever, even on
  # battery. Both hosts get it (same reasoning as power-profiles-daemon
  # above): on the PC it's what surfaces Bluetooth mouse/keyboard battery
  # levels in the same widget.
  services.upower.enable = true;

  # The shell's UI fonts. The DMS module does NOT install them (only the
  # greeter module does, and that's a separate intent that must stay
  # removable on its own): Inter for UI text, Fira Code for mono,
  # Material Symbols for every icon in the bar/menus — without it the shell
  # renders tofu boxes everywhere.
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
  # documented NixOS behavior) and its fingerprint path talks to fprintd
  # directly via DMS-owned PAM fragments. Declaring
  # security.pam.services.dankshell would override that — don't.
}
