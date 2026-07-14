# unclebeam-thinkpad — ThinkPad X1 Carbon Aura Edition (Intel Core Ultra,
# Intel graphics). Same desktop as the PC, plus laptop power management.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; see the placeholder note
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix
    ../../modules/desktop.nix    # greeter (session picker), fonts, Wayland env
    ../../modules/niri.nix       # niri session (the only compositor; won the trial vs hyprland)
    ../../modules/audio.nix
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl
    ../../modules/laptop.nix     # power mgmt, backlight, lid behavior, fwupd
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + Brave extension
    ../../modules/nautilus.nix   # gvfs (smb://) + avahi discovery + keyring PAM unlock
    ../../modules/localsend.nix  # LAN file sharing (AirDrop-style) + firewall port
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
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
