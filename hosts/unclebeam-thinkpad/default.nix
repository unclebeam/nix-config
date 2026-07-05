# unclebeam-thinkpad — ThinkPad X1 Carbon Aura Edition (Intel Core Ultra,
# Intel graphics). Same desktop as the PC, plus laptop power management.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; see the placeholder note
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix
    ../../modules/sway.nix
    ../../modules/audio.nix
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl
    ../../modules/laptop.nix     # power mgmt, backlight, lid behavior, fwupd
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/onepassword.nix # 1Password app + op CLI + Brave extension
    ../../modules/dolphin.nix    # avahi (SMB discovery) + kwallet PAM unlock
    # ../../modules/gaming.nix   # uncomment to get Steam on the laptop too
  ];

  # MUST match the attribute name in flake.nix.
  networking.hostName = "unclebeam-thinkpad";

  # Intel graphics: the in-kernel driver + Mesa load automatically;
  # this enables the userspace GL/Vulkan stack.
  hardware.graphics.enable = true;

  # Set once at first install, never change (see the PC host for details).
  system.stateVersion = "26.05";
}
