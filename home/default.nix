# home/default.nix — home-manager entrypoint, shared by BOTH hosts
# (imported from flake.nix as home-manager.users.unclebeam).
{ config, lib, pkgs, ... }:

{
  imports = [
    ./directories.nix # home skeleton: XDG dirs + ~/org + ~/.ssh
    ./niri.nix      # niri glue: symlinks niri/config.kdl + nix.kdl + session target
    ./dms.nix       # DMS user glue: adw-gtk3 + template placeholders (the shell itself: modules/dms.nix)
    ./wallpapers.nix # tracked wallpaper images -> ~/Pictures/Wallpapers
    ./satty.nix     # screenshot annotator (fed by the screenshot-annotate wrapper)
    ./alacritty.nix # terminal
    ./tmux.nix      # terminal multiplexer (plain tmux.conf; nvim navigation pairing)
    ./fish.nix      # shell + prompt
    ./direnv.nix    # per-directory envs (project dev shells via .envrc)
    ./neovim.nix    # Neovim + LazyVim (live-symlinked lua config; LSPs from Nix, no Mason)
    ./btop.nix      # resource monitor (CPU sensor pinned to k10temp/Tctl on the PC)
    ./emacs.nix     # Doom Emacs (classic clone; Nix ships emacs-pgtk, doom config live-symlinked)
    ./vscode.nix    # VS Code (FHS build) for .ipynb notebooks; per-project venvs via uv
    ./cursor.nix    # mouse cursor theme + size (HiDPI)
    ./gtk.nix       # GTK icon theme (Adwaita)
    ./nautilus.nix     # file manager (system half in modules/nautilus.nix) + xdg default for dirs
    ./file-roller.nix  # archive manager + CLI backends
    ./qt.nix           # Qt theming via qt6ct + DMS's KColorScheme (VLC/FreeCAD)
    ./vlc.nix          # VLC + default audio handler
    ./mpv.nix          # mpv + default video handler
    ./obs.nix          # OBS Studio (screencast via the GNOME portal)
    ./spotify.nix      # Spotify desktop client
    ./freecad.nix      # parametric CAD modeller
    ./orca-slicer.nix  # 3D slicer file associations (the app is a flatpak)
    ./mangohud.nix     # in-game FPS overlay (per-game: `mangohud %command%` in Steam)
    ./google-drive.nix # ~/GoogleDrive rclone mount (one-time: `rclone config`)
    ./chrome.nix       # default browser: web-link handler + $BROWSER
    ./brave.nix        # secondary browser
    ./claude.nix       # Claude Code CLI + settings + statusline script
    ./insta360-link.nix # Insta360 Link 2 Pro webcam: v4l2-ctl + cameractrls PTZ
  ];

  home.username = "unclebeam";
  home.homeDirectory = "/home/unclebeam";

  # Like system.stateVersion: set once, never bump casually.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # The xdg default-application registry (~/.config/mimeapps.list). Enabled
  # here, not in any app's file — nautilus, file-roller, vlc, mpv and chrome
  # all merge their defaultApplications into it, so no single app's removal
  # can kill the others' mime defaults.
  xdg.mimeApps.enable = true;

  programs.git = {
    enable = true;
    # `settings` is written to ~/.config/git/config verbatim.
    settings = {
      user.name = "unclebeam";
      user.email = "patompong.beam@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
