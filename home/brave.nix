# home/brave.nix — Brave, the secondary browser (default-browser role lives
# in home/chrome.nix). Search policy: modules/chromium-policies.nix;
# 1Password extension: modules/onepassword.nix; Wayland: NIXOS_OZONE_WL.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  # Fast-moving; tracks unstable (moves only when `nix flake update` bumps
  # the pin).
  home.packages = [ pkgs-unstable.brave ];
}
