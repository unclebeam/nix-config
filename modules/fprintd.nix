# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor.
# Enroll once after the first switch: `fprintd-enroll` (DMS's built-in polkit
# agent shows the prompt); sanity-check with `fprintd-verify`.
{ config, lib, pkgs, ... }:

{
  # CAREFUL: enabling flips fprintAuth on by default for EVERY PAM service
  # (~20). The opt-outs below are as load-bearing as this line; what's kept is
  # fingerprint for sudo, polkit, su-l/runuser, systemd-user.
  services.fprintd.enable = true;

  # Greeter stays password-only forever: pam_gnome_keyring can only derive the
  # keyring key from a typed password — a fingerprint login would leave the
  # keyring locked and every secrets consumer prompting separately. `login`
  # too: the DMS lock screen's password path authenticates against it (as do
  # tty logins). DMS's own lock-screen fingerprint is orthogonal — the shell
  # talks to fprintd directly, outside PAM, so this neither enables nor blocks
  # it.
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;

  # Narrow the blast radius to sudo + polkit:
  #  * passwd/chpasswd — password change must stay behind the current password
  #    (it's the operation that silently breaks keyring auto-unlock).
  #  * systemd-run0 — run0 root escalation.
  #  * vlock — console locker (not covered by the `login` opt-out).
  #  * su — target-password-only, matching tty policy.
  #  * other — the PAM catch-all; future services would silently inherit.
  #  * swaylock — unused stack programs.niri generates unconditionally;
  #    dead auth surface, neutralized for hygiene.
  security.pam.services.passwd.fprintAuth = false;
  security.pam.services.chpasswd.fprintAuth = false;
  security.pam.services.systemd-run0.fprintAuth = false;
  security.pam.services.vlock.fprintAuth = false;
  security.pam.services.su.fprintAuth = false;
  security.pam.services.other.fprintAuth = false;
  security.pam.services.swaylock.fprintAuth = false;
}
