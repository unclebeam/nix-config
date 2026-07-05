# home/direnv.nix — per-directory environments.
# direnv watches for an `.envrc` as you cd around and loads/unloads it
# automatically. We use it for per-project toolchains: an .envrc saying
# `use flake nixpkgs#nodejs_22` puts that dev shell on PATH inside the
# project and takes it off again when you leave — the
# NixOS answer to nvm/.nvmrc, whose downloaded binaries wouldn't run here
# anyway (they expect a standard glibc layout the Nix store doesn't have).
# New/changed .envrc files are inert until you approve them: `direnv allow`.
{ config, lib, pkgs, ... }:

{
  programs.direnv = {
    # home-manager hooks direnv into fish automatically (it sees fish is
    # managed in home/fish.nix) — no manual shell-init line needed.
    enable = true;
    # nix-direnv replaces direnv's naive `use flake` with a cached one:
    # activation is instant after the first build, and the shell is
    # GC-rooted so `nix-collect-garbage` can't sweep it out from under you.
    nix-direnv.enable = true;
  };
}
