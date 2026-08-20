# modules/syncthing.nix — P2P file sync between the two machines (equal
# peers; no server/relay here). In modules/ because it needs firewall holes.
# Folders and paired devices are GUI-owned (http://localhost:8384), not Nix.
# One-time setup per machine: open the GUI, Add Remote Device with the peer's
# ID, accept on the peer, share a folder.
{ config, lib, pkgs, ... }:

{
  services.syncthing = {
    enable = true;

    # Run as the human user (default is a dedicated `syncthing` user) so
    # shared folders live under /home/unclebeam owned by the user.
    user = "unclebeam";
    group = "users";

    # Config under home; dataDir is the base relative folder paths resolve
    # against, so folders default under home too.
    configDir = "/home/unclebeam/.config/syncthing";
    dataDir = "/home/unclebeam";

    # TCP+UDP 22000 (transfers) and UDP 21027 (LAN discovery). The GUI port
    # (8384) stays bound to 127.0.0.1 and is deliberately not opened.
    openDefaultPorts = true;

    # Both default TRUE, which would re-PUT the (empty) Nix-declared set on
    # every rebuild and WIPE everything added in the GUI.
    overrideDevices = false;
    overrideFolders = false;
  };
}
