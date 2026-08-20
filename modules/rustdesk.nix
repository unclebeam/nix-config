# modules/rustdesk.nix — RustDesk as a flatpak from Flathub.
#
# CLIENT ONLY — these machines reach out; nobody can control THEM. Two
# independent reasons, either fatal: (1) niri doesn't implement
# org.gnome.Mutter.RemoteDesktop, which the gnome portal's input injection
# fronts (upstream niri-wm/niri#390, open); (2) the flatpak sandbox has no
# /dev/uinput (no --device=all in Flathub's finish-args), killing the fallback
# input path. Failure mode if someone tries: a session may paint a screen
# (ScreenCast works) with dead mouse/keyboard. If hosting is ever wanted,
# re-check #390 first and expect to swap to the nixpkgs package + root uinput
# service — don't start here.
#
# No firewall block on purpose: RustDesk's LAN ports are all INBOUND, i.e.
# the hosting path that doesn't work; the rendezvous/relay handshake is
# outbound-only. Opening them would advertise a capability we don't have.
#
# Flatpak by choice (unlike OrcaSlicer's necessity): nixpkgs builds fine,
# Flathub is just newer and upstream's own build — which matters for a tool
# interoperating with whatever the other end runs. Revert = drop this package,
# add rustdesk-flutter to core.nix.
#
# Runs under XWayland (--socket=x11, no wayland socket in the manifest): soft
# at scale 1.5, same caveat as Steam. Upstream's manifest — don't widen the
# sandbox to fix it.
#
# No home/rustdesk.nix: ID + permanent password are machine-local GUI-owned
# state, same call as DMS settings and Syncthing. In modules/ because
# services.flatpak.packages is a NixOS option home-manager can't set.
# Removing RustDesk = this file + its import line in both hosts.
{ config, lib, pkgs, ... }:

{
  # Service enable + update timer live in modules/flatpak.nix. Merging list
  # option — adds alongside OrcaSlicer's.
  services.flatpak.packages = [ "com.rustdesk.RustDesk" ];
}
