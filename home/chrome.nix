# home/chrome.nix — Google Chrome + default handler for web links. Exactly
# one browser file may own the mime handlers and $BROWSER. Managed policy
# (search, 1Password extension) comes from modules/chromium-policies.nix +
# modules/onepassword.nix; native Wayland from NIXOS_OZONE_WL.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  # Fast-moving; tracks unstable (moves only when `nix flake update` bumps
  # the pin).
  home.packages = [ pkgs-unstable.google-chrome ];

  # Default browser: links anywhere open Chrome. The desktop id is
  # `google-chrome.desktop` — NOT the reverse-DNS com.google.Chrome.desktop
  # alias shipped alongside it. xdg.mimeApps.enable lives in
  # home/default.nix.
  xdg.mimeApps.defaultApplications = {
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };

  # For CLI tools that read $BROWSER instead of asking xdg-open.
  home.sessionVariables.BROWSER = "google-chrome-stable";
}
