# home/default.nix — home-manager entrypoint, shared by BOTH hosts
# (imported from flake.nix as home-manager.users.unclebeam).
# Same user environment, same look, on every machine.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./niri.nix      # niri glue: symlinks niri/config.kdl + swayidle (locker = modules/gtklock.nix)
    ./waybar.nix    # status bar
    ./fuzzel.nix    # launcher
    ./swaync.nix    # notifications (replaced mako: renders action buttons)
    ./satty.nix     # screenshot annotator (run by hand on saved screenshots)
    ./alacritty.nix # terminal
    ./tmux.nix      # terminal multiplexer (plain tmux.conf; nvim navigation pairing)
    ./fish.nix      # shell + prompt
    ./direnv.nix    # per-directory envs (project dev shells via .envrc)
    ./neovim.nix    # Neovim + LazyVim (live-symlinked lua config; LSPs from Nix, no Mason)
    ./emacs.nix     # Doom Emacs (classic clone; Nix ships emacs-pgtk, doom config live-symlinked)
    ./cursor.nix    # mouse cursor theme + size (HiDPI)
    ./dolphin.nix      # file manager (KIO workers) + xdg default for dirs
    ./kwallet.nix      # session keyring user half: kwalletrc (ksecretd on, no first-run wizard)
    ./ark.nix          # archive manager (.zip/.7z/.rar) + CLI backends
    ./qt.nix           # Breeze widget/icon theming for the Qt apps (Dolphin/Ark/VLC)
    ./vlc.nix          # VLC media player + default video/audio handler
    ./obs.nix          # OBS Studio (screencast via GNOME portal, audio via PipeWire)
    ./spotify.nix      # Spotify desktop client (unfree; allowUnfree in core.nix)
    ./ticktick.nix     # TickTick task manager (unfree; allowUnfree in core.nix)
    ./onlyoffice.nix   # OnlyOffice desktop editors (alongside LibreOffice in core.nix)
    ./mangohud.nix     # in-game FPS overlay (per-game: `mangohud %command%` in Steam)
    ./google-drive.nix # ~/GoogleDrive rclone mount (one-time: `rclone config`)
    ./claude.nix       # Claude Code CLI + settings + statusline script
    ./insta360-link.nix # Insta360 Link 2 Pro webcam: v4l2-ctl + cameractrls PTZ control
    ./power.nix         # Shutdown/Reboot as fuzzel launcher entries (systemctl via logind)
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
