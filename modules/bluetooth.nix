# bluetooth.nix — the BlueZ userspace stack. Importing this = enabling it.
#
# The kernel side (btusb + the radio, hci0) works without any of this, but
# with no bluetoothd there is nothing to pair against and no bluetoothctl
# on the PATH — the adapter just sits there invisible to userspace.
{ ... }:

{
  # Enables bluetoothd + installs bluez tools (bluetoothctl). Pipewire
  # (modules/audio.nix) picks up Bluetooth audio automatically via
  # wireplumber once bluetoothd is running — no extra wiring needed.
  hardware.bluetooth.enable = true;

  # Power the adapter at boot; without this you'd have to `bluetoothctl
  # power on` after every reboot before anything reconnects.
  hardware.bluetooth.powerOnBoot = true;
}
