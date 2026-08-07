# modules/chromium-policies.nix — managed browser policy making Google the
# default search engine for the WHOLE Chromium family. (Renamed from
# brave.nix 2026-08: programs.chromium writes /etc/brave, /etc/chromium,
# AND /etc/opt/chrome, so this file was always configuring Chrome — the
# default browser — too, and the old name hid that. Brave itself lives in
# home/brave.nix; Chrome — which owns the xdg default-browser handlers —
# in home/chrome.nix; the 1Password extension policy lives in
# modules/onepassword.nix because it exists for 1Password.)
#
# Why a NixOS module and not home-manager: Chromium-family browsers on
# Linux only read managed policy from /etc, and /etc is NixOS territory.
# programs.chromium installs no browser — it only writes policy files for
# the WHOLE family (/etc/brave, /etc/chromium, /etc/opt/chrome), so this
# search policy and onepassword.nix's extension policy govern Brave AND
# Chrome alike. This block merges with onepassword.nix's programs.chromium
# — both files set `enable = true` ON PURPOSE, so deleting either one
# alone leaves the other's policies fully working (atomic removal).
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
