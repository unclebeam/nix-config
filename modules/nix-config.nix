# nix-config.nix — self-provision the ~/nix-config checkout.
#
# The repo checkout at ~/nix-config is a load-bearing invariant (see
# CLAUDE.md): every out-of-store symlink hardcodes it — hyprland.lua, the
# hypr/binds.lua + hypr/host.lua fragments, the noctalia config dir, and the
# neovim config. On a fresh nixos-anywhere install the checkout doesn't
# exist yet, so all of those links dangle and the FIRST login is broken
# (no compositor config, no shell config, configless nvim) until someone
# remembers to clone. This
# oneshot closes that gap: it clones the repo on the first boot that has
# network, then never runs again.
#
# Failure modes are deliberately soft:
#  * ConditionPathExists watches ~/nix-config/.git — a real-checkout marker,
#    NOT the bare directory. The bare-directory check burned on paper 2026-08:
#    a home-manager activation script was creating ~/nix-config/… seconds
#    after boot with NO network dependency, so on a fresh install the
#    directory existed before this unit's network-online wait finished — the
#    condition would fail, a condition-skip is not a unit *failure*,
#    Restart=on-failure never fires, and the clone never happens (dangling
#    symlinks forever, the exact bounced-login bug the retry loop exists to
#    prevent). That particular script is gone, but the .git marker stays: it's
#    correct no matter what else ever pre-seeds the directory. Keying on .git
#    means only an actual checkout — however it got there — makes the unit a
#    silent no-op forever; it can never touch a repo with local work in it.
#    The condition is re-checked on every restart, so a manual clone while the
#    unit is retrying stops the retries cleanly instead of racing them.
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
      ConditionPathExists = "!/home/unclebeam/nix-config/.git";
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
    # NOT a plain `git clone`: something may already have put files in
    # ~/nix-config before we run (a home-manager activation script did
    # exactly that until 2026-08), and `git clone` fails PERMANENTLY into a
    # non-empty directory — the 15s retry loop would spin forever.
    # init+fetch+checkout is the clone-into-non-empty idiom: idempotent
    # across retries (every step tolerates a partial previous attempt), and
    # it leaves any pre-existing untracked files alone.
    script = ''
      mkdir -p /home/unclebeam/nix-config
      cd /home/unclebeam/nix-config
      git init -b main
      git remote add origin https://github.com/unclebeam/nix-config.git 2>/dev/null || true
      git fetch origin
      git checkout -f -B main -t origin/main
    '';
  };
}
