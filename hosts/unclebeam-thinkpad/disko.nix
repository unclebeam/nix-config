# Declarative disk layout for unclebeam-thinkpad, consumed by disko.
#
# Two jobs, one file:
#   1. At INSTALL time, nixos-anywhere runs disko with this spec to wipe,
#      partition, format and mount the disk. THIS DESTROYS THE DISK'S CONTENTS.
#   2. At RUN time, disko generates the fileSystems.* mount entries from the
#      same spec, so hardware-configuration.nix no longer declares them.
#
# Same layout as unclebeam-pc:
# GPT → 512M vfat ESP on /boot → btrfs on the rest with @ and @home subvolumes.
{ ... }:

let
  # ── Target disk ─────────────────────────────────────────────────────────
  # Use the stable /dev/disk/by-id/ path, not /dev/nvme0n1 — kernel device
  # names can change between boots, by-id names never do.
  #
  # How to find it (run on the target machine, e.g. from the installer):
  #   ls -l /dev/disk/by-id/ | grep nvme
  # Pick the disk's  nvme-<model>_<serial>  symlink:
  #   - NOT the nvme-eui.* alias (same disk, opaque name)
  #   - NO -part1/-part2 suffix (those are partitions, we want the whole disk)
  #
  # The 1TB Samsung 9100 PRO in the thinkpad.
  targetDisk = "/dev/disk/by-id/nvme-Samsung_SSD_9100_PRO_1TB_S7YDNJ0Y705788K";
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = targetDisk;
    content = {
      type = "gpt"; # GUID partition table — required for UEFI boot

      partitions = {
        # ── Partition 1: EFI System Partition ──────────────────────────────
        # Where systemd-boot and the kernels live. UEFI firmware can only
        # read FAT, hence vfat.
        ESP = {
          priority = 1; # lay this partition out FIRST on the disk
          size = "512M";
          type = "EF00"; # GPT partition type: EFI System Partition
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # Without these, vfat (which has no Unix permissions) exposes
            # everything as world-writable and NixOS warns about /boot perms.
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };

        # ── Partition 2: btrfs with subvolumes ──────────────────────────────
        # One big btrfs pool; subvolumes carve it into / and /home without
        # fixed sizes, and are cheap to snapshot independently later.
        root = {
          size = "100%"; # everything the ESP didn't take
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # force mkfs even over old FS signatures
            subvolumes = {
              # "@" / "@home" is the common btrfs naming convention;
              # the names are arbitrary, the mountpoints are what matter.
              "@" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" ]; # transparent compression
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
            };
          };
        };
      };
    };
  };
}
