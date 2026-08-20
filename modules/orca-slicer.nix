# modules/orca-slicer.nix — the SYSTEM half of OrcaSlicer, and the file that
# owns the app itself. Two things live here, both because only NixOS can set
# them: the firewall holes that let a Bambu Lab printer be discovered on the
# LAN, and the flatpak the slicer is installed from.
#
# ── WHY THIS APP IS A FLATPAK ───────────────────────────────────────────────
# It was the FIRST flatpak in an otherwise Nix-native config, and for a while
# the only one (RustDesk joined it 2026-08-20 — modules/rustdesk.nix — which is
# why the service enable and the update timer now live in modules/flatpak.nix
# instead of down there). The difference between the two is worth keeping
# straight: RustDesk *chooses* flatpak for freshness and could go back to
# nixpkgs in one line. This one has no choice — nixpkgs' orca-slicer physically
# cannot run on this machine. It was tried first (2026-08-11) and aborts ~2s into
# every launch, deterministically, the moment Bambu's proprietary network
# plugin is on disk. The coredump says exactly why:
#
#   #4  malloc_printerr             (libc.so.6)
#   #6  std::locale::_Impl::~_Impl  (.orca-slicer-wrapped)   ← the EXECUTABLE
#   #7  std::locale::~locale        (libstdc++.so.6)         ← the SHARED lib
#   #8  (libbambu_networking_02.03.00.62.so)                 ← Bambu's plugin
#
# The nixpkgs binary both links libstdc++.so.6 (via wxGTK/boost) AND carries a
# statically-linked copy of libstdc++ that it exports — `nm -D` shows 2214
# std:: symbols defined as strong symbols in the executable, including that
# _Impl destructor. The executable is first in the dynamic linker's search
# order, so it preempts. Bambu's plugin then builds a std::locale through one
# copy of the C++ runtime and destroys it through the other, glibc catches the
# bad free, and the process aborts before the main window ever appears. That
# is a build-level ABI defect; no amount of .nix config can fix it from here,
# and the only Nix-side cure is recompiling OrcaSlicer from source on every
# `nix flake update`, on both machines.
#
# The Flathub build (com.orcaslicer.OrcaSlicer, published by OrcaSlicer's lead
# dev) is built inside the Freedesktop SDK against an ordinary shared
# libstdc++, so there is no second C++ runtime to collide with, and it is the
# build essentially every Linux + Bambu user runs. The trade accepted here:
# the slicer's version is no longer pinned by flake.lock. That IS the point.
#
# So: do NOT "tidy up" the odd-one-out flatpak — that reintroduces a slicer
# that cannot start. And if OrcaSlicer ever becomes a working Nix package
# again, deleting it does NOT mean deleting the nix-flatpak flake input any
# more: RustDesk still needs it. Just remove the package line below (the
# mechanism in modules/flatpak.nix stays, and only goes when its LAST consumer
# does).
#
# ── WHY THE FIREWALL HOLES ARE NOT OPTIONAL ─────────────────────────────────
# NixOS's firewall is on by default and this repo otherwise never touches it,
# so out of the box OrcaSlicer simply never sees the printer: no error, no
# entry in the device list, nothing. It is a long-standing nixpkgs issue
# (NixOS/nixpkgs#355821, still open) that trips everyone who installs Bambu
# Studio or OrcaSlicer here. It bites even with a Bambu *cloud* account, which
# is how this machine is set up: when the slicer and the printer are on the
# same network, discovery, file upload and the camera liveview all take the
# direct LAN path rather than going via the cloud. The flatpak changes nothing
# about this — it runs in the HOST network namespace, so the rules still apply
# to it exactly as they did to the Nix build.
#
# Removing OrcaSlicer = delete this file + home/orca-slicer.nix + the three
# import lines (both hosts and home/default.nix). The nix-flatpak input stays
# as long as any flatpak remains.
{ config, lib, pkgs, ... }:

{
  # ── The app ────────────────────────────────────────────────────────────────
  # `packages` comes from the nix-flatpak module (wired into mkHost in
  # flake.nix); plain nixpkgs only offers `enable`. Flathub is already in that
  # module's default remotes, so there is no remote to declare.
  #
  # The service enable and the weekly update timer are NOT here — they are
  # flatpak-wide policy and live in modules/flatpak.nix, which both hosts also
  # import. `packages` is a merging list option, so this definition sits
  # alongside RustDesk's rather than replacing it.
  services.flatpak.packages = [ "com.orcaslicer.OrcaSlicer" ];

  # ── LAN discovery ──────────────────────────────────────────────────────────
  networking.firewall = {
    # The two INBOUND ports Bambu's LAN protocol needs:
    #   2021 — SSDP discovery. The printer announces itself to the multicast
    #          group 239.255.255.250:2021 and the slicer listens there. This
    #          is the one that decides whether the printer shows up at all.
    #   1990 — Bambu's status/report channel.
    # Everything else the X1 Carbon uses is OUTBOUND, which the firewall
    # already allows, so it needs no rule here: TCP 8883/1883 (MQTT control),
    # TCP 990 (implicit FTPS — how sliced files are uploaded), TCP 6000
    # (the LAN liveview camera stream).
    allowedUDPPorts = [ 1990 2021 ];

    # …and opening the ports alone has repeatedly NOT been enough on NixOS,
    # because those discovery packets arrive as multicast rather than as
    # ordinary unicast to this host's address. Accept multicast UDP
    # explicitly. The rule goes into NixOS's own `nixos-fw` chain (jumping to
    # its `nixos-fw-accept` target) rather than raw INPUT: that keeps it
    # inside the managed firewall, so it is created and torn down with it
    # instead of lingering as a stray INPUT rule.
    extraCommands = ''
      iptables -I nixos-fw -p udp -m pkttype --pkt-type multicast -j nixos-fw-accept
    '';
    # The matching delete. Without it, every firewall reload (i.e. every
    # nixos-rebuild switch) would stack another identical copy of the rule.
    extraStopCommands = ''
      iptables -D nixos-fw -p udp -m pkttype --pkt-type multicast -j nixos-fw-accept || true
    '';
    # NOTE: this is iptables syntax, which is correct because nothing in this
    # repo sets `networking.nftables.enable` — NixOS's firewall still runs on
    # the iptables backend. If that ever changes, these two blocks must be
    # rewritten as `extraInputRules`; extraCommands is silently ignored under
    # nftables, and the printer would quietly stop being discovered.
  };
}
