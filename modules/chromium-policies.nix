# modules/chromium-policies.nix — managed policy: Google as default search
# for the whole Chromium family. A NixOS module because the browsers only
# read managed policy from /etc. programs.chromium installs no browser — it
# writes policy for /etc/brave, /etc/chromium AND /etc/opt/chrome, so this
# governs Brave and Chrome alike. Merges with modules/onepassword.nix's
# programs.chromium; both set `enable = true` on purpose so deleting either
# file alone leaves the other's policies working.
#
# Trade-off: policy values are enforced — the settings UI shows the search
# engine as managed. Changing it means editing this file.
{ ... }:

{
  programs.chromium = {
    enable = true;
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL =
      "https://www.google.com/search?q={searchTerms}";
    defaultSearchProviderSuggestURL =
      "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
    extraOpts.DefaultSearchProviderName = "Google";
  };
}
