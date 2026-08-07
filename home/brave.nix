# home/brave.nix — Brave browser (secondary; the default-browser role —
# web-link handlers + $BROWSER — moved to home/chrome.nix).
# One file per intent: everything that exists because of Brave lives here.
# Removing Brave = delete this file + its import line in default.nix.
# (modules/chromium-policies.nix stays — it governs Chrome too, which is
# why it's no longer named after Brave.)
# (Moved from modules/core.nix when it grew per-user config — same story
# as neovim and claude-code.)
#
# System-side halves that stay elsewhere on purpose:
#  - modules/chromium-policies.nix sets Google as the default search engine
#    via managed policy — /etc is NixOS territory, not home-manager's.
#  - modules/onepassword.nix writes the policy that force-installs the
#    1Password extension — it exists because of 1Password, so it lives there.
#  - Native Wayland comes from NIXOS_OZONE_WL in modules/desktop.nix.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  # Fast-moving; tracks unstable so browser updates aren't gated on the
  # 26.05 branch (same pattern as lazygit/starship/claude-code). Still
  # only moves when `nix flake update` bumps the nixpkgs-unstable pin.
  home.packages = [ pkgs-unstable.brave ];
}
