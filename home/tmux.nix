# home/tmux.nix — tmux terminal multiplexer + its plain-file config.
# One file per intent: everything that exists because of tmux lives here
# (plus the paired nvim plugin spec, see below). Removing tmux = delete this
# file, home/tmux/, home/nvim/lua/plugins/tmux-navigator.lua, and the import
# line in default.nix.
#
# The config is a PLAIN tmux.conf symlinked into place (same rule as editor
# configs — never Nix-generated). Unlike the nvim config this is a store
# symlink, not mkOutOfStoreSymlink: tmux never writes into its config dir,
# so read-only is fine and edits go through a rebuild like any module.
#
# Integration note: seamless Ctrl+h/j/k/l navigation across tmux panes AND
# nvim splits is two halves that must stay in sync — the bindings in
# home/tmux/tmux.conf (tmux side) and christoomey/vim-tmux-navigator in
# home/nvim/lua/plugins/tmux-navigator.lua (nvim side).
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ tmux ];

  # tmux >= 3.1 reads ~/.config/tmux/tmux.conf natively — no ~/.tmux.conf
  # or wrapper needed.
  xdg.configFile."tmux/tmux.conf".source = ./tmux/tmux.conf;
}
