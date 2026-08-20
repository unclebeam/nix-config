# modules/flatpak.nix — the flatpak mechanism only: service + update policy.
# No app is named here; each flatpak app contributes its own
# services.flatpak.packages line from its own module (OrcaSlicer: cannot be a
# Nix package — ABI defect, see its header; RustDesk: chooses Flathub for
# freshness). If both app modules ever go, delete this file and the
# nix-flatpak flake input together.
#
# The nix-flatpak input exists because nixpkgs' services.flatpak has only
# `enable` — no way to declare remotes or apps. Flathub is already in the
# module's default remotes, so no remote is declared anywhere in this repo.
{ config, lib, pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    # `packages` deliberately not set here — it's a merging list option; each
    # app owns its entry next to its rationale. Check the merge result with:
    #   nix eval --json .#nixosConfigurations.unclebeam-pc.config.services.flatpak.packages

    # Timer, NOT update.onActivation: activation-time updates would make every
    # switch reach out to Flathub, so a rebuild on a flaky connection could
    # fail for unrelated reasons. (The install of a newly declared package
    # still happens at activation — that one switch needs network.)
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    # uninstallUnmanaged stays default false: hand-installed flatpaks are not
    # this module's business to remove.
  };
}
