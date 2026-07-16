# fprintd.nix — fingerprint auth for the ThinkPad's Synaptics sensor
# (lsusb 06cb:0123, libfprint "synaptics" driver). Enroll once after the
# first switch with:
#   sudo fprintd-enroll unclebeam
# (sudo, not plain fprintd-enroll: enrollment needs polkit auth, and this
# session deliberately runs no polkit agent — see modules/niri.nix — so
# there is nothing to show the prompt and polkit denies. Root bypasses it.)
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
  # pam_gnome_keyring (wired on the sddm service in modules/nautilus.nix)
  # can only auto-unlock the keyring with the password typed at login. A
  # fingerprint login would leave the keyring locked and every
  # keyring-backed app prompting separately — so first login stays
  # password-only, and fingerprint is for the surfaces where the keyring
  # is already open.
  security.pam.services.sddm.fprintAuth = false;
  security.pam.services.login.fprintAuth = false; # tty login: same rule

  # Known quirk left as-is: on the gtklock lock screen PAM runs
  # pam_fprintd first, so a typed password is only accepted after the
  # fingerprint attempt fails (3 bad reads) or times out. If that annoys
  # in practice, the fix is one line here:
  #   security.pam.services.gtklock.fprintAuth = false;
}
