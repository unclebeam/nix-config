# nix-config.nix — self-provision the ~/nix-config checkout.
#
# The repo checkout at ~/nix-config is a load-bearing invariant (see
# CLAUDE.md): every out-of-store symlink hardcodes it — hyprland.lua, the
# whole hypr/dms fragment dir, and the neovim config. On a fresh
# nixos-anywhere install the checkout doesn't exist yet, so all of those
# links dangle and the FIRST login is broken (no compositor config, no DMS
# fragments, configless nvim) until someone remembers to clone. This
# oneshot closes that gap: it clones the repo on the first boot that has
# network, then never runs again.
#
# Failure modes are deliberately soft:
#  * ConditionPathExists means an existing checkout — however it got there
#    — makes the unit a silent no-op forever. It can never touch a repo
#    with local work in it. The condition is re-checked on every restart,
#    so a manual `git clone` while the unit is retrying stops the retries
#    cleanly instead of racing them.
#  * No network at boot → the unit RETRIES every 15s until the clone
#    succeeds (Restart=on-failure below). The original fail-once oneshot
#    burned a fresh install (unclebeam-pc 2026-07-21): network-online was
#    reached before DNS actually worked, the clone died in 11ms with
#    "Could not resolve host: github.com" and stayed dead, every
#    out-of-store symlink dangled, and graphical login bounced back to the
#    greeter until someone intervened from a TTY. Now the first login just
#    works ≤15s after network appears (watch `journalctl -u
#    clone-nix-config -f` for the attempts).
#  * Clones over https anonymously — the repo must be publicly fetchable,
#    which it already has to be for `nixos-anywhere github:…` installs to
#    work. The clone's origin is https; switch it to SSH by hand once keys
#    exist if pushing from that machine.
{ config, lib, pkgs, ... }:

{
  systemd.services.clone-nix-config = {
    description = "Clone ~/nix-config on first boot (out-of-store symlink target)";
    wantedBy = [ "multi-user.target" ];
    # network-online is a *want*, not a require: if NetworkManager can't
    # reach online state the unit should still attempt (and cleanly fail)
    # rather than hang the boot waiting.
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig = {
      ConditionPathExists = "!/home/unclebeam/nix-config";
      # No start-rate limit: a machine sitting without network (laptop
      # before wifi credentials exist) may retry for hours before the
      # clone can land, and that's fine.
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      # `simple`, NOT `oneshot`: a oneshot's start job blocks
      # multi-user.target (and via graphical.target, the greeter) until
      # the process EXITS — fine when it failed in 11ms, a black screen
      # for minutes once we retry. With `simple` the job completes as
      # soon as the process spawns, so boot never waits on the retries.
      Type = "simple";
      # The self-heal: a failed clone (no DNS yet) re-runs every 15s and
      # stops retrying the moment one attempt exits 0 — so the first
      # greeter login works within 15s of network coming up.
      Restart = "on-failure";
      RestartSec = 15;
      User = "unclebeam";
    };
    path = [ pkgs.git ];
    script = ''
      git clone https://github.com/unclebeam/nix-config.git /home/unclebeam/nix-config
    '';
  };
}
