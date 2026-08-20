# home/vlc.nix — VLC: audio default and fallback player. The video/*
# defaults live in home/mpv.nix (VLC has no Wayland HDR output). Themed look
# comes from home/qt.nix (VLC is Qt5 — the reason qt.nix carries qt5ct);
# VLC's own settings are app-owned in ~/.config/vlc.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ vlc ];

  # xdg.mimeApps.enable lives in home/default.nix.
  xdg.mimeApps.defaultApplications = {
    "audio/mpeg" = "vlc.desktop";
    "audio/flac" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/x-wav" = "vlc.desktop";
    "audio/mp4" = "vlc.desktop";
  };
}
