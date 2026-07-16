# kwallet.nix — the session keyring, KDE edition (SYSTEM half; the USER half
# — kwalletrc — is home/kwallet.nix). Replaced gnome-keyring 2026-07 by
# explicit request: session plumbing followed the file manager to KDE, with
# screencasting as the sole GNOME holdout (see modules/niri.nix). ksecretd
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
  # The nixpkgs niri module enables gnome-keyring with mkDefault, so this
  # plain `false` (priority 100) wins without mkForce. Everything the
  # gnome-keyring module wired — pam_gnome_keyring on the `login` PAM
  # service, its Secret portal backend, the D-Bus activation, the
  # CAP_IPC_LOCK wrapper — is behind its own mkIf and retracts with it.
  # Deleting this file (+ import lines + home/kwallet.nix) therefore reverts
  # cleanly to the niri module's stock gnome-keyring setup.
  services.gnome.gnome-keyring.enable = false;

  # kdePackages.kwallet ships kwallet.portal (an org.freedesktop.impl.portal.
  # Secret backend, needed by sandboxed/portal-only apps) plus the D-Bus
  # activation files for ksecretd and the kwalletd6 compat wrapper. Listing
  # it in extraPortals lets the xdg.portal module wire dbus.packages,
  # systemPackages (kwallet-query lands on PATH) and the portal dir in one
  # go — exactly how plasma6.nix installs it.
  xdg.portal.extraPortals = [ pkgs.kdePackages.kwallet ];

  # The niri module hard-sets Secret="gnome-keyring" in niri-portals.conf;
  # same-key portal routes are coerced strings, so overriding takes mkForce
  # (a second plain definition is an eval conflict, not a merge). The rest
  # of the routing overrides live in modules/niri.nix — the Secret route is
  # here so removing this file removes every trace of the KDE keyring.
  xdg.portal.config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "kwallet";

  # PAM half of step 1. On `login`, NOT `sddm`: on this nixpkgs the sddm PAM
  # service is generated with useDefaultRules=false and is just a substack
  # of `login`, so per-service toggles on sddm are silent no-ops (the old
  # sddm.enableGnomeKeyring line was one; pam_gnome_keyring really came from
  # the gnome-keyring module targeting `login`). plasma6.nix targets `login`
  # for the same reason. pam_kwallet skips sessions without a graphical
  # XDG_SESSION_TYPE, so tty logins are unaffected; `kwallet.forceRun` is
  # the escape hatch if that detection ever misfires.
  # (modules/fprintd.nix depends on this staying password-driven: the wallet
  # key can only be derived from a TYPED password, so first login must not
  # be fingerprint-only.)
  security.pam.services.login.kwallet.enable = true;

  # Step 3. kwallet-pam ships this unit in share/systemd/user — a directory
  # systemd.packages does NOT scan (only etc/ and lib/systemd/user; Plasma
  # gets away with it by linking all of /share and starting the unit from
  # its own session). So the unit is declared here verbatim instead, with
  # the upstream ExecStart. Without it ksecretd stays keyed-but-busless
  # (step 2) and every secrets consumer prompts for a password.
  # Upstream's Before=/After= lines reference plasma-* units that don't
  # exist here and were dropped; ordering is safe because niri-session
  # imports the PAM environment (incl. PAM_KWALLET5_LOGIN) into the user
  # manager before graphical-session.target comes up.
  systemd.user.services.plasma-kwallet-pam = {
    description = "Unlock kwallet from PAM credentials";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      Type = "simple";
      Slice = "background.slice";
      Restart = "no";
    };
  };
}
