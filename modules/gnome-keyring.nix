# gnome-keyring.nix — the session keyring, GNOME edition (took the job back
# from ksecretd/kwallet 2026-08: auth follows the file layer to GNOME; the
# 2026-07 KDE detour lives on in git history as modules/kwallet.nix +
# home/kwallet.nix). gnome-keyring-daemon owns org.freedesktop.secrets — the
# store behind Nautilus/gvfs's saved share credentials, browser Safe Storage
# keys, and the Secret portal.
#
# This module is SHORT because upstream already leans this way:
# programs.niri (modules/niri.nix) enables gnome-keyring by mkDefault and
# routes the Secret portal to it. The kwallet era existed by FIGHTING those
# defaults (a live enable=false plus a mkForce Secret→kwallet reroute);
# coming back to GNOME mostly means deleting the fight. What kwallet.nix
# carried that has NO equivalent here, on purpose:
#  * no portal override — upstream's Secret=gnome-keyring in
#    niri-portals.conf is simply correct now (and with kwallet's reroute
#    gone, NO portal key in this repo needs mkForce anymore);
#  * no xdg.portal.extraPortals — services.gnome.gnome-keyring installs the
#    daemon, its D-Bus activation, and gnome-keyring's own
#    org.freedesktop.impl.portal.Secret backend in one option;
#  * no systemd user unit — pam_gnome_keyring starts the daemon inside the
#    PAM session and hands it the password directly, so there is no
#    keyed-but-busless limbo needing a plasma-kwallet-pam-style env pipe
#    (and no WAYLAND_DISPLAY race to document: the daemon doesn't care).
#
# The login chain: pam_gnome_keyring captures the typed password in the
# auth phase, then in the session phase starts gnome-keyring-daemon and
# unlocks the `login` keyring with it. First password login auto-creates
# that keyring — no wizard. Caveat, same shape as the kwallet era's: a
# later `passwd` does NOT re-encrypt the keyring — auto-unlock silently
# breaks until the keyring password is changed to match (Seahorse:
# right-click the Login keyring → Change Password).
{ config, lib, pkgs, ... }:

{
  # The daemon + D-Bus activation + Secret portal backend + the
  # CAP_IPC_LOCK wrapper (lets the daemon mlock() secret pages out of
  # swap). programs.niri already mkDefaults this true; pinned explicitly
  # because it IS the session keyring now — belt-and-braces like
  # useNautilus in modules/niri.nix, so an upstream default flip can't
  # silently take the keyring down with it.
  services.gnome.gnome-keyring.enable = true;

  # PAM half — on `greetd` (the DMS greeter's display manager,
  # modules/dms-greeter.nix). Unlike the old sddm service — generated with
  # useDefaultRules=false as a bare substack of `login`, where per-service
  # toggles were silent no-ops — greetd's PAM service is generated WITH
  # default rules, and greetd does NOT traverse `login`. So the hook must
  # sit on `greetd` itself; a hook on `login` would never fire at
  # graphical login. NB the greetd module already mkDefault-follows
  # services.gnome.gnome-keyring.enable for this option, so the line is
  # technically redundant — kept because the login unlock is the whole
  # point of this file, and a mkDefault three modules away is not where
  # anyone will look for it.
  # (modules/fprintd.nix depends on this staying password-driven: the
  # keyring key can only be derived from a TYPED password, so the greeter
  # must not be fingerprint-only.)
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Seahorse ("Passwords and Keys") — browse/delete stored secrets and,
  # the actual reason it's here, re-key the Login keyring after a password
  # change (the kwallet era needed a hand-rolled `kwallet-rekey` script
  # for this; Seahorse is the stock tool). Config-less, so it sits in
  # systemPackages core.nix-style rather than getting a home/ file.
  environment.systemPackages = [ pkgs.seahorse ];
}
