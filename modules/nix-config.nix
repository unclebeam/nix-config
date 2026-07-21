# nix-config.nix — self-provision the ~/nix-config checkout.
#
# The repo checkout at ~/nix-config is a load-bearing invariant (see
# CLAUDE.md): every out-of-store symlink hardcodes it — hyprland.lua, the
# whole hypr/dms fragment dir, and the neovim config. On a fresh
# nixos-anywhere install the checkout doesn't exist yet, so all of those
# links dangle and the FIRST login is broken (no compositor config, no DMS
# fragments, configless nvim) until someone remembers to clone. This
# oneshot closes that gap: it clones the repo on the first boot that has
# network, then never runs again.
#
# Failure modes are deliberately soft:
#  * ConditionPathExists means an existing checkout — however it got there
#    — makes the unit a silent no-op forever. It can never touch a repo
#    with local work in it.
#  * No network at boot (laptop before wifi credentials exist) → the clone
#    fails, the unit shows failed, and it simply tries again on the next
#    boot or `nixos-rebuild switch`. Nothing downstream depends on it.
#  * Clones over https anonymously — the repo must be publicly fetchable,
#    which it already has to be for `nixos-anywhere github:…` installs to
#    work. The clone's origin is https; switch it to SSH by hand once keys
#    exist if pushing from that machine.
{ config, lib, pkgs, ... }:

{
  systemd.services.clone-nix-config = {
    description = "Clone ~/nix-config on first boot (out-of-store symlink target)";
    wantedBy = [ "multi-user.target" ];
    # network-online is a *want*, not a require: if NetworkManager can't
    # reach online state the unit should still attempt (and cleanly fail)
    # rather than hang the boot waiting.
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/home/unclebeam/nix-config";
    serviceConfig = {
      Type = "oneshot";
      User = "unclebeam";
    };
    path = [ pkgs.git ];
    script = ''
      git clone https://github.com/unclebeam/nix-config.git /home/unclebeam/nix-config
    '';
  };
}
