# kwallet.nix — the session keyring, KDE edition (SYSTEM half; the USER half
# — kwalletrc — is home/kwallet.nix). Replaced gnome-keyring 2026-07 by
# explicit request: session plumbing followed the file manager to KDE
# (screencasting goes to hyprland's own portal — see modules/hyprland.nix).
# ksecretd
# (the Secret Service daemon split out of kwalletd in Plasma 6) becomes the
# owner of org.freedesktop.secrets — the store behind Dolphin's saved share
# passwords, browser Safe Storage keys, and the Secret portal.
#
# The whole login chain, since no single upstream doc spells it out:
#   1. pam_kwallet (below) derives a key from the password typed at login
#      and execs `ksecretd --pam-login`, handing the key over inherited fds.
#   2. ksecretd sits keyed but OFF the session bus — it has no environment
#      yet. It listens on a socket exported as $PAM_KWALLET5_LOGIN.
#   3. plasma-kwallet-pam.service (below) runs pam_kwallet_init at session
#      start: a 3-line `env | socat` that pipes the session environment into
#      that socket. Only then does ksecretd join the bus and claim
#      org.freedesktop.secrets (+ the org.kde.kwalletd6 compat name).
#   4. First password login auto-creates the wallet — named `kdewallet`,
#      encrypted with the login password, no wizard.
# Caveats that follow from the design: auto-unlock only works while the
# wallet is named `kdewallet` AND its password equals the login password. A
# later `passwd` does NOT re-encrypt the wallet — unlock silently breaks
# until the wallet password is changed to match (kwalletmanager can do it).
{ config, lib, pkgs, ... }:

{
  # Nothing enables gnome-keyring anymore (the old niri module did with
  # mkDefault; programs.hyprland doesn't), so this is a pure guard: if some
  # future module flips it back on, everything it wires — pam_gnome_keyring
  # on the `login` PAM service, its Secret portal backend, the D-Bus
  # activation, the CAP_IPC_LOCK wrapper — would fight ksecretd for
  # org.freedesktop.secrets. Two keyrings on one bus is breakage, not choice.
  services.gnome.gnome-keyring.enable = false;

  # kdePackages.kwallet ships kwallet.portal (an org.freedesktop.impl.portal.
  # Secret backend, needed by sandboxed/portal-only apps) plus the D-Bus
  # activation files for ksecretd and the kwalletd6 compat wrapper. Listing
  # it in extraPortals lets the xdg.portal module wire dbus.packages,
  # systemPackages (kwallet-query lands on PATH) and the portal dir in one
  # go — exactly how plasma6.nix installs it.
  xdg.portal.extraPortals = [ pkgs.kdePackages.kwallet ];

  # Unlike the old niri module (which hard-set Secret="gnome-keyring",
  # forcing a mkForce here), programs.hyprland writes no portal-config keys
  # at all — this is a fresh key, no force needed. The rest of the routing
  # lives in modules/hyprland.nix — the Secret route is here so removing
  # this file removes every trace of the KDE keyring.
  xdg.portal.config.hyprland."org.freedesktop.impl.portal.Secret" = "kwallet";

  # PAM half of step 1. On `greetd` (the DMS greeter's display manager,
  # modules/dms-greeter.nix). Unlike the old sddm service — which was
  # generated with useDefaultRules=false as a bare substack of `login`, so
  # per-service toggles on it were silent no-ops — greetd's PAM service is
  # generated WITH default rules, and greetd does NOT traverse `login`.
  # So the hook must sit on `greetd` itself; a hook on `login` would never
  # fire at graphical login anymore. (tty logins lose nothing: pam_kwallet
  # skips sessions it doesn't consider graphical anyway.)
  # Escape hatch: pam_kwallet's graphical-session detection keys off the
  # session type at PAM time — if the wallet ever stays locked after a
  # greeter login, force it with:
  #   security.pam.services.greetd.kwallet.forceRun = true;
  # (modules/fprintd.nix depends on this staying password-driven: the wallet
  # key can only be derived from a TYPED password, so the greeter must not
  # be fingerprint-only.)
  security.pam.services.greetd.kwallet.enable = true;

  # Step 3. kwallet-pam ships this unit in share/systemd/user — a directory
  # systemd.packages does NOT scan (only etc/ and lib/systemd/user; Plasma
  # gets away with it by linking all of /share and starting the unit from
  # its own session). So the unit is declared here verbatim instead, with
  # the upstream ExecStart. Without it ksecretd stays keyed-but-busless
  # (step 2) and every secrets consumer prompts for a password.
  # Upstream's Before=/After= lines reference plasma-* units that don't
  # exist here and were dropped — but their ROLE (run only once the
  # compositor is up) must be kept. The env-pipe timing is load-bearing:
  # ksecretd constructs its QApplication the moment the env arrives, so
  # WAYLAND_DISPLAY in that env must point at a LIVE socket — in the niri
  # era this unit once raced the compositor, piped a STALE WAYLAND_DISPLAY
  # from the previous session, and ksecretd SIGABRTed, taking the
  # PAM-derived wallet key with it (every secrets consumer then prompted).
  # There is no compositor user unit to order after now (greetd execs
  # Hyprland directly; no uwsm) — instead the guarantee comes from
  # hyprland.lua's startup hook: it pushes the fresh env into the user
  # manager and THEN starts hyprland-session.target, whose BindsTo pulls up
  # graphical-session.target. So After=graphical-session.target implies the
  # env push already happened. (No deadlock with WantedBy on the same
  # target: the target doesn't wait for its wants, this unit just starts
  # once the target is active.)
  systemd.user.services.plasma-kwallet-pam = {
    description = "Unlock kwallet from PAM credentials";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      Type = "simple";
      Slice = "background.slice";
      Restart = "no";
    };
  };
}
