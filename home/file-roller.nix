# home/file-roller.nix — File Roller (archive manager) + the CLI backends it
# needs. Nautilus carries its own Extract/Compress context entries via
# gnome-autoar; File Roller is the double-click handler and the fallback for
# passworded/exotic archives.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # zip/tar come built-in (libarchive); 7z and RAR are handled by exec'ing
    # external binaries found on PATH at runtime — without the two packages
    # below those formats silently fail to open.
    file-roller

    # 7-Zip CLI (`7zz`), the -rar variant with the unfree RAR codec.
    _7zz-rar

    # RarLab's unrar (unfree) — full RAR5 + passworded archives.
    unrar
  ];

  # xdg.mimeApps.enable lives in home/default.nix.
  xdg.mimeApps.defaultApplications = {
    "application/zip" = "org.gnome.FileRoller.desktop";
    "application/vnd.rar" = "org.gnome.FileRoller.desktop";
    "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
  };
}
