# unclebeam-thinkpad — ThinkPad X1 Carbon Aura Edition (Intel Core Ultra,
# Intel graphics). Same desktop as the PC, plus laptop power management.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; see the placeholder note
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix
    ../../modules/nix-config.nix # clone ~/nix-config on first boot (out-of-store symlink target)
    ../../modules/desktop.nix    # fonts, Wayland env, GTK portal fallback
    ../../modules/niri.nix       # niri session (back for good 2026-08; hyprland re-trial ended — full replacement)
    ../../modules/dms.nix        # DMS shell, system half (service + fonts + input group; user glue in home/dms.nix)
    ../../modules/dms-greeter.nix # DMS login greeter on greetd (took over from the Noctalia greeter 2026-08)
    ../../modules/gnome-keyring.nix # session keyring: gnome-keyring + PAM unlock on greetd + seahorse (took back over from ksecretd 2026-08)
    ../../modules/audio.nix
    ../../modules/bluetooth.nix  # bluez userspace for the built-in Intel adapter (pairing UI is the shell's — no Blueman)
    ../../modules/kanata.nix     # capslock: tap = esc, hold = ctrl; f/j: hold = shift
    ../../modules/laptop.nix     # power mgmt, backlight, lid behavior, fwupd
    ../../modules/ddc.nix        # DDC/CI brightness for the docked Dell (i2c + ddcutil; panel stays on kernel backlight)
    ../../modules/fprintd.nix    # fingerprint auth (sudo/polkit; greeter + lock stay password — keyring unlock)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + browser extension (Chrome + Brave)
    ../../modules/chromium-policies.nix # managed policy for ALL Chromium-family browsers (Chrome + Brave): Google as default search
    ../../modules/nautilus.nix   # gvfs + avahi discovery + udisks2 + ntfs/exfat (system half of Nautilus)
    ../../modules/printing.nix   # CUPS + SANE, driverless network printing/scanning
    ../../modules/localsend.nix  # LAN file sharing (AirDrop-style) + firewall port
    ../../modules/syncthing.nix  # continuous file sync between machines (P2P; GUI-owned config)
    ../../modules/flatpak.nix    # flatpak service + weekly update timer (the apps below declare their own packages)
    ../../modules/orca-slicer.nix # OrcaSlicer (flatpak — the Nix build can't run) + Bambu X1C LAN discovery firewall holes
    ../../modules/rustdesk.nix   # RustDesk remote desktop (flatpak — CLIENT ONLY; niri can't be hosted, see the module)
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
    # ../../modules/gaming.nix   # uncomment to get Steam on the laptop too
  ];

  # MUST match the attribute name in flake.nix.
  networking.hostName = "unclebeam-thinkpad";

  # Intel graphics: the in-kernel driver + Mesa load automatically;
  # this enables the userspace GL/Vulkan stack.
  hardware.graphics.enable = true;

  # The disk layout (disko.nix) has no swap partition — same as the PC.
  # zram covers it: a compressed block device in RAM used as swap. On the
  # laptop this matters MORE than on the desktop (less RAM headroom, runs
  # on battery, suspends under memory pressure) — it was simply missing
  # here until 2026-08.
  zramSwap.enable = true;

  # Set once at first install, never change (see the PC host for details).
  system.stateVersion = "26.05";
}
