# dms-greeter.nix — the login greeter: DMS's own greeter UI running on
# greetd (took over from the Noctalia greeter 2026-08; the lineage is
# SDDM+SilentSDDM → DMS greeter → Noctalia greeter → DMS greeter again —
# the login screen always matches the shell's lock screen). greetd is a
# minimal display-manager daemon; the DMS greeter module points its
# default session at a script that boots a nested niri kiosk on VT1 and
# draws the greeter (quickshell) inside it.
#
# Sessions: greetd's session, once authenticated, execs the chosen session
# from the wayland-sessions dir. The menu shows exactly ONE entry — "Niri"
# — naturally: the niri package ships exactly one session file, so the
# force-filter the hyprland era needed (its package unconditionally
# shipped a second, uwsm-managed entry with no units behind it, which
# provably bounced logins — journal 2026-07-20) has nothing to filter and
# is gone. The lesson survives in modules/niri.nix and CLAUDE.md: audit
# the session files any future compositor package ships — every entry
# this menu lists must actually boot.
#
# PAM: greetd authenticates via security.pam.services.greetd — a service
# generated WITH default rules, so per-service toggles on it actually work
# (unlike sddm, whose stack was a bare `substack login` where every toggle
# was a silent no-op — see the hard-won rule in CLAUDE.md). Two files hook
# into it and have carried across every greeter era unchanged:
# modules/kwallet.nix (pam_kwallet auto-unlock — the reason the greeter
# must stay password-only) and modules/fprintd.nix (the fprintAuth opt-out
# enforcing exactly that). The module also declares its own empty
# `dms-greeter` PAM service — that one is the greeter UI's, not the login
# path; leave it alone. If the wallet ever fails to unlock after login,
# the escape hatch to try first is
# security.pam.services.greetd.kwallet.forceRun = true.
#
# Upstream note: on DMS master the greeter has moved out to a separate
# `dank-greeter` repo and this flake output became a warning stub — fine
# on the pinned `/stable` (1.5.x), but the first `nix flake update` that
# lands 1.6 needs a new input + option namespace here (see flake.nix).
{ config, lib, pkgs, ... }:

{
  programs.dank-material-shell.greeter = {
    enable = true; # sets services.greetd.enable under the hood
    # (package: deliberately unset — it defaults to the shell's package
    # because modules/dms.nix enables programs.dank-material-shell, so
    # greeter and desktop always render from the same DMS build.)
    # Which compositor the greeter kiosk runs in. Reuses programs.niri's
    # package (modules/niri.nix enables it), so greeter and session render
    # with the same niri build.
    compositor.name = "niri";
    # Copy this user's DMS settings/session/wallpaper into the greeter's
    # state dir (/var/lib/dms-greeter) at greetd start — the login screen
    # picks up the same wallpaper and matugen colors as the desktop.
    configHome = "/home/unclebeam";
  };
}
