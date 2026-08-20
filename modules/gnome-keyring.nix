# gnome-keyring.nix — the session keyring. gnome-keyring-daemon owns
# org.freedesktop.secrets: gvfs saved share credentials, browser Safe Storage
# keys, and the Secret portal (upstream niri routes Secret→gnome-keyring; no
# portal override needed here).
#
# Login chain: pam_gnome_keyring captures the typed password in the auth
# phase, then starts the daemon and unlocks the `login` keyring in the session
# phase; first password login auto-creates the keyring. Caveat: a later
# `passwd` does NOT re-encrypt it — auto-unlock silently breaks until the
# keyring password is changed to match (Seahorse: Login keyring → Change
# Password).
{ config, lib, pkgs, ... }:

{
  # Daemon + D-Bus activation + Secret portal backend + CAP_IPC_LOCK wrapper.
  # programs.niri already mkDefaults this true; pinned so an upstream default
  # flip can't silently take the keyring down.
  services.gnome.gnome-keyring.enable = true;

  # The hook must sit on `greetd` itself — greetd does not traverse `login`,
  # so a hook there would never fire at graphical login. Technically redundant
  # (the greetd module mkDefault-follows the enable above) but the unlock is
  # this file's whole point. modules/fprintd.nix depends on this staying
  # password-driven: the keyring key derives only from a TYPED password.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Seahorse — browse stored secrets and re-key the Login keyring after a
  # password change. Config-less, hence systemPackages.
  environment.systemPackages = [ pkgs.seahorse ];
}
