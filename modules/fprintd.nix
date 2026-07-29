# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor
# (lsusb 06cb:0123, libfprint "synaptics" driver). Enroll once after the
# first switch with:
#   fprintd-enroll
# (enrollment needs polkit auth; the Noctalia shell carries its own polkit
# agent — enabled in home/noctalia/config.toml — which shows the prompt.)
# Then sanity-check the sensor with: fprintd-verify
{ config, lib, pkgs, ... }:

{
  # fprintd is the D-Bus daemon PAM talks to. CAREFUL: enabling it flips
  # security.pam.services.*.fprintAuth on BY DEFAULT for EVERY PAM service
  # (sudo, polkit, greetd, tty login) — the opt-outs below are as
  # load-bearing as this line. What we keep: fingerprint for sudo and
  # polkit prompts.
  services.fprintd.enable = true;

  # ── Keep the greeter (and tty login) password-only — BY DESIGN ─────────
  # pam_kwallet (wired on the `greetd` service in modules/kwallet.nix) can
  # only derive the wallet key from the password typed at login. A
  # fingerprint login would leave the wallet locked and every secrets
  # consumer (Dolphin's saved SMB shares, browser Safe Storage) prompting
  # separately — so the greeter stays password-only forever, and
  # fingerprint is for the surfaces where the wallet is already open:
  # sudo and polkit. `login` also stays password-only because the Noctalia
  # lock screen authenticates against /etc/pam.d/login on NixOS —
  # pam_fprintd there would gate the LOCK SCREEN's password path behind a
  # finger-scan prompt (and tty logins with it). Noctalia does have its own
  # [lockscreen] fingerprint option; wiring it up is a deliberate follow-up
  # experiment, NOT part of the DMS→Noctalia migration — verify on-machine
  # how it interacts with this opt-out before flipping anything.
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;
}
