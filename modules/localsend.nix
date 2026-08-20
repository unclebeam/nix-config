# modules/localsend.nix — LocalSend, an open-source AirDrop alternative.
# In modules/ because it needs a firewall hole; the nixpkgs module covers
# package + port in one option. App settings are app-owned, not Nix.
{ config, lib, pkgs, ... }:

{
  programs.localsend = {
    enable = true;
    openFirewall = true; # TCP+UDP 53317: multicast discovery + file transfer
  };
}
