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
  home.packages = [
    # `kwallet-rekey [wallet]` — pops KWallet's change-password dialog for
    # the wallet (default: kdewallet). Rekeying has no CLI/GUI entry point
    # here (kwalletmanager isn't installed), so the D-Bus method is the
    # only path. Signature sxs = (wallet name, window id, appid).
    #
    # ⚠ pam_kwallet (modules/kwallet.nix) derives the wallet key from the
    # LOGIN password — rekeying to anything else silently breaks
    # auto-unlock at next login, so change the login password first
    # (passwd), then rekey the wallet to the same one. The script prints
    # that reminder before the dialog appears.
    (pkgs.writeShellScriptBin "kwallet-rekey" ''
      wallet=''${1:-kdewallet}
      echo "NOTE: auto-unlock (pam_kwallet) only works if the wallet password" >&2
      echo "matches your LOGIN password. Keep them in sync — change your login" >&2
      echo "password first (passwd), then rekey the wallet to the same one." >&2
      exec busctl --user call org.kde.kwalletd6 /modules/kwalletd6 \
        org.kde.KWallet changePassword "sxs" "$wallet" 0 ""
    '')
  ];

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
