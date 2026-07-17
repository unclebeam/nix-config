# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor
# (lsusb 06cb:0123, libfprint "synaptics" driver). Enroll once after the
# first switch with:
#   fprintd-enroll
# (enrollment needs polkit auth; the DMS shell carries its own polkit
# agent — home/dms.nix — which shows the prompt.)
# Then sanity-check the sensor with: fprintd-verify
{ config, lib, pkgs, ... }:

{
  # fprintd is the D-Bus daemon PAM talks to. CAREFUL: enabling it flips
  # security.pam.services.*.fprintAuth on BY DEFAULT for EVERY PAM service
  # (sudo, polkit, greetd, tty login) — the opt-outs below are as
  # load-bearing as this line. What we keep: fingerprint for sudo, polkit
  # prompts, and the DMS lock screen (which does NOT go through fprintAuth:
  # DMS talks to fprintd directly with its own pre-wired PAM fragments —
  # never hand-roll pam_fprintd into security.pam.services.dankshell).
  services.fprintd.enable = true;

  # ── Keep the greeter (and tty login) password-only — BY DESIGN ─────────
  # pam_kwallet (wired on the `greetd` service in modules/kwallet.nix) can
  # only derive the wallet key from the password typed at login. A
  # fingerprint login would leave the wallet locked and every secrets
  # consumer (Dolphin's saved SMB shares, browser Safe Storage) prompting
  # separately — so the greeter stays password-only forever, and
  # fingerprint is for the surfaces where the wallet is already open:
  # sudo, polkit, and the DMS lock screen. `login` also stays password-only
  # because the DMS lock screen's PASSWORD path authenticates against
  # /etc/pam.d/login on NixOS — pam_fprintd there would double-prompt
  # (DMS already handles the fingerprint itself, in parallel).
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;
}
