# home/vlc.nix — VLC media player + default handler for audio files.
# One file per intent: everything that exists because of VLC lives here.
# Removing VLC = delete this file + its import line in default.nix.
#
# VLC used to own the video/* defaults too; those moved to home/mpv.nix
# because VLC has no Wayland HDR output (no wp_color_management_v1) and
# HDR movies played in it get crushed to SDR. VLC stays as the audio
# default and a fallback player.
#
# No system-side (modules/) half and no theming block here: VLC is Qt-based
# and gets its Breeze look from the shared home/qt.nix (alongside Dolphin
# and Ark — VLC is Qt5, so it's the reason qt.nix carries the .qt5 style
# variant). VLC's own settings live in ~/.config/vlc, managed by the app
# itself, not Nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ vlc ];

  # Make double-clicking an audio file in Dolphin open VLC. Merges with the
  # inode/directory + archive defaults already registered (xdg.mimeApps is
  # enabled in home/dolphin.nix; don't re-set enable here). VLC's desktop id
  # is `vlc.desktop`. Video defaults live in home/mpv.nix (HDR — see header).
  xdg.mimeApps.defaultApplications = {
    "audio/mpeg" = "vlc.desktop";
    "audio/flac" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/x-wav" = "vlc.desktop";
    "audio/mp4" = "vlc.desktop";
  };
}
