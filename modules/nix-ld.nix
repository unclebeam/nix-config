# nix-ld — run prebuilt dynamic binaries never packaged for NixOS (turbo,
# SWC, bcrypt prebuilds, uv-downloaded Pythons). Normal binaries hardcode
# /lib64/ld-linux-x86-64.so.2, which doesn't exist on NixOS; nix-ld installs
# a shim there that delegates via NIX_LD/NIX_LD_LIBRARY_PATH (session vars —
# hence a re-login after first enabling). Nix-built binaries are untouched.
# Importing this module = enabling it.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.nix-ld.enable = true;
  # Extends the module's default set. Only add a library when an actual
  # binary complains about a missing .so — never preemptively.
  programs.nix-ld.libraries = with pkgs; [
    openssl
    vips
  ];

  environment.variables = {
    # The one thing nix-ld can't fix: Prisma sees ID=nixos in /etc/os-release
    # and downloads engines for a "linux-nixos" target that doesn't exist
    # (404). Point it at nixpkgs' build; Prisma 7's only native engine is
    # schema-engine (query engine is WASM).
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
    # Turbo strict env mode would strip the var above from task envs; loose
    # lets it through. Cache hashing still uses only turbo.json-declared vars.
    TURBO_ENV_MODE = "loose";
  };
}
