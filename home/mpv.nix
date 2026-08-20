# home/mpv.nix — mpv, the video player and default video handler. Brought in
# as the HDR-capable player (VLC can't speak wp_color_management_v1); HDR is
# parked until niri ships color management (then re-add
# target-colorspace-hint = "yes" below), but mpv stays the better player:
# gpu-next rendering, VA-API 10-bit decode.
{ config, lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      # gpu-next (libplacebo) — best scaling/tonemapping and the only vo that
      # can hint colorspaces to the compositor once CM exists; Vulkan Wayland
      # context to match.
      vo = "gpu-next";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
      # AMD VA-API decode via mesa. auto-safe = whitelisted methods only,
      # clean fallback to software rather than artifacts.
      hwdec = "auto-safe";
    };
  };

  # Video only — audio stays with VLC. xdg.mimeApps.enable lives in
  # home/default.nix.
  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
  };
}
