# home/file-roller.nix — File Roller (GNOME's archive manager) + the CLI
# backends it needs. One file per intent: everything that exists because of
# archive handling (.zip / .7z / .rar extraction) lives here. Removing it =
# delete this file + its import line in default.nix. (It replaced Ark when
# the KDE stack was removed.)
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # zip and tar formats come built-in (libarchive), but like Ark before
    # it, File Roller handles 7z and RAR by exec'ing external binaries found
    # on PATH at runtime — without the two packages below those formats
    # silently fail to open.
    file-roller

    # 7-Zip's official CLI (`7zz`), the -rar variant built with the unfree
    # RAR codec (covered by allowUnfree in modules/core.nix). Backend for
    # File Roller's .7z support, and a standalone terminal tool:
    #   7zz x file.7z / file.zip / file.rar
    _7zz-rar

    # RarLab's unrar (unfree) — full RAR5 + passworded-archive support for
    # File Roller's rar backend. CLI: `unrar x file.rar`.
    unrar
  ];

  # Make double-clicking an archive in Nautilus open File Roller. Merges with
  # the inode/directory default in nautilus.nix (mimeApps is enabled there).
  xdg.mimeApps.defaultApplications = {
    "application/zip" = "org.gnome.FileRoller.desktop";
    "application/vnd.rar" = "org.gnome.FileRoller.desktop";
    "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
  };
}
