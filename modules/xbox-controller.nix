# xbox-controller.nix — Xbox controllers, both connection paths:
#
#  1. The Microsoft Xbox Wireless Adapter (USB dongle, 045e:02fe) used by the
#     original Xbox One controller. That generation has NO Bluetooth — it only
#     speaks Microsoft's proprietary RF protocol, and the kernel has no driver
#     for the dongle. Without xone the adapter enumerates on USB and then just
#     sits there: no input device ever appears.
#  2. Bluetooth-capable controllers (Xbox One S and later). Firmware 5.x+
#     switched these to Bluetooth LOW ENERGY (HID-over-GATT): bluetoothd does
#     the HID work in userspace and creates the input device through the
#     `uhid` kernel module; xpadneo then binds to it for correct button
#     mapping, trigger rumble, and battery reporting (in-kernel hid-microsoft
#     is only a basic fallback).
#
# PLAYBOOK, verified against the journal + xpadneo docs (2026-07):
#
#  - Controller firmware matters: xpadneo warns at bind time ("BLE firmware
#    version 5.09, please upgrade for better stability") — anything but the
#    latest firmware (Xbox Accessories app on Windows/Xbox) is known-unstable
#    over BLE.
#  - After ANY controller firmware upgrade: `bluetoothctl remove <MAC>`,
#    REBOOT, then re-pair (xpadneo TROUBLESHOOTING.md requires the full
#    sequence). A stale pre-upgrade bond shows up as "Failed to add device
#    … (0x03)" at boot and GATT "unlikely error" bursts in bluetoothd's log.
#  - `bluetoothctl trust <MAC>` after pairing is mandatory: bluetoothd
#    refuses reconnections from untrusted devices, which looks exactly like
#    a connect/disconnect loop.
#  - A few GATT error bursts in the first seconds after a fresh pair are
#    NORMAL (the controller retries while BlueZ re-populates its GATT db) —
#    judge success by /dev/input/js0 appearing and the light going solid,
#    not by a spotless journal.
#  - Don't add `Privacy = device` — it's forum folklore, not in xpadneo's
#    docs.
#  - If it binds fine and then drops seconds later in a loop, suspect the
#    ADAPTER's power management, not this config — that was the MT7925 story
#    on unclebeam-pc (btusb autosuspend, disabled in that host's file).
{ ... }:
{
  # Out-of-tree `xone` kernel module + the dongle firmware (extracted from
  # the Windows driver — this is why the package is unfree; allowUnfree in
  # core.nix covers it). Steam's udev rules (gaming.nix) already grant the
  # user session access to the resulting input device.
  hardware.xone.enable = true;

  # Out-of-tree `hid_xpadneo` module for Bluetooth controllers. Also flips
  # hardware.bluetooth.enable on by itself (harmless overlap with
  # modules/bluetooth.nix), and knows NOT to disable ERTM on kernels ≥5.12
  # (disabling it there crashes the controller firmware during rumble).
  hardware.xpadneo.enable = true;

  # xpadneo's documented main.conf recommendations (docs/TROUBLESHOOTING.md).
  # These land in the controller's file, not bluetooth.nix, because they only
  # exist for its sake — remove this module, lose them atomically.
  hardware.bluetooth.settings = {
    General = {
      # BLE-firmware controllers need the LE side; "dual" (classic + LE) is
      # BlueZ's default, pinned here so a future main.conf tweak can't silently
      # break controller pairing.
      ControllerMode = "dual";
      # A controller previously bonded to another host (a console, Windows)
      # re-pairs without proper cryptographic re-authentication ("just works").
      # BlueZ's default "never" silently rejects that; "confirm" asks the
      # pairing agent (Blueman) instead. Deliberately not "always".
      # CAUTION: "confirm" only works with a notification daemon that renders
      # action buttons — Blueman asks via a Confirm/Deny notification and
      # declined to add a dialog fallback (blueman#2477). mako silently broke
      # this (no buttons, mako#588) and pairing stalled until timeout; the
      # DMS shell's notifications render action buttons (as swaync did
      # before the DMS migration), keeping it answerable.
      JustWorksRepairing = "confirm";
    };
    LE = {
      # The controller's protocol runs at 100 Hz internally; BlueZ's default
      # LE connection interval is slower, which xpadneo's docs blame for
      # laggy/choppy input and lost button presses. 7–9 units = 8.75–11.25 ms.
      # Caveat from the same doc: BlueZ upstream discourages pinning this
      # because it applies to ALL BLE devices on the machine — acceptable
      # here, the controller is the only latency-critical BLE device around.
      MinConnectionInterval = 7;
      MaxConnectionInterval = 9;
      ConnectionLatency = 0;
    };
  };
}
