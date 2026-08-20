# bluetooth.nix — BlueZ userspace. Importing this = enabling it; without
# bluetoothd the adapter is invisible to userspace.
{ ... }:

{
  # bluetoothd + bluez tools. PipeWire picks up BT audio automatically via
  # wireplumber. powerOnBoot is nixpkgs' default (adapter powered at boot).
  hardware.bluetooth.enable = true;

  # No pairing GUI on purpose: DMS's bluetooth panel is the pairing UI,
  # including BlueZ agent prompts; bluetoothctl is the CLI fallback.
}
