# docker.nix — Docker daemon + compose. Importing this module = enabling it.
{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;

    # Socket activation launches dockerd on the first `docker` command
    # instead of at boot — saves RAM/battery when containers aren't in use.
    enableOnBoot = false;

    # Weekly prune, or /var/lib/docker grows forever.
    autoPrune.enable = true;
  };

  # Compose v2; `docker compose` also works via CLI plugin discovery.
  environment.systemPackages = [ pkgs.docker-compose ];

  # docker-group membership is effectively root-equivalent (can mount / into
  # a container). Merges with core.nix's groups; takes effect on re-login.
  users.users.unclebeam.extraGroups = [ "docker" ];
}
