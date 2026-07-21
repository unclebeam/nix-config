# dms-greeter.nix — the login greeter: DMS's own greeter UI running on
# greetd (replaced SDDM + SilentSDDM 2026-07 so the login screen matches
# the DMS lock screen/desktop). greetd is a minimal display-manager daemon;
# the DMS greeter module points its default session at a script that boots
# a nested hyprland kiosk on VT1 and draws the greeter (quickshell) inside
# it.
#
# Sessions: greetd's session, once authenticated, execs the chosen session
# from the same wayland-sessions dir SDDM scanned. The menu shows exactly
# ONE entry — plain "Hyprland" — because modules/hyprland.nix force-filters
# services.displayManager.sessionPackages: the package's second entry,
# "Hyprland (uwsm-managed)", had no uwsm units behind it (withUWSM is off)
# and provably bounced first-attempt logins back to this greeter
# (journal 2026-07-20: uwsm → systemctl exit status 5 → session closed).
#
# PAM: greetd authenticates via security.pam.services.greetd — a service
# generated WITH default rules, so per-service toggles on it actually work
# (unlike sddm, whose stack was a bare `substack login` where every toggle
# was a silent no-op — see the hard-won rule in CLAUDE.md). Two files hook
# into it: modules/kwallet.nix (pam_kwallet auto-unlock — the reason the
# greeter must stay password-only) and modules/fprintd.nix (the fprintAuth
# opt-out enforcing exactly that).
{ config, lib, pkgs, ... }:

{
  programs.dank-material-shell.greeter = {
    enable = true; # sets services.greetd.enable under the hood
    # (package: deliberately unset — it defaults to the shell's package
    # because modules/dms.nix enables programs.dank-material-shell, so
    # greeter and desktop always render from the same DMS build.)
    # Which compositor the greeter kiosk runs in. Reuses
    # programs.hyprland's package, so greeter and session render with the
    # same hyprland build.
    compositor.name = "hyprland";
    # Copy this user's DMS settings/session/wallpaper into the greeter's
    # state dir (/var/lib/dms-greeter) at greetd start — the login screen
    # picks up the same wallpaper and matugen colors as the desktop.
    configHome = "/home/unclebeam";
  };
}
