# modules/rustdesk.nix — RustDesk, the open-source remote desktop tool,
# installed as a flatpak from Flathub (com.rustdesk.RustDesk).
#
# ── IT IS A CLIENT HERE. IT CANNOT BE A HOST. ───────────────────────────────
# This is the single most important thing about this module: these machines use
# RustDesk to reach OUT and control other devices. Nobody can use it to control
# THEM. That's not a setting we forgot to turn on — there is no working input
# path on this desktop, for two independent reasons, either of which alone would
# be fatal:
#
#   1. niri does not implement `org.gnome.Mutter.RemoteDesktop`. RustDesk's
#      Wayland input injection goes through the RemoteDesktop xdg portal, which
#      modules/niri.nix routes to xdg-desktop-portal-gnome (the only backend
#      that can work here). But that backend is a *front end* to Mutter's D-Bus
#      API, and niri only speaks part of it. Check the binary yourself:
#
#        grep -ao 'org\.gnome\.Mutter\.[A-Za-z]*' $(readlink -f $(command -v niri)) | sort -u
#
#      On niri 26.04 that prints DisplayConfig, ScreenCast and ServiceChannel —
#      capture, yes; remote input, no. Upstream issue niri-wm/niri#390 ("Support
#      the remote desktop portal") is still OPEN, and was filed precisely
#      because RustDesk works on GNOME/KDE and not on niri.
#
#   2. The flatpak sandbox has no /dev/uinput. RustDesk's fallback input path is
#      the kernel's uinput device (which is why the AUR package installs a ROOT
#      systemd service). Flathub's finish-args, verbatim:
#
#        --share=ipc --socket=x11 --share=network
#        --filesystem=home --device=dri --socket=pulseaudio
#
#      No --device=all, so no /dev/uinput inside the sandbox. Even on a
#      compositor with a working RemoteDesktop portal this build would be
#      relying on route 1.
#
# The failure mode if someone tries anyway is quiet and confusing: an incoming
# session may paint a screen (ScreenCast alone can work) with a completely dead
# mouse and keyboard. So if hosting is ever actually wanted, do NOT start by
# poking at this file — re-check whether niri has landed #390, and expect to
# drop the flatpak for the nixpkgs package plus a root uinput service.
#
# ── WHY THERE IS NO FIREWALL BLOCK ──────────────────────────────────────────
# Deliberate, not an oversight. This repo's other network apps sit in modules/
# *because* they need inbound holes (localsend.nix, syncthing.nix,
# orca-slicer.nix). RustDesk's equivalents — TCP 21115-21119 and UDP 21116 for
# LAN direct access — are all INBOUND, i.e. they belong to the hosting path
# above that does not work. Outgoing connections need nothing: NixOS's firewall
# already allows all outbound traffic, and the rendezvous/relay handshake is
# outbound-only. Adding those ports would advertise a capability we don't have.
#
# This module is still in modules/ rather than home/ for a boring reason:
# `services.flatpak.packages` is a NixOS option and home-manager cannot set it.
#
# ── WHY FLATPAK RATHER THAN nixpkgs ─────────────────────────────────────────
# Unlike OrcaSlicer (which physically cannot run from nixpkgs — see
# modules/orca-slicer.nix), this is a judgement call. Both `rustdesk` (1.4.7)
# and `rustdesk-flutter` (1.4.5) build fine on the 26.05 pin; Flathub is simply
# newer (1.4.9) and is upstream's own build, which matters for a tool whose job
# is to interoperate with whatever version the machine at the other end runs.
# The trade: RustDesk's version is no longer pinned by flake.lock. Reverting is
# one line — drop this module's package and add `rustdesk-flutter` to
# core.nix's systemPackages.
#
# ── IT RUNS UNDER XWAYLAND ──────────────────────────────────────────────────
# Note `--socket=x11` and the ABSENCE of `--socket=wayland` in the finish-args
# above: the GUI is an X11 client. That works with no setup — niri 26.04 spawns
# xwayland-satellite on demand (modules/niri.nix) — but on the 4K outputs at
# scale 1.5 expect the window to look soft, the same scaling caveat Steam has.
# That's upstream's manifest, not our config. Don't reflexively "fix" it by
# widening the sandbox; if it ever genuinely must be widened, nix-flatpak does
# expose `services.flatpak.overrides`.
#
# ── NO home/rustdesk.nix, ON PURPOSE ────────────────────────────────────────
# RustDesk's ID and permanent password are machine-local state under
# ~/.config/rustdesk, generated on first run and owned by the app's own UI —
# the same "GUI-owned, never tracked" call already made for DMS settings and
# Syncthing. It also claims no MIME type worth pointing at it. So there is
# nothing for home-manager to manage.
#
# Removing RustDesk = delete this file + its import line in BOTH hosts.
{ config, lib, pkgs, ... }:

{
  # The flatpak service itself (and the weekly update timer) is enabled by
  # modules/flatpak.nix. `packages` is a merging list option, so this line adds
  # to it rather than replacing OrcaSlicer's.
  services.flatpak.packages = [ "com.rustdesk.RustDesk" ];
}
