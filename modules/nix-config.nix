# nix-config.nix — self-provision the ~/nix-config checkout, which every
# out-of-store symlink hardcodes. On a fresh install the checkout doesn't
# exist, all those links dangle, and the first login is broken until someone
# clones — this oneshot closes that gap, then never runs again.
{ config, lib, pkgs, ... }:

{
  systemd.services.clone-nix-config = {
    description = "Clone ~/nix-config on first boot (out-of-store symlink target)";
    wantedBy = [ "multi-user.target" ];
    # A want, not a require: if online state is never reached, attempt and
    # cleanly fail rather than hang the boot.
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig = {
      # Keyed on .git, NOT the bare directory: only a real checkout may make
      # this a permanent no-op — a pre-seeded empty dir must not skip the
      # clone (a condition-skip is not a failure, so Restart would never
      # fire and the symlinks would dangle forever). Re-checked on every
      # restart, so a manual clone stops the retries cleanly.
      ConditionPathExists = "!/home/unclebeam/nix-config/.git";
      # No start-rate limit: a machine may sit without network for hours.
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      # `simple`, NOT `oneshot`: a oneshot's start job blocks
      # multi-user.target (and the greeter) until the process exits — a
      # black screen for as long as the retry loop runs.
      Type = "simple";
      # Self-heal: network-online can be reached before DNS works, so a
      # failed clone re-runs every 15s until one attempt exits 0.
      Restart = "on-failure";
      RestartSec = 15;
      User = "unclebeam";
    };
    path = [ pkgs.git ];
    # NOT a plain `git clone`: it fails permanently into a non-empty dir and
    # the retry loop would spin forever. init+fetch+checkout is idempotent
    # across retries and leaves pre-existing untracked files alone. https
    # origin (the repo must be publicly fetchable anyway for nixos-anywhere);
    # switch to SSH by hand if pushing from that machine.
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
