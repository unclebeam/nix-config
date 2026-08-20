# 1Password — desktop app, `op` CLI, and the browser extension.
# NixOS modules, not plain packages: the GUI needs a setgid browser-support
# helper + polkit policy, and the CLI a setgid wrapper so `op` unlocks
# through the running app. home-manager installs would silently lose those.
{ ... }:

{
  programs._1password.enable = true;

  programs._1password-gui = {
    enable = true;
    # Polkit policy: unlock with system authentication instead of retyping
    # the master password.
    polkitPolicyOwners = [ "unclebeam" ];
  };

  # Force-install the extension via managed policy — programs.chromium writes
  # /etc policy every Chromium-family browser reads, so this covers Chrome
  # AND Brave. Merges with modules/chromium-policies.nix; both set
  # `enable = true` on purpose so either file can be removed alone.
  programs.chromium = {
    enable = true;
    # "1Password – Password Manager" (Chrome Web Store ID).
    extensions = [ "aeblfdkhhhdcdjpifhhbdiojplfjncoa" ];
  };
}
