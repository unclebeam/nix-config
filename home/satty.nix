# home/satty.nix — screenshot annotator. Every screenshot flows through it:
# the Print binds (home/niri/config.kdl) run the `screenshot-annotate`
# wrapper, which captures via DMS's screenshot UI and hands the image to
# satty. Nothing touches disk or clipboard until Enter commits inside satty;
# Escape discards. Owns everything satty: package, config.toml, wrapper.
{ config, lib, pkgs, ... }:

{
  home.packages = [
    # Mode passes through: `screenshot-annotate` = region (default),
    # `… full` = focused output, `… window` = focused window.
    (pkgs.writeShellScriptBin "screenshot-annotate" ''
      # --no-file/--no-clipboard/--no-notify: satty is the ONLY output —
      # the raw capture is kept nowhere, and DMS's "saved!" toast would lie.
      # Buffer through a temp file instead of a raw pipe so a cancelled
      # region-select (empty stdout) never launches satty on a blank image.
      #
      # Chromium quirk (verified 2026-07-21, DMS 1.5.2, under hyprland):
      # when a Chromium-family window (brave) OWNS the clipboard, dms's
      # region UI touching the selection during init makes the browser fire
      # an xdg-activation request — a compositor that honors it yanks focus
      # to the browser mid-capture. Re-owning the clipboard first (same
      # content, owner becomes wl-copy) keeps dms away from the browser.
      # Not re-verified on niri, but harmless: only the top mime type
      # survives the re-own, which is fine — a committed satty run replaces
      # the clipboard with the screenshot anyway. Drop when upstream fixes
      # the clipboard init.
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
    settings = {
      general = {
        # A tiling compositor would squeeze satty into whatever gap is free.
        fullscreen = true;
        early-exit = true; # close after the first save/copy
        copy-command = "wl-copy";
        # Copying also writes the file below — clipboard AND disk in one.
        save-after-copy = true;
        initial-tool = "arrow";
        output-filename = "${config.home.homeDirectory}/Pictures/Screenshots/annotated-%Y%m%d-%H%M%S.png";
        actions-on-enter = [ "save-to-clipboard" ]; # Enter = copy(+save)+exit
        actions-on-escape = [ "exit" ];
      };
      # Quick-pick colors stay satty's stock palette — annotation colors
      # want to be legible on any screenshot, not to match a theme.
    };
  };
}
