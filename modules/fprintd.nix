# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor
# (lsusb 06cb:0123, libfprint "synaptics" driver). Enroll once after the
# first switch with:
#   fprintd-enroll
# (enrollment needs polkit auth; the DMS shell carries its own built-in
# polkit agent — always on, no config — which shows the prompt.)
# Then sanity-check the sensor with: fprintd-verify
{ config, lib, pkgs, ... }:

{
  # fprintd is the D-Bus daemon PAM talks to. CAREFUL: enabling it flips
  # security.pam.services.*.fprintAuth on BY DEFAULT for EVERY PAM service —
  # evaluated, that's ~20 services: not just sudo/polkit-1 but also passwd,
  # chpasswd, su, systemd-run0, vlock, the `other` catch-all, and more.
  # The opt-outs below are as load-bearing as this line. What we KEEP after
  # them: fingerprint for sudo, polkit prompts, su-l/runuser, systemd-user.
  services.fprintd.enable = true;

  # ── Keep the greeter (and tty login) password-only — BY DESIGN ─────────
  # pam_gnome_keyring (wired on the `greetd` service in
  # modules/gnome-keyring.nix) can only derive the keyring key from the
  # password typed at login. A fingerprint login would leave the keyring
  # locked and every secrets consumer (Nautilus/gvfs's saved SMB
  # credentials, browser Safe Storage) prompting separately — so the
  # greeter stays password-only forever, and fingerprint is for the
  # surfaces where the keyring is already open:
  # sudo and polkit. `login` also stays password-only because the DMS
  # lock screen authenticates against /etc/pam.d/login on NixOS —
  # pam_fprintd there would gate the LOCK SCREEN's password path behind a
  # finger-scan prompt (and tty logins with it). (This stance is
  # era-independent: it held under DMS the first time, under Noctalia,
  # under both keyrings — kwallet then, gnome-keyring now — and every
  # shell's lock has used `login` for its password path.)
  #
  # (DMS's own lock-screen fingerprint support is ORTHOGONAL to these
  # opt-outs: the shell talks to fprintd directly, not through the
  # `login` PAM stack, so `login.fprintAuth` neither enables nor blocks
  # it. The opt-out here still matters for the lock screen's PASSWORD
  # path and for tty logins.)
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;

  # ── Narrow the blast radius to the stated intent (sudo + polkit) ───────
  # Without these, the enable-everything default quietly hands a finger
  # scan powers it shouldn't have:
  #  * passwd/chpasswd — CHANGING the login password by finger-scan. That's
  #    exactly the operation the keyring warning (modules/gnome-keyring.nix)
  #    says silently breaks keyring auto-unlock; it must stay deliberate,
  #    behind the current password.
  #  * systemd-run0 — run0 root escalation.
  #  * vlock — the console locker (not covered by the `login` opt-out).
  #  * su — keep target-password-only, matching the tty-login policy.
  #  * other — the PAM catch-all: any future service without its own stack
  #    would silently inherit fingerprint.
  #  * swaylock — an unused stack nixpkgs generates via programs.niri
  #    (wayland-session.nix ships it unconditionally; swaylock isn't
  #    installed, the DMS lock uses `login`) — dead auth surface,
  #    neutralized for hygiene.
  security.pam.services.passwd.fprintAuth = false;
  security.pam.services.chpasswd.fprintAuth = false;
  security.pam.services.systemd-run0.fprintAuth = false;
  security.pam.services.vlock.fprintAuth = false;
  security.pam.services.su.fprintAuth = false;
  security.pam.services.other.fprintAuth = false;
  security.pam.services.swaylock.fprintAuth = false;
}
