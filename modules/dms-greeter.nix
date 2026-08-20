# dms-greeter.nix — DMS's greeter UI on greetd: the greeter script boots a
# nested niri kiosk on VT1 and draws quickshell inside it; once authenticated,
# greetd execs the chosen session from wayland-sessions (currently exactly one
# entry — audit that dir whenever a compositor package changes; every entry
# the menu lists must actually boot).
#
# PAM: greetd's service is generated WITH default rules, so per-service
# toggles on it work. Two files hook into it: modules/gnome-keyring.nix
# (pam_gnome_keyring auto-unlock — the reason the greeter must stay
# password-only) and modules/fprintd.nix (the fprintAuth opt-out enforcing
# that). The module also declares its own empty `dms-greeter` PAM service —
# that's the greeter UI's, not the login path; leave it alone. If the keyring
# fails to unlock after login, check /etc/pam.d/greetd carries
# pam_gnome_keyring in auth AND session before debugging anywhere else.
#
# Upstream 1.6 moves the greeter to a separate dank-greeter repo — that bump
# needs a new input + option namespace (see flake.nix).
{ config, lib, pkgs, ... }:

{
  programs.dank-material-shell.greeter = {
    enable = true; # sets services.greetd.enable under the hood
    # package deliberately unset — defaults to the shell's package, so greeter
    # and desktop always render from the same DMS build.
    # Reuses programs.niri's package, same-build for the kiosk too.
    compositor.name = "niri";
    # Copies this user's DMS settings/wallpaper into /var/lib/dms-greeter at
    # greetd start — login screen matches the desktop's wallpaper/colors.
    configHome = "/home/unclebeam";
  };
}
