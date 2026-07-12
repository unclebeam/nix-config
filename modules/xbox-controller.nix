# xbox-controller.nix — driver for the Microsoft Xbox Wireless Adapter
# (USB dongle, 045e:02fe) used by the original Xbox One controller.
# That controller generation has NO Bluetooth — it only speaks Microsoft's
# proprietary RF protocol, and the kernel has no driver for the dongle.
# Without this module the adapter enumerates on USB and then just sits
# there: no input device ever appears.
{ ... }:
{
  # Out-of-tree `xone` kernel module + the dongle firmware (extracted from
  # the Windows driver — this is why the package is unfree; allowUnfree in
  # core.nix covers it). Steam's udev rules (gaming.nix) already grant the
  # user session access to the resulting input device.
  hardware.xone.enable = true;
}
