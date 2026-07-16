# home/ark.nix — Ark (KDE's archive manager) + the CLI backends it needs.
# One file per intent: everything that exists because of archive handling
# (.zip / .7z / .rar extraction) lives here. Removing it = delete this file
# + its import line in default.nix. (It replaced File Roller when the file
# manager went back to KDE — Ark is what wires Dolphin's Extract/Compress
# context-menu entries.)
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # zip and tar formats come built-in (libarchive/libzip), but Ark handles
    # 7z and RAR by exec'ing external binaries found on PATH at runtime
    # (it knows the `7zz` binary name) — without the two packages below
    # those formats silently fail to open.
    kdePackages.ark

    # 7-Zip's official CLI (`7zz`), the -rar variant built with the unfree
    # RAR codec (covered by allowUnfree in modules/core.nix). Backend for
    # Ark's .7z support, and a standalone terminal tool:
    #   7zz x file.7z / file.zip / file.rar
    _7zz-rar

    # RarLab's unrar (unfree) — full RAR5 + passworded-archive support for
    # Ark's rar backend. CLI: `unrar x file.rar`.
    unrar
  ];

  # Make double-clicking an archive in Dolphin open Ark. Merges with the
  # inode/directory default in dolphin.nix (mimeApps is enabled there).
  xdg.mimeApps.defaultApplications = {
    "application/zip" = "org.kde.ark.desktop";
    "application/vnd.rar" = "org.kde.ark.desktop";
    "application/x-7z-compressed" = "org.kde.ark.desktop";
  };
}
