# unclebeam-pc — AMD Ryzen 9 desktop with an AMD RDNA GPU. Primary gaming box.
# Hosts stay thin: hostname, hardware quirks, and which shared modules to use.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # machine-generated; filesystems live in disko.nix
    ./disko.nix                  # declarative disk layout (partitions, btrfs, mounts)
    ../../modules/core.nix       # users, nix settings, boot loader, networking…
    ../../modules/nix-config.nix # clone ~/nix-config on first boot (out-of-store symlink target)
    ../../modules/desktop.nix    # fonts, Wayland env, GTK portal fallback
    ../../modules/niri.nix       # niri session, system half
    ../../modules/dms.nix        # DMS shell, system half (user glue in home/dms.nix)
    ../../modules/dms-greeter.nix # DMS login greeter on greetd
    ../../modules/gnome-keyring.nix # gnome-keyring + PAM unlock on greetd + seahorse
    ../../modules/audio.nix      # pipewire
    ../../modules/bluetooth.nix  # bluez userspace for the MT7925's BT radio
    ../../modules/gaming.nix     # steam + gamemode (importing it = enabling it)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + browser extension (Chrome + Brave)
    ../../modules/chromium-policies.nix # managed policy for all Chromium-family browsers
    ../../modules/ddc.nix        # DDC/CI brightness for the external monitors (i2c + ddcutil)
    ../../modules/nautilus.nix   # gvfs + avahi discovery + udisks2 + ntfs/exfat (system half of Nautilus)
    ../../modules/printing.nix   # CUPS + SANE, driverless network printing/scanning
    ../../modules/localsend.nix  # LAN file sharing + firewall port
    ../../modules/syncthing.nix  # continuous file sync between machines (P2P; GUI-owned config)
    ../../modules/flatpak.nix    # flatpak service + weekly update timer
    ../../modules/orca-slicer.nix # OrcaSlicer flatpak + Bambu X1C LAN discovery firewall holes
    ../../modules/rustdesk.nix   # RustDesk flatpak (client only; niri can't be hosted)
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
  ];

  # Must match the attribute name in flake.nix (bare `--flake .` lookup).
  networking.hostName = "unclebeam-pc";

  # In-kernel amdgpu + Mesa (radeonsi/RADV); no proprietary blobs.
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit GL/Vulkan for Steam/Proton
  };

  hardware.cpu.amd.updateMicrocode = true;

  # pcie_aspm=off — the MT7925 WiFi/BT chip fails to probe ("driver own
  # failed", error -5) when ASPM's low-power state races the MCU handshake;
  # next escalation if it recurs: add "pcie_port_pm=off".
  # cfg80211.ieee80211_regdom=TH — the world regdom forbids 6 GHz transmit, so
  # roaming toward the mesh AP's 6 GHz BSSID flapped in a connect/disconnect
  # loop. Host-level on purpose: this desktop never leaves Thailand; the
  # ThinkPad travels and keeps the country-IE default.
  # usbcore.autosuspend=-1 — two slow-to-resume USB devices (Kanto ORA
  # speakers, Insta360 Link) eat 5 s resume timeouts that serialize udev for
  # the whole PCIe branch, leaving keyboard/mouse dead at the login screen.
  # Must be a kernel param, not a udev power/control rule — udev would race
  # the probe it protects. Host-level: this box is on mains; the ThinkPad
  # keeps autosuspend for battery.
  boot.kernelParams = [ "pcie_aspm=off" "cfg80211.ieee80211_regdom=TH" "usbcore.autosuspend=-1" ];

  # The TH regdom pin needs the signed regulatory.db present — explicit so a
  # firmware cleanup can't silently turn the kernel param into a no-op.
  hardware.wirelessRegulatoryDatabase = true;

  # btusb autosuspend power-cycles the MT7925 BT radio mid-session (Xbox
  # controller drops every ~30 s).
  # The Kanto speakers (8888:17b6) can't report their sample rate; without the
  # stock GET_SAMPLE_RATE quirk, snd-usb-audio eats a 5 s timeout per endpoint
  # on every boot (part of the login-screen input stall above). quirk_flags is
  # parsed as VID:PID:flags strings, so this is scoped to the Kanto only.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
    options snd-usb-audio quirk_flags=8888:17b6:GET_SAMPLE_RATE
  '';

  # mt76 chips miss EAPOL frames in WiFi power-save → handshake timeouts and
  # NetworkManager misreading the PSK as wrong. Host-level on purpose: the
  # ThinkPad on battery keeps its default. (Cold-boot variant of the same
  # timeout is handled by wifi.backend = "iwd" in modules/core.nix.)
  networking.networkmanager.wifi.powersave = false;

  # No swap partition in disko.nix; zram covers memory pressure instead.
  zramSwap.enable = true;

  # Set once at install; never change, even on upgrades.
  system.stateVersion = "26.05";
}
