# nix-ld — run prebuilt dynamic binaries that were never packaged for NixOS.
# Importing this module = enabling it (same convention as docker.nix).
#
# Why this exists: normal Linux binaries hardcode their ELF interpreter as
# /lib64/ld-linux-x86-64.so.2 — a path that deliberately does not exist on
# NixOS (every library lives in /nix/store, nothing global). So anything a
# tool downloads at runtime and tries to exec — turbo's prebuilt binary,
# Next.js's SWC, bcrypt's N-API prebuilds being the concrete cases here —
# fails before main() even runs.
#
# nix-ld installs a small shim AT that hardcoded path. The shim reads
# NIX_LD (the real glibc loader to delegate to) and NIX_LD_LIBRARY_PATH
# (where to resolve shared libraries), both set as session variables by
# this module — which is also why a re-login is needed after first enabling
# it. Nix-built binaries are untouched; they never look at /lib64.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.nix-ld.enable = true;
  # Extends the module's default set (zlib, zstd, stdenv.cc.cc and friends).
  # Only add libraries here when an actual binary complains about a missing
  # .so — never preemptively.
  programs.nix-ld.libraries = with pkgs; [
    openssl
    vips
  ];

  environment.variables = {
    # The one thing nix-ld can't fix: Prisma reads /etc/os-release, sees
    # ID=nixos, and downloads engines for a "linux-nixos" target that
    # binaries.prisma.sh doesn't host (404) — it never gets to exec'ing
    # anything. Point it at nixpkgs' build instead. Prisma 7 only has one
    # native engine left (schema-engine); the query engine is WASM.
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    # Turbo 2 strict env mode strips undeclared vars (incl. the one above)
    # from task envs; loose mode lets them through. Cache hashing still only
    # uses turbo.json-declared vars, so caching is unaffected.
    TURBO_ENV_MODE = "loose";
  };
}
