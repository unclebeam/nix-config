# home/default.nix — home-manager entrypoint, shared by BOTH hosts
# (imported from flake.nix as home-manager.users.unclebeam).
# Same user environment, same look, on every machine.
{ config, lib, pkgs, ... }:

{
  imports = [
    ./directories.nix # home skeleton: XDG dirs (Documents/Downloads/Pictures) + ~/org + ~/.ssh
    ./niri.nix      # niri glue: symlinks niri/config.kdl + host.kdl + session target
    ./dms.nix       # DMS user glue: adw-gtk3 + template placeholders (the shell itself: modules/dms.nix)
    ./wallpapers.nix # tracked wallpaper images -> ~/Pictures/Wallpapers (picked via SUPER+Y)
    ./satty.nix     # screenshot annotator (fed by the screenshot-annotate wrapper around `dms screenshot`)
    ./alacritty.nix # terminal
    ./tmux.nix      # terminal multiplexer (plain tmux.conf; nvim navigation pairing)
    ./fish.nix      # shell + prompt
    ./direnv.nix    # per-directory envs (project dev shells via .envrc)
    ./neovim.nix    # Neovim + LazyVim (live-symlinked lua config; LSPs from Nix, no Mason)
    ./btop.nix      # resource monitor (CPU sensor pinned to k10temp/Tctl on the PC)
    ./emacs.nix     # Doom Emacs (classic clone; Nix ships emacs-pgtk, doom config live-symlinked)
    ./vscode.nix    # VS Code (FHS build) for .ipynb notebooks; per-project venvs via uv (core.nix)
    ./cursor.nix    # mouse cursor theme + size (HiDPI)
    ./gtk.nix       # GTK icon theme (Adwaita) — GTK apps' counterpart to qt.nix's breeze-icons
    ./dolphin.nix      # file manager (KIO workers) + xdg default for dirs
    ./kwallet.nix      # session keyring user half: kwalletrc (ksecretd on, no first-run wizard)
    ./ark.nix          # archive manager (.zip/.7z/.rar) + CLI backends
    ./qt.nix           # Qt theming via qt6ct + DMS's KColorScheme (Dolphin/Ark/VLC)
    ./vlc.nix          # VLC media player + default audio handler
    ./mpv.nix          # mpv: video player + default video handler (HDR parked — niri has no CM yet)
    ./obs.nix          # OBS Studio (screencast via the GNOME portal — niri's backend; audio via PipeWire)
    ./spotify.nix      # Spotify desktop client (unfree; allowUnfree in core.nix)
    ./ticktick.nix     # TickTick task manager (unfree; allowUnfree in core.nix)
    ./onlyoffice.nix   # OnlyOffice desktop editors (alongside LibreOffice in core.nix)
    ./freecad.nix      # parametric CAD modeller (authors the models the slicer below prints)
    ./orca-slicer.nix  # 3D slicer file associations (the app is a flatpak — see modules/orca-slicer.nix)
    ./mangohud.nix     # in-game FPS overlay (per-game: `mangohud %command%` in Steam)
    ./google-drive.nix # ~/GoogleDrive rclone mount (one-time: `rclone config`)
    ./chrome.nix       # default browser: web-link handler + $BROWSER (policies via modules/chromium-policies.nix + onepassword.nix)
    ./brave.nix        # secondary browser (search policy in modules/chromium-policies.nix)
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

  # The xdg default-application registry (~/.config/mimeapps.list). Enabled
  # HERE, not in any app's file: dolphin (inode/directory), ark (archives),
  # vlc (audio), mpv (video), and chrome (web links — the default browser!)
  # all merge their defaultApplications into it. It used to live in
  # dolphin.nix, which meant deleting the file manager would have silently
  # killed every other app's mime defaults too.
  xdg.mimeApps.enable = true;

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
