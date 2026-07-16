# home/kwallet.nix — kwalletrc: the USER half of the session keyring (the
# daemon, PAM unlock, and portal wiring are system-side in
# modules/kwallet.nix). History: this file's predecessor lived in
# home/dolphin.nix as a BRIDGE config ([KSecretD] Enabled=false +
# MigrateTo3rdParty=true) that forwarded KWallet API calls into
# gnome-keyring. The 2026-07 KDE-plumbing migration inverted it: ksecretd
# now IS the org.freedesktop.secrets store, so the bridge settings are gone
# and this stands alone as its own intent.
#
# Failure mode if this file is ever deleted: KWallet's first-run wizard
# might appear once — never data loss.
{ config, lib, pkgs, ... }:

{
  xdg.configFile."kwalletrc".text = ''
    [Wallet]
    # Suppress the first-run wizard (the "Basic (Blowfish) vs Advanced
    # (GPG)" dialog). pam_kwallet creates `kdewallet` at first password
    # login before any app can trigger the wizard, so it's pure noise —
    # and a GPG-encrypted wallet would BREAK pam auto-unlock, so the
    # wizard is also a trap. NB: the wallet must stay Blowfish/password
    # encrypted with password == login password for auto-unlock to work.
    First Use=false

    [KSecretD]
    # Upstream default since the kwalletd split, kept explicit because it
    # documents the inversion of the old bridge (which set false to keep
    # KWallet from fighting gnome-keyring over org.freedesktop.secrets).
    # true = ksecretd is the session's one real keyring.
    Enabled=true
  '';
}
