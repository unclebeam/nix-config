# home/brave.nix — Brave browser + default handler for web links.
# One file per intent: everything that exists because of Brave lives here.
# Removing Brave = delete this file + its import line in default.nix
# (plus the system half, modules/brave.nix, and its host import lines).
# (Moved from modules/core.nix when it grew per-user config — same story
# as neovim and claude-code.)
#
# System-side halves that stay elsewhere on purpose:
#  - modules/brave.nix sets Google as the default search engine via managed
#    policy — /etc is NixOS territory, not home-manager's.
#  - modules/onepassword.nix writes the policy that force-installs the
#    1Password extension — it exists because of 1Password, so it lives there.
#  - Native Wayland comes from NIXOS_OZONE_WL in modules/desktop.nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ brave ];

  # Register Brave as the default browser: clicking a link anywhere
  # (Slack, Obsidian, terminal xdg-open) opens Brave. Merges with the
  # dolphin/vlc/ark defaults (xdg.mimeApps is enabled in home/dolphin.nix;
  # don't re-set enable here). Brave's desktop id is `brave-browser.desktop`
  # — NOT `com.brave.Browser.desktop`, which is a hidden (NoDisplay)
  # Flatpak-ID alias shipped alongside it.
  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "application/xhtml+xml" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
  };

  # For CLI tools that read $BROWSER instead of asking xdg-open
  # (same pattern as EDITOR in home/neovim.nix).
  home.sessionVariables.BROWSER = "brave";
}
