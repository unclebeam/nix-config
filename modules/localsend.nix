# modules/localsend.nix — LocalSend, an open-source AirDrop alternative
# for sharing files between devices on the local network.
#
# This lives in modules/ (system level), not home/, because LocalSend needs
# a firewall hole: NixOS's firewall is on by default, and without port 53317
# open other devices can neither discover this machine nor send files to it.
# nixpkgs ships a module that handles both the package and the port, so one
# file covers the whole intent — removing LocalSend = delete this file plus
# its import line in each host.
#
# App settings live in ~/.local/share/localsend, managed by the app itself,
# not Nix (same rule as editor configs).
{ config, lib, pkgs, ... }:

{
  programs.localsend = {
    enable = true;
    openFirewall = true; # TCP+UDP 53317: multicast discovery + file transfer
  };
}
