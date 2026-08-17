# noctalia-greeter.nix — the login greeter: Noctalia's greeter UI running
# on greetd (took over from the DMS greeter 2026-07, which had replaced
# SDDM + SilentSDDM — the login screen matches the shell's lock screen).
# greetd is a minimal display-manager daemon; the upstream module enables
# it (plus accounts-daemon for avatars/real names) and points its default
# session at the noctalia-greeter binary.
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
# into it and carry over from the DMS era unchanged:
# modules/kwallet.nix (pam_kwallet auto-unlock — the reason the greeter
# must stay password-only) and modules/fprintd.nix (the fprintAuth opt-out
# enforcing exactly that). If the wallet ever fails to unlock after login
# with this greeter, the escape hatch to try first is
# security.pam.services.greetd.kwallet.forceRun = true.
{ config, lib, pkgs, ... }:

{
  programs.noctalia-greeter = {
    enable = true; # enables services.greetd + accounts-daemon under the hood
    # `settings` deliberately unset for now — it renders
    # /var/lib/noctalia-greeter/greeter.toml ([output] scale, [keyboard]
    # layout, [cursor]…). The defaults are fine; per-host tweaks can be
    # added later and apply on the next switch. Desktop→greeter sync of
    # wallpaper/colors lives in the shell's Settings → Security GUI.
  };
}
