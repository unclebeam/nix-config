# dms.nix — the SYSTEM half of DankMaterialShell (the quickshell-based
# desktop shell; the USER half — the shell itself, its systemd service and
# theming glue — is home/dms.nix; the login greeter is its own intent in
# modules/dms-greeter.nix). DMS replaced the whole hand-rolled component
# stack in 2026-07: waybar (bar), fuzzel (launcher), swaync (notifications),
# gtklock (lock screen), swayidle (idle policy), plasma-polkit-agent (auth
# prompts) and power.nix (power menu) — plus things we never had: OSD,
# wallpaper, clipboard history, night mode.
{ config, lib, pkgs, ... }:

{
  # DMS's NixOS module (wired into mkHost from the dank-material-shell
  # flake input). At the system level we only want its service defaults —
  # the shell itself runs from home/dms.nix's user service, so
  # `systemd.enable` stays OFF here (the module would otherwise start a
  # second copy of the shell; upstream warns never to run it twice).
  # What enabling this turns on (all mkDefault true), and what each replaces:
  #   - services.power-profiles-daemon: DMS's battery widget drives it.
  #     Used to be laptop.nix's (thinkpad-only); now both hosts have it,
  #     which is harmless on the PC (it just exposes "balanced").
  #   - services.accounts-daemon: avatar/real-name source for greeter and
  #     lock screen. Used to be modules/gtklock.nix's.
  #   - services.geoclue2: NEW — location for night-mode sunset times and
  #     the weather widget.
  #   - security.polkit: the policy engine. Used to be polkit-agent.nix's;
  #     the AGENT (the prompt UI) is now built into the DMS shell itself,
  #     replacing plasma-polkit-agent.
  programs.dank-material-shell.enable = true;

  # The shell's UI fonts. Neither the HM module nor this one installs them
  # (only the greeter module does, and that's a separate intent that must
  # stay removable on its own): Inter for UI text, Fira Code for mono,
  # Material Symbols for every icon in the bar/menus — without it the shell
  # renders tofu boxes everywhere.
  fonts.packages = with pkgs; [
    inter
    fira-code
    material-symbols
  ];

  # PAM note: the DMS lock screen does NOT get a hand-rolled PAM service.
  # Its password path authenticates against /etc/pam.d/login (upstream's
  # documented NixOS behavior) and its fingerprint path talks to fprintd
  # directly via DMS-owned PAM fragments. Declaring
  # security.pam.services.dankshell would override that — don't.
}
