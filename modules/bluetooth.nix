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

  # Blueman: the GTK pairing/connection GUI (blueman-manager) + tray applet.
  # Lives here rather than in home/ for the same reason pavucontrol lives in
  # audio.nix: it only makes sense alongside this stack, so removing this
  # module removes the GUI atomically. This installs the binaries and the
  # D-Bus-activated blueman-mechanism service (the privileged half the GUI
  # talks to). The tray applet autostarts by itself: the package ships an XDG
  # autostart entry that systemd's xdg-autostart-generator turns into
  # app-blueman@autostart.service in the niri session. Do NOT also add a
  # home-manager blueman-applet service — two instances race for the
  # org.blueman.Applet D-Bus name and the loser dies at login (seen 2026-07).
  services.blueman.enable = true;
}
