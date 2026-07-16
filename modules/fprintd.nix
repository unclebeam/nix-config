# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor
# (lsusb 06cb:0123, libfprint "synaptics" driver). Enroll once after the
# first switch with:
#   fprintd-enroll
# (enrollment needs polkit auth; since 2026-07 plasma-polkit-agent —
# modules/polkit-agent.nix — shows the prompt. Before that agent existed,
# the workaround was `sudo fprintd-enroll unclebeam`.)
# Then sanity-check the sensor with: fprintd-verify
{ config, lib, pkgs, ... }:

{
  # fprintd is the D-Bus daemon PAM talks to. CAREFUL: enabling it flips
  # security.pam.services.*.fprintAuth on BY DEFAULT for EVERY PAM service
  # (sudo, polkit, gtklock, sddm, tty login) — the opt-outs below are as
  # load-bearing as this line. What we keep: fingerprint for sudo, polkit
  # prompts, and gtklock unlock.
  services.fprintd.enable = true;

  # ── Keep the greeter (and tty login) password-only ─────────────────────
  # pam_kwallet (wired on the `login` service in modules/kwallet.nix, which
  # sddm's PAM stack substacks) can only derive the wallet key from the
  # password typed at login. A fingerprint login would leave the wallet
  # locked and every secrets-backed app prompting separately — so first
  # login stays password-only, and fingerprint is for the surfaces where
  # the wallet is already open. The `login` line is the load-bearing one
  # (and always was — sddm has no default rules, it just substacks login);
  # the sddm line is a harmless no-op kept as belt-and-braces.
  security.pam.services.sddm.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;

  # Known quirk left as-is: on the gtklock lock screen PAM runs
  # pam_fprintd first, so a typed password is only accepted after the
  # fingerprint attempt fails (3 bad reads) or times out. If that annoys
  # in practice, the fix is one line here:
  #   security.pam.services.gtklock.fprintAuth = false;
}
