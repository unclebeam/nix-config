# unclebeam-pc — AMD Ryzen 9 desktop with an AMD RDNA GPU. Primary gaming box.
#
# Hosts stay THIN on purpose: hostname, hardware quirks, and which shared
# modules this machine uses. All real configuration lives in modules/ and home/.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; see the placeholder note
    ../../modules/core.nix       # users, nix settings, boot loader, networking…
    ../../modules/sway.nix       # sway session, greetd, portals
    ../../modules/audio.nix      # pipewire
    ../../modules/gaming.nix     # steam + gamemode (importing it = enabling it)
  ];

  # MUST match the attribute name in flake.nix — this is how a bare
  # `nixos-rebuild switch --flake .` finds the right config on this machine.
  networking.hostName = "unclebeam-pc";

  # AMD RDNA graphics: the in-kernel `amdgpu` driver loads automatically and
  # Mesa provides OpenGL (radeonsi) + Vulkan (RADV). No proprietary blobs.
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit GL/Vulkan for Steam/Proton (steam sets this too; explicit is clearer)
  };

  # CPU microcode security/stability updates for the Ryzen.
  hardware.cpu.amd.updateMicrocode = true;

  # Version of NixOS this machine was FIRST installed with. It gates stateful
  # migration defaults — set once, then never change it, even on upgrades.
  system.stateVersion = "26.05";
}
