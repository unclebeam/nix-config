# home/satty.nix — screenshot annotator. Every screenshot flows through it:
# the Print binds (the mandatory-feature DEVIATION block at the bottom of
# home/hypr/hyprland.lua) run the `screenshot-annotate` wrapper below,
# which captures via DMS's built-in screenshot UI and hands the image
# straight to satty. Nothing touches disk or clipboard until you commit
# inside satty (Enter); Escape discards.
# Owns everything satty: the package, config.toml, and the wrapper script.
{ config, lib, pkgs, ... }:

{
  home.packages = [
    # Capture with DMS's screenshot UI, hand the result to satty. Mode
    # passes through: `screenshot-annotate` = region, `… full` = focused
    # output, `… window` = focused window (the three Print binds).
    (pkgs.writeShellScriptBin "screenshot-annotate" ''
      # --no-file/--no-clipboard/--no-notify: satty is the ONLY output —
      # the raw capture is kept nowhere, and DMS's "saved!" toast would lie.
      # Buffer through a temp file instead of a raw pipe so a cancelled
      # region-select (empty stdout) never launches satty on a blank image.
      #
      # Chromium quirk (verified 2026-07-21, DMS 1.5.2): when a Chromium-
      # family window (brave) OWNS the clipboard, dms's region UI touching
      # the selection during init makes the browser fire an xdg-activation
      # request — hyprland honors it and yanks focus AND the workspace to
      # the browser mid-capture. Re-owning the clipboard first (same
      # content, owner becomes wl-copy) keeps dms away from the browser.
      # Only the top mime type survives the re-own, which is fine: a
      # committed satty run replaces the clipboard with the screenshot
      # anyway. Drop this if upstream fixes the clipboard init.
      t=$(wl-paste --list-types 2>/dev/null | head -n1)
      [ -n "$t" ] && wl-paste -t "$t" 2>/dev/null | wl-copy -t "$t" 2>/dev/null
      img=$(mktemp --suffix=.png)
      trap 'rm -f "$img"' EXIT
      dms screenshot "$@" --stdout --no-file --no-clipboard --no-notify > "$img"
      [ -s "$img" ] && satty --filename "$img"
    '')
  ];

  programs.satty = {
    enable = true;
    # Rendered to ~/.config/satty/config.toml.
    settings = {
      general = {
        # A tiling compositor would squeeze satty into whatever gap is
        # free — fullscreen it so there's actually room to annotate.
        fullscreen = true;
        early-exit = true; # close after the first save/copy
        copy-command = "wl-copy"; # wayland clipboard
        # Copying ALSO writes the file below, so every screenshot lands on
        # both the clipboard AND disk in one action.
        save-after-copy = true;
        initial-tool = "arrow";
        # strftime placeholders expanded by satty. The "annotated-" prefix is
        # just a readable marker on the saved filenames.
        output-filename = "${config.home.homeDirectory}/Pictures/Screenshots/annotated-%Y%m%d-%H%M%S.png";
        actions-on-enter = [ "save-to-clipboard" ]; # Enter = copy(+save)+exit
        actions-on-escape = [ "exit" ];
      };
      # Toolbar quick-pick colors: satty's stock palette. (The old melange
      # override left with colors.nix in the DMS migration — annotation
      # colors want to be legible on any screenshot, not to match a theme.)
    };
  };
}
