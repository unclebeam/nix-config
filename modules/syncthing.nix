# modules/syncthing.nix — Syncthing, continuous file sync between machines.
#
# Syncthing is peer-to-peer: there is NO client/server split. Every machine
# runs the same daemon as an equal peer that discovers and syncs directly with
# the other over the LAN. This file does NOT set up any server, relay, or
# discovery daemon (those are separate services) — just a local peer on each
# host that imports it.
#
# This lives in modules/ (system level), not home/, for the same reason as
# LocalSend: it needs a firewall hole. NixOS's firewall is on by default, and
# without the P2P ports open the two machines can neither discover nor reach
# each other. nixpkgs' services.syncthing handles the package, the systemd
# service, AND the ports, so one file covers the whole intent — removing
# Syncthing = delete this file plus its import line in each host.
#
# WHAT'S EXPOSED: only the peer-to-peer ports (openDefaultPorts below). The web
# GUI stays bound to 127.0.0.1:8384 (the module default, left untouched) — it is
# reachable only from the machine itself, never from the network.
#
# CONFIG IS GUI-OWNED, NOT NIX. Folders and paired devices are added at
# http://localhost:8384 and stored in Syncthing's own config — the same rule as
# editor configs, DMS settings, and the rclone token in home/google-drive.nix.
# This is why overrideDevices/overrideFolders are forced to false below: both
# default to TRUE in nixpkgs, which would make every rebuild re-PUT the (here
# empty) Nix-declared device/folder set and WIPE everything added in the GUI.
# With them false, the GUI is the durable source of truth. Consequently we
# declare no settings.devices / settings.folders here at all.
#
# ONE-TIME SETUP (per machine, after the first switch):
#   1. Open http://localhost:8384 on each machine.
#   2. On one, Add Remote Device using the other's Device ID (Actions → Show ID);
#      accept the pairing prompt on the peer.
#   3. Add a shared folder and share it with the paired device → it syncs.
{ config, lib, pkgs, ... }:

{
  services.syncthing = {
    enable = true;

    # Run as the human user (module default is a dedicated `syncthing` user),
    # so shared folders can live under /home/unclebeam and their contents are
    # owned by the user, not a service account.
    user = "unclebeam";
    group = "users";

    # Keep Syncthing's own config/index and default folder base under the
    # user's home instead of /var/lib/syncthing. dataDir is the base that
    # relative folder paths resolve against, so folders default under home.
    configDir = "/home/unclebeam/.config/syncthing";
    dataDir = "/home/unclebeam";

    # Open ONLY the peer-to-peer ports in the firewall: TCP+UDP 22000
    # (direct + QUIC transfers) and UDP 21027 (LAN discovery broadcasts).
    # Default is false, which would leave the two machines unable to find or
    # reach each other. The GUI port (8384) is deliberately NOT opened.
    openDefaultPorts = true;

    # Make the web GUI the source of truth for devices and folders (see header):
    # default true would clobber GUI-added state on every rebuild.
    overrideDevices = false;
    overrideFolders = false;
  };
}
