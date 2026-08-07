# home/chrome.nix — Google Chrome + default handler for web links.
# One file per intent: everything that exists because of Chrome lives here.
# Removing Chrome = delete this file + its import line in default.nix
# (and hand the default-browser role back to another browser's file —
# exactly one file may own the mime handlers and $BROWSER).
#
# System-side halves that come for free (no new module needed):
#  - programs.chromium (modules/chromium-policies.nix + modules/onepassword.nix) writes
#    managed policy for the whole Chromium family, including Chrome's
#    /etc/opt/chrome/policies/managed/ — so the Google-search policy and
#    the force-installed 1Password extension apply here too.
#  - Native Wayland comes from NIXOS_OZONE_WL in modules/desktop.nix.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  # Fast-moving; tracks unstable so browser updates aren't gated on the
  # 26.05 branch (same pattern as brave/lazygit/claude-code). Still
  # only moves when `nix flake update` bumps the nixpkgs-unstable pin.
  home.packages = [ pkgs-unstable.google-chrome ];

  # Register Chrome as the default browser: clicking a link anywhere
  # (Slack, Obsidian, terminal xdg-open) opens Chrome. Merges with the
  # dolphin/vlc/ark defaults (xdg.mimeApps is enabled in home/default.nix;
  # don't re-set enable here). Chrome's desktop id is `google-chrome.desktop`
  # — NOT `com.google.Chrome.desktop`, the reverse-DNS alias shipped
  # alongside it (same trap as Brave's com.brave.Browser.desktop).
  xdg.mimeApps.defaultApplications = {
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };

  # For CLI tools that read $BROWSER instead of asking xdg-open
  # (same pattern as EDITOR in home/neovim.nix).
  home.sessionVariables.BROWSER = "google-chrome-stable";
}
