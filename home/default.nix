# home/default.nix — home-manager entrypoint, shared by BOTH hosts
# (imported from flake.nix as home-manager.users.unclebeam).
# Same user environment, same look, on every machine.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./niri.nix      # niri glue: symlinks niri/config.kdl + swaylock + swayidle
    ./waybar.nix    # status bar
    ./fuzzel.nix    # launcher
    ./mako.nix      # notifications
    ./satty.nix     # screenshot annotator (run by hand on saved screenshots)
    ./alacritty.nix # terminal
    ./fish.nix      # shell + prompt
    ./direnv.nix    # per-directory envs (project dev shells via .envrc)
    ./helix.nix     # editor + language servers
    ./zellij.nix    # terminal multiplexer
    ./cursor.nix    # mouse cursor theme + size (HiDPI)
    ./nautilus.nix     # file manager + xdg default for dirs
    ./file-roller.nix  # archive manager (.zip/.7z/.rar) + CLI backends
    ./vlc.nix          # VLC media player + default video/audio handler
    ./obs.nix          # OBS Studio (screencast via GNOME portal, audio via PipeWire)
    ./spotify.nix      # Spotify desktop client (unfree; allowUnfree in core.nix)
    ./ticktick.nix     # TickTick task manager (unfree; allowUnfree in core.nix)
    ./mangohud.nix     # in-game FPS overlay (per-game: `mangohud %command%` in Steam)
    ./google-drive.nix # ~/GoogleDrive rclone mount (one-time: `rclone config`)
    ./claude.nix       # Claude Code CLI + settings + statusline script
    ./insta360-link.nix # Insta360 Link 2 Pro webcam: v4l2-ctl + cameractrls PTZ control
  ];

  home.username = "unclebeam";
  home.homeDirectory = "/home/unclebeam";

  # Like system.stateVersion: the home-manager release this config was
  # born under. Set once, never bump casually.
  home.stateVersion = "26.05";

  # Let home-manager manage itself (provides the `home-manager` CLI).
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    # `settings` is written to ~/.config/git/config verbatim (sections.keys).
    settings = {
      user.name = "unclebeam";
      user.email = "patompong.beam@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
