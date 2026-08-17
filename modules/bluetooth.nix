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

  # powerOnBoot (adapter powered at boot, so devices reconnect without a
  # manual `bluetoothctl power on`) is nixpkgs' DEFAULT — documenting it
  # here rather than restating it. Set `hardware.bluetooth.powerOnBoot =
  # false` if a machine should ever boot radio-off.

  # There is deliberately no pairing GUI here: the DMS shell's
  # bluetooth panel (control center) is the pairing/connection UI, including
  # answering BlueZ agent prompts. Blueman filled that role until 2026-07 —
  # removed as a redundant second GUI (and second tray applet) once the
  # shell covered it.
  # `bluetoothctl` (installed by hardware.bluetooth.enable) remains the CLI
  # fallback for anything the panel can't express.
}
