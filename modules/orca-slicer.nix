# modules/orca-slicer.nix — system half of OrcaSlicer: the flatpak that owns
# the app, and the firewall holes for Bambu LAN discovery.
#
# WHY A FLATPAK: nixpkgs' orca-slicer cannot run here — the binary exports its
# own statically-linked libstdc++ symbols while also linking libstdc++.so.6,
# so Bambu's proprietary network plugin builds a std::locale through one C++
# runtime and destroys it through the other; glibc aborts ~2s into every
# launch. Build-level ABI defect — no .nix config can fix it. The Flathub
# build (published by OrcaSlicer's lead dev) links one shared libstdc++. Trade
# accepted: the slicer's version is not pinned by flake.lock. Do NOT "tidy up"
# the odd-one-out flatpak — that reintroduces a slicer that cannot start.
#
# WHY FIREWALL HOLES: NixOS's firewall is on by default, and without these the
# printer silently never appears — even with a Bambu cloud account, same-LAN
# discovery/upload/liveview take the direct path (nixpkgs#355821). The flatpak
# runs in the host network namespace, so the rules apply to it unchanged.
#
# Removing OrcaSlicer = this file + home/orca-slicer.nix + three import lines.
# The nix-flatpak input stays as long as any flatpak remains.
{ config, lib, pkgs, ... }:

{
  # `packages` comes from the nix-flatpak module; Flathub is in its default
  # remotes. Service enable + update timer are flatpak-wide policy in
  # modules/flatpak.nix. Merging list option — sits alongside RustDesk's.
  services.flatpak.packages = [ "com.orcaslicer.OrcaSlicer" ];

  networking.firewall = {
    # Inbound ports Bambu's LAN protocol needs: 2021 = SSDP discovery (decides
    # whether the printer shows up at all), 1990 = status/report channel.
    # Everything else (MQTT 8883/1883, FTPS 990, liveview 6000) is outbound.
    allowedUDPPorts = [ 1990 2021 ];

    # Discovery arrives as multicast, not unicast — open ports alone are not
    # enough. Insert into NixOS's own nixos-fw chain so the rule is created
    # and torn down with the managed firewall.
    extraCommands = ''
      iptables -I nixos-fw -p udp -m pkttype --pkt-type multicast -j nixos-fw-accept
    '';
    # Matching delete, or every switch stacks another copy of the rule.
    extraStopCommands = ''
      iptables -D nixos-fw -p udp -m pkttype --pkt-type multicast -j nixos-fw-accept || true
    '';
    # iptables syntax is correct while networking.nftables stays off. If that
    # ever flips, rewrite as extraInputRules — extraCommands is silently
    # ignored under nftables and discovery would quietly break.
  };
}
