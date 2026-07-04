# docker.nix — Docker daemon + compose. Importing this module = enabling it.
{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;

    # Don't start dockerd at boot; socket activation launches it on the
    # first `docker` command instead. Saves RAM (and battery on the
    # thinkpad) whenever containers aren't in use.
    enableOnBoot = false;

    # Weekly cleanup of dangling images/stopped containers, mirroring the
    # nix gc policy in core.nix — otherwise /var/lib/docker grows forever.
    autoPrune.enable = true;
  };

  # Compose v2. Provides the standalone `docker-compose` binary; the
  # `docker compose` (space) subcommand works too because the docker CLI
  # discovers it as a plugin.
  environment.systemPackages = [ pkgs.docker-compose ];

  # Membership in the docker group = talking to the daemon socket without
  # sudo. That is effectively root-equivalent access — anyone in the group
  # can mount / into a container. extraGroups lists merge across modules,
  # so this composes with the groups in core.nix and disappears atomically
  # when this module is removed. Takes effect after a re-login.
  users.users.unclebeam.extraGroups = [ "docker" ];
}
