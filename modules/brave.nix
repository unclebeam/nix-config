# modules/brave.nix — the system half of Brave: managed browser policy
# making Google the default search engine. (The app itself + xdg default-
# browser handlers live in home/brave.nix; the 1Password extension policy
# lives in modules/onepassword.nix because it exists for 1Password.)
#
# Why a NixOS module and not home-manager: Chromium-family browsers on
# Linux only read managed policy from /etc (Brave reads
# /etc/brave/policies/managed/), and /etc is NixOS territory.
# programs.chromium installs no browser — it only writes those policy
# files. This block merges with onepassword.nix's programs.chromium.
#
# Trade-off: policy-set values are enforced — Brave's settings UI shows
# the search engine as managed and won't let a profile override it.
# Changing search engines means editing this file, not the UI.
{ ... }:

{
  programs.chromium = {
    enable = true;
    # Replace Brave's built-in default (Brave Search) with Google.
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL =
      "https://www.google.com/search?q={searchTerms}";
    # Address-bar suggestions as you type.
    defaultSearchProviderSuggestURL =
      "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
    # Display name shown in the search-engine settings list.
    extraOpts.DefaultSearchProviderName = "Google";
  };
}
