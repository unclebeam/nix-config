# home/ark.nix — Ark (KDE's archive manager) + the CLI backends it needs.
# One file per intent: everything that exists because of archive handling
# (.zip / .7z / .rar extraction) lives here. Removing it = delete this file
# + its import line in default.nix.
#
# Ark integrates with Dolphin two ways, both "free" given our existing setup:
#   - right-click → Extract/Compress: Ark ships a KFileItemAction plugin that
#     Dolphin discovers via the Qt plugin paths exported by qt.enable = true
#     (home/dolphin.nix).
#   - double-click an archive: the xdg default apps registered below.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # In current nixpkgs Ark is built with libarchive + libzip only, so zip
    # and tar work out of the box — but 7z and RAR are handled by cli plugins
    # that exec external binaries found on PATH at runtime. Without the two
    # packages below, Ark silently greys out those formats.
    kdePackages.ark

    # 7-Zip's official CLI (`7zz`), the -rar variant built with the unfree
    # RAR codec (covered by allowUnfree in modules/core.nix). Backend for
    # Ark's .7z support, and a standalone terminal tool:
    #   7zz x file.7z / file.zip / file.rar
    _7zz-rar

    # RarLab's unrar (unfree). Ark's dedicated rar plugin prefers it over
    # 7zz — full RAR5 + passworded-archive support. CLI: `unrar x file.rar`.
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
