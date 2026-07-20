# unclebeam-thinkpad — ThinkPad X1 Carbon Aura Edition (Intel Core Ultra,
# Intel graphics). Same desktop as the PC, plus laptop power management.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; see the placeholder note
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix
    ../../modules/desktop.nix    # fonts, Wayland env, GTK portal fallback
    ../../modules/hyprland.nix   # hyprland session (re-trial vs niri, 2026-07; full replacement on this branch)
    ../../modules/dms.nix        # DMS shell, system half (service defaults + shell fonts; shell itself in home/dms.nix)
    ../../modules/dms-greeter.nix # DMS login greeter on greetd (replaced SDDM 2026-07)
    ../../modules/kwallet.nix    # session keyring: ksecretd + pam_kwallet unlock (replaced gnome-keyring 2026-07)
    ../../modules/audio.nix
    ../../modules/bluetooth.nix  # bluetoothd + Blueman GUI (built-in Intel adapter)
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl
    ../../modules/laptop.nix     # power mgmt, backlight, lid behavior, fwupd
    ../../modules/fprintd.nix    # fingerprint auth (sudo/polkit/DMS lock screen; greeter stays password — kwallet)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + Brave extension
    ../../modules/brave.nix      # Brave managed policy: Google as default search (user half in home/brave.nix)
    ../../modules/dolphin.nix    # avahi discovery + udisks2 + ntfs/exfat (system half of Dolphin)
    ../../modules/localsend.nix  # LAN file sharing (AirDrop-style) + firewall port
    ../../modules/syncthing.nix  # continuous file sync between machines (P2P; GUI-owned config)
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
