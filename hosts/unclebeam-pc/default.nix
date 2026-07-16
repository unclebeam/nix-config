# unclebeam-pc — AMD Ryzen 9 desktop with an AMD RDNA GPU. Primary gaming box.
#
# Hosts stay THIN on purpose: hostname, hardware quirks, and which shared
# modules this machine uses. All real configuration lives in modules/ and home/.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; filesystems moved to disko.nix
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix       # users, nix settings, boot loader, networking…
    ../../modules/desktop.nix    # greeter (session picker), fonts, Wayland env
    ../../modules/niri.nix       # niri session (the only compositor; won the trial vs hyprland)
    ../../modules/gtklock.nix    # greeter-look lock screen (gtklock + plugin modules + PAM)
    ../../modules/audio.nix      # pipewire
    ../../modules/bluetooth.nix  # bluez userspace for the MT7925's BT radio
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl
    ../../modules/gaming.nix     # steam + gamemode (importing it = enabling it)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + Brave extension
    ../../modules/dolphin.nix    # avahi discovery + udisks2 + ntfs/exfat (system half of Dolphin)
    ../../modules/localsend.nix  # LAN file sharing (AirDrop-style) + firewall port
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
    ../../modules/xbox-controller.nix # xone driver for the Xbox Wireless Adapter dongle
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

  # The onboard MediaTek MT7925 WiFi/BT chip fails to probe on every boot
  # ("mt7925e: driver own failed" → error -5, the message that leaks onto the
  # login screen): the chip's MCU never answers the driver's ownership
  # handshake. A known trigger on AMD boards is PCIe ASPM putting the device
  # in a low-power state that races the probe; turning ASPM off system-wide
  # lets the handshake complete. If this alone doesn't fix it, the next
  # escalation is adding "pcie_port_pm=off" here as well.
  boot.kernelParams = [ "pcie_aspm=off" ];

  # The MT7925's OTHER power-management failure: with btusb USB autosuspend
  # active (kernel default Y), the BT radio gets power-cycled mid-session and
  # live connections drop — observed here (2026-07) as the Xbox controller
  # binding fine (xpadneo "gamepad detected") and then disconnecting ~30s
  # later, in a loop, across two controller firmware versions and a clean
  # re-pair. Desktop box: autosuspend on the radio saves nothing worth having.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
  '';

  # The disk layout (disko.nix) has no swap partition. Instead, use zram:
  # a compressed block device in RAM used as swap. Cheap insurance against
  # memory pressure with no disk wear and nothing to partition.
  zramSwap.enable = true;

  # Version of NixOS this machine was FIRST installed with. It gates stateful
  # migration defaults — set once, then never change it, even on upgrades.
  system.stateVersion = "26.05";
}
