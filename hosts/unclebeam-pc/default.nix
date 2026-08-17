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
    ../../modules/nix-config.nix # clone ~/nix-config on first boot (out-of-store symlink target)
    ../../modules/desktop.nix    # fonts, Wayland env, GTK portal fallback
    ../../modules/niri.nix       # niri session (back for good 2026-08; hyprland re-trial ended — full replacement)
    ../../modules/dms.nix        # DMS shell, system half (service + fonts + input group; user glue in home/dms.nix)
    ../../modules/dms-greeter.nix # DMS login greeter on greetd (took over from the Noctalia greeter 2026-08)
    ../../modules/kwallet.nix    # session keyring: ksecretd + pam_kwallet unlock (replaced gnome-keyring 2026-07)
    ../../modules/audio.nix      # pipewire
    ../../modules/bluetooth.nix  # bluez userspace for the MT7925's BT radio
    ../../modules/gaming.nix     # steam + gamemode (importing it = enabling it)
    ../../modules/docker.nix     # docker daemon + compose (importing it = enabling it)
    ../../modules/nix-ld.nix     # run prebuilt binaries (Prisma engines etc.)
    ../../modules/onepassword.nix # 1Password app + op CLI + browser extension (Chrome + Brave)
    ../../modules/chromium-policies.nix # managed policy for ALL Chromium-family browsers (Chrome + Brave): Google as default search
    ../../modules/ddc.nix        # DDC/CI brightness for the two external monitors (i2c + ddcutil)
    ../../modules/nautilus.nix   # gvfs + avahi discovery + udisks2 + ntfs/exfat (system half of Nautilus)
    ../../modules/printing.nix   # CUPS + SANE, driverless network printing/scanning
    ../../modules/localsend.nix  # LAN file sharing (AirDrop-style) + firewall port
    ../../modules/syncthing.nix  # continuous file sync between machines (P2P; GUI-owned config)
    ../../modules/orca-slicer.nix # OrcaSlicer (flatpak — the Nix build can't run) + Bambu X1C LAN discovery firewall holes
    ../../modules/solaar.nix     # Logitech mouse/keyboard manager (udev rules + GUI)
    ../../modules/zsa.nix        # ZSA keyboard udev rules (flash via Oryx in browser)
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
  #
  # MT7925 failure #4 — the connect/disconnect loop (fixed 2026-07): the
  # kernel's default regulatory domain is world ("00"), where 6 GHz is
  # transmit-forbidden. Our tri-band mesh AP advertises a 6 GHz radio plus a
  # Thailand country IE; while associated on 5 GHz that IE temporarily
  # unlocks 6 GHz, wpa_supplicant roams toward the "better" 6 GHz BSSID —
  # but the instant it drops the 5 GHz link, the country-IE regdom reverts
  # to world and the kernel refuses the 6 GHz auth ("regulatory prevented
  # using AP config"). ~10 s of outage while it crawls back onto 5 GHz,
  # then the loop repeats (137 drops in 48 h). Pinning the regdom to TH at
  # boot makes 6 GHz persistently legal, so the roam completes instead of
  # flapping. Host-level on purpose: this desktop never leaves Thailand;
  # the ThinkPad travels and should keep the country-IE default.
  #
  # usbcore.autosuspend=-1 — the "keyboard and mouse are dead for 15 s at the
  # login screen" bug (diagnosed 2026-08-09). The greeter draws at ~9.6 s, but
  # the keyboard/mouse evdev nodes only reach logind and the greeter's
  # compositor at ~23.5 s. The chain: USB devices enumerate at ~3.2 s, sit idle,
  # and runtime autosuspend (default delay 2 s) puts them to sleep at ~5.3 s.
  # Their drivers probe at ~6.6 s and must resume them first — and two devices
  # on this desk answer that resume far too slowly, so their control transfers
  # hit the 5 s USB timeout: the Kanto ORA speakers ("cannot get freq at ep
  # 0x2", twice, every boot) and the Insta360 Link 2 Pro ("Failed to query
  # (GET_INFO) UVC control N on unit 5: -110"). udev event processing for the
  # WHOLE PCIe branch holding that USB controller serializes behind those
  # probes, which is why the Intel NIC and the MT7925 also only appeared at
  # 23.8 s — and why on one boot (journal 2026-08-09 14:21) the camera burned
  # 8 × 5 s and input never arrived at all before the machine was rebooted.
  # A negative default delay means devices are never runtime-suspended, so both
  # are still awake when their drivers probe. It has to be a kernel param, not
  # a udev rule setting power/control=on: the param applies at device
  # registration (~3.2 s), while a udev rule would race the probe it's meant to
  # protect. Same failure class — and same cure — as the btusb quirk below.
  # Host-level on purpose: this box is on mains; the ThinkPad runs on battery
  # and should keep autosuspend.
  boot.kernelParams = [ "pcie_aspm=off" "cfg80211.ieee80211_regdom=TH" "usbcore.autosuspend=-1" ];

  # The regdom pin above is only as good as the signed regulatory.db the
  # kernel validates TH against. It's currently present via the general
  # firmware set, but make the dependency explicit so a future firmware
  # cleanup can't silently turn the kernel param into a no-op.
  hardware.wirelessRegulatoryDatabase = true;

  # The MT7925's OTHER power-management failure: with btusb USB autosuspend
  # active (kernel default Y), the BT radio gets power-cycled mid-session and
  # live connections drop — observed here (2026-07) as the Xbox controller
  # binding fine (xpadneo "gamepad detected") and then disconnecting ~30s
  # later, in a loop, across two controller firmware versions and a clean
  # re-pair. Desktop box: autosuspend on the radio saves nothing worth having.
  # The Kanto ORA speakers (USB 8888:17b6) don't support reading back their
  # current sample rate: snd-usb-audio asks anyway during probe and eats a 5 s
  # USB timeout per endpoint — "usb 1-5.1.1: 1:1: cannot get freq at ep 0x2",
  # twice, on every single boot. That is the larger half of the login-screen
  # input stall documented on boot.kernelParams above, so belt-and-braces with
  # usbcore.autosuspend=-1: that keeps the speakers awake, this stops the
  # pointless question being asked at all (in case they're slow to answer even
  # when never suspended). GET_SAMPLE_RATE is the stock upstream quirk for this
  # exact symptom — Plantronics DA45/BT600, Microdia JP001 and friends carry it
  # hardcoded in sound/usb/quirks.c; ours just isn't in the kernel's list.
  #
  # quirk_flags is a string array parsed as VID:PID:flags, so this is scoped to
  # the Kanto by ID and cannot touch the other two USB audio devices on this
  # machine (the Insta360's mic and the ASUS front-panel DAC). Verify the kernel
  # still takes strings — not the old per-card int array — before editing:
  # `cat /sys/module/snd_usb_audio/parameters/quirk_flags` must print "(null)"
  # slots, not numbers.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
    options snd-usb-audio quirk_flags=8888:17b6:GET_SAMPLE_RATE
  '';

  # MT7925 power-management failure #3: with WiFi power-save on (the driver
  # default), the radio dozes between beacons and mt76 chips are known to
  # miss/delay EAPOL frames — seen here (2026-07) as 4-way handshake timeouts
  # (deauth reason 15) and mid-session drops, which in turn made
  # NetworkManager decide the stored PSK was wrong and re-prompt for the
  # password. A desktop on mains has nothing to gain from radio power-save,
  # so force it off. (Host-level on purpose: the ThinkPad on battery should
  # keep its default.)
  #
  # MT7925 failure #5 — the cold-boot variant of the same handshake timeout
  # (reason 15 ~4s after firmware load, while the regdom/channel list is
  # still churning; powersave-off doesn't cover it, and pre-login there is
  # no secret agent, so NM's "wrong password" misread became a shell
  # password prompt on ~3 of 5 boots, 2026-07). Handled by switching the wifi
  # supplicant to iwd — which retries handshakes internally instead of
  # reporting bad-password — in modules/core.nix (wifi.backend = "iwd").
  networking.networkmanager.wifi.powersave = false;

  # The disk layout (disko.nix) has no swap partition. Instead, use zram:
  # a compressed block device in RAM used as swap. Cheap insurance against
  # memory pressure with no disk wear and nothing to partition.
  zramSwap.enable = true;

  # Version of NixOS this machine was FIRST installed with. It gates stateful
  # migration defaults — set once, then never change it, even on upgrades.
  system.stateVersion = "26.05";
}
