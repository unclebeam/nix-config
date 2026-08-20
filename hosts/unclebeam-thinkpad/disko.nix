# Declarative disk layout for unclebeam-thinkpad, consumed by disko.
# At INSTALL time nixos-anywhere runs disko with this spec to wipe, partition,
# format and mount — THIS DESTROYS THE DISK'S CONTENTS. At run time disko
# generates the fileSystems.* mounts from the same spec (so
# hardware-configuration.nix declares none). Same layout as unclebeam-pc.
{ ... }:

let
  # Always the stable /dev/disk/by-id/ path, never /dev/nvme0n1 (kernel names
  # can change between boots). To find it on the target machine:
  #   ls -l /dev/disk/by-id/ | grep nvme
  # → the nvme-<model>_<serial> symlink for the whole disk (not the
  #   nvme-eui.* alias, no -partN suffix).
  # The 1TB Samsung 9100 PRO in the thinkpad.
  targetDisk = "/dev/disk/by-id/nvme-Samsung_SSD_9100_PRO_1TB_S7YDNJ0Y705788K";
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = targetDisk;
    content = {
      type = "gpt";

      partitions = {
        ESP = {
          priority = 1; # first on disk
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # Without these, vfat (no Unix permissions) mounts world-writable
            # and NixOS warns about /boot perms.
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };

        # One btrfs pool; subvolumes carve / and /home without fixed sizes.
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # force mkfs even over old FS signatures
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" ];
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
