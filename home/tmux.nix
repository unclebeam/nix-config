# home/tmux.nix — tmux + its plain tmux.conf (never Nix-generated). A store
# symlink, not mkOutOfStoreSymlink: tmux never writes into its config dir,
# so read-only is fine and edits go through a rebuild.
#
# Ctrl+h/j/k/l navigation across tmux panes AND nvim splits is two halves
# that must stay in sync: home/tmux/tmux.conf and
# home/nvim/lua/plugins/tmux-navigator.lua.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ tmux ];

  # tmux >= 3.1 reads ~/.config/tmux/tmux.conf natively — no ~/.tmux.conf
  # or wrapper needed.
  xdg.configFile."tmux/tmux.conf".source = ./tmux/tmux.conf;
}
