# unclebeam-thinkpad — ThinkPad X1 Carbon Aura Edition (Intel Core Ultra,
# Intel graphics). Same desktop as the PC, plus laptop power management.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; filesystems live in disko.nix
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix
    ../../modules/nix-config.nix # clone ~/nix-config on first boot (out-of-store symlink target)
    ../../modules/desktop.nix    # fonts, Wayland env, GTK portal fallback
    ../../modules/niri.nix       # niri session, system half
    ../../modules/dms.nix        # DMS shell, system half (user glue in home/dms.nix)
    ../../modules/dms-greeter.nix # DMS login greeter on greetd
    ../../modules/gnome-keyring.nix # gnome-keyring + PAM unlock on greetd + seahorse
    ../../modules/audio.nix
    ../../modules/bluetooth.nix  # bluez userspace for the built-in Intel adapter (pairing UI is the shell's)
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl; f/j: hold = shift
    ../../modules/laptop.nix     # power mgmt, backlight, lid behavior, fwupd
    ../../modules/ddc.nix        # DDC/CI brightness for the docked monitor (panel stays on kernel backlight)
    ../../modules/fprintd.nix    # fingerprint auth (sudo/polkit; greeter + lock stay password — keyring unlock)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + browser extension (Chrome + Brave)
    ../../modules/chromium-policies.nix # managed policy for all Chromium-family browsers
    ../../modules/nautilus.nix   # gvfs + avahi discovery + udisks2 + ntfs/exfat (system half of Nautilus)
    ../../modules/printing.nix   # CUPS + SANE, driverless network printing/scanning
    ../../modules/localsend.nix  # LAN file sharing + firewall port
    ../../modules/syncthing.nix  # continuous file sync between machines (P2P; GUI-owned config)
    ../../modules/flatpak.nix    # flatpak service + weekly update timer
    ../../modules/orca-slicer.nix # OrcaSlicer flatpak + Bambu X1C LAN discovery firewall holes
    ../../modules/rustdesk.nix   # RustDesk flatpak (client only; niri can't be hosted)
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
    # ../../modules/gaming.nix   # uncomment to get Steam on the laptop too
  ];

  # Must match the attribute name in flake.nix.
  networking.hostName = "unclebeam-thinkpad";

  hardware.graphics.enable = true;

  # No swap partition in disko.nix; zram covers memory pressure instead.
  zramSwap.enable = true;

  # Set once at install; never change, even on upgrades.
  system.stateVersion = "26.05";
}
