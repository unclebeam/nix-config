# nix-ld — run prebuilt dynamic binaries that were never packaged for NixOS.
# Importing this module = enabling it (same convention as docker.nix).
#
# Why this exists: normal Linux binaries hardcode their ELF interpreter as
# /lib64/ld-linux-x86-64.so.2 — a path that deliberately does not exist on
# NixOS (every library lives in /nix/store, nothing global). So anything a
# tool downloads at runtime and tries to exec — Prisma's engine binaries
# being the concrete case here ("prisma generate" fetches engines for
# "debian-openssl-3.0.x" and they die with "No such file or directory") —
# fails before main() even runs.
#
# nix-ld installs a small shim AT that hardcoded path. The shim reads
# NIX_LD (the real glibc loader to delegate to) and NIX_LD_LIBRARY_PATH
# (where to resolve shared libraries), both set as session variables by
# this module — which is also why a re-login is needed after first enabling
# it. Nix-built binaries are untouched; they never look at /lib64.
{ config, lib, pkgs, ... }:

{
  programs.nix-ld.enable = true;

  # No `programs.nix-ld.libraries` override: the module's default set
  # already ships openssl, zlib, zstd, stdenv.cc.cc (libstdc++) and friends,
  # which covers Prisma's engines. Only add libraries here when an actual
  # binary complains about a missing .so — never preemptively.
}
