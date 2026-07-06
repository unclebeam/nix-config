# home/vlc.nix — VLC media player + default handler for video/audio files.
# One file per intent: everything that exists because of VLC lives here.
# Removing VLC = delete this file + its import line in default.nix.
#
# No system-side (modules/) half and no Qt block here: VLC is Qt-based and
# inherits the session-wide breeze theming exported by home/dolphin.nix
# (qt.enable = true). VLC's own settings live in ~/.config/vlc, managed by
# the app itself, not Nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ vlc ];

  # Make double-clicking a media file in Dolphin open VLC. Merges with the
  # inode/directory + archive defaults already registered (xdg.mimeApps is
  # enabled in home/dolphin.nix; don't re-set enable here). VLC's desktop id
  # is `vlc.desktop`.
  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/webm" = "vlc.desktop";
    "video/quicktime" = "vlc.desktop";
    "video/x-msvideo" = "vlc.desktop";
    "audio/mpeg" = "vlc.desktop";
    "audio/flac" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/x-wav" = "vlc.desktop";
    "audio/mp4" = "vlc.desktop";
  };
}
