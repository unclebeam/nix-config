# ┌─────────────────────────────────────────────────────────────────────────┐
# │ PLACEHOLDER — REPLACE THIS FILE DURING INSTALL                          │
# │                                                                         │
# │ On the machine (from the NixOS installer, disks mounted at /mnt):       │
# │   nixos-generate-config --root /mnt                                     │
# │   cp /mnt/etc/nixos/hardware-configuration.nix \                        │
# │      hosts/unclebeam-pc/hardware-configuration.nix                      │
# │   git add hosts/unclebeam-pc/hardware-configuration.nix                 │
# │                                                                         │
# │ The generated file describes THIS machine's disks, filesystems and      │
# │ kernel modules. It must never be hand-written.                          │
# │                                                                         │
# │ The dummy filesystem below exists only so `nix flake check` can         │
# │ evaluate the config before install (NixOS refuses to evaluate without   │
# │ a root filesystem). The fake disk label cannot boot anything.           │
# └─────────────────────────────────────────────────────────────────────────┘
{ lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/REPLACE-ME-placeholder";
    fsType = "ext4";
  };

  # Printed on every eval/build until this file is replaced — impossible to miss.
  warnings = [
    "hosts/unclebeam-pc/hardware-configuration.nix is a PLACEHOLDER. Run nixos-generate-config on the machine and replace it before installing."
  ];
}
