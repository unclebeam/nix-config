# home/qt.nix — Qt theming, so Qt apps don't draw the bare Fusion default
# and instead follow DMS's wallpaper-derived (matugen) colors. Promoted to
# its own file because it has three consumers (the promotion rule in
# CLAUDE.md): Dolphin and Ark (Qt6/KF6) and VLC (Qt5). Not tied to any one
# app — remove it and the apps still run, just visibly unthemed.
#
# How the colors flow (replaced Breeze 2026-07 with the DMS migration):
# DMS generates a qt6ct/qt5ct color scheme from the wallpaper when "Apply
# Qt themes" is toggled on in DMS Settings; QT_QPA_PLATFORMTHEME=qt6ct
# below makes Qt apps read it. Nothing renders DMS colors until that
# toggle is flipped once — until then Qt apps show qt6ct's defaults.
#
# ⚠ The last inch of that pipeline is broken upstream (DMS rev 74896fb,
# quickshell/scripts/qt.sh): when qt6ct.conf/qt5ct.conf doesn't exist yet,
# the script creates it with `printf '[Appearance]\\n…'` — the doubled
# backslash writes LITERAL "\n" text instead of newlines, producing a
# one-line garbage file whose [Appearance] header never parses, so qt6ct
# silently ignores the matugen palette and Qt apps stay unthemed forever
# (that exact corpse is what both machines had until 2026-07-22). The
# script's update-an-EXISTING-file branch uses sed correctly, so the fix
# is a one-time seed: the activation script below (re)writes the file iff
# it's missing or carries the literal-\n corruption, and otherwise never
# touches it — DMS's sed and any qt6ct-GUI tweaks stay the owners. The
# file must remain a plain writable file, never a store symlink (DMS
# sed-edits it in place — same EROFS failure class as hyprland.lua).
{ config, lib, pkgs, ... }:

let
  # What the seed writes — exactly the [Appearance] shape qt.sh's sed
  # branch expects to find, plus the look-and-feel qt6ct would otherwise
  # leave undefined: Fusion pinned explicitly (deliberate choice over
  # Breeze/Darkly — no extra style package, the matugen palette does the
  # work), breeze icons pinned by name instead of trusting KF6's internal
  # fallback, and the shell's own UI font (Inter, from modules/dms.nix)
  # so Qt apps stop falling back to fontconfig's pick. The font strings
  # are the 10-field legacy QFont::fromString form, which both Qt5 and
  # Qt6 parse. color_scheme_path may not exist yet on a fresh install
  # (DMS writes it on the first "Apply Qt Themes" toggle) — qt6ct just
  # uses defaults until the file appears.
  qtctSeed = pkgs.writeText "qtct-seed.conf" ''
    [Appearance]
    custom_palette=true
    color_scheme_path=${config.home.homeDirectory}/.local/share/color-schemes/DankMatugen.colors
    style=Fusion
    icon_theme=breeze

    [Fonts]
    fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
    general="Inter,10,-1,5,50,0,0,0,0,0"
  '';
in
{
  home.packages = [
    # qt6ct, the KDE-flavored build: KF6 apps (Dolphin, Ark) resolve their
    # palette through KColorScheme, which plain qt6ct can't feed — this
    # variant carries the KDE integration so DMS's generated scheme
    # actually reaches them. (In nixpkgs the qt6ct-kde fork IS
    # kdePackages.qt6ct; there is no separate top-level attr.)
    pkgs.kdePackages.qt6ct
    # VLC is Qt5; qt5ct reads the same DMS-generated colors for it.
    pkgs.libsForQt5.qt5ct
    # KF6 apps hardcode "breeze" as their default icon-theme name; without
    # the theme actually installed, Dolphin/Ark render missing-icon
    # placeholders on every toolbar button. (Only the ICONS survive the
    # Breeze exit — the widget style is qt6ct's now.)
    pkgs.kdePackages.breeze-icons
  ];

  # Both halves matter: sessionVariables covers login shells, but apps
  # launched from Spotlight inherit the systemd user
  # environment — that second line is what the old qt.enable module did
  # for us and is easy to lose.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

  # Seed/repair qt6ct.conf and qt5ct.conf (see the header for the upstream
  # bug this exists for). Same pattern as home/dms.nix's placeholders:
  # create only what's missing, then stay out of the way — a well-formed
  # existing file is NEVER rewritten, so DMS's sed updates and manual
  # qt6ct-GUI changes survive every switch. The corruption test is a
  # literal-backslash-n grep: only qt.sh's broken create-branch ever puts
  # that two-character sequence in an ini file. `install` (not cp) because
  # the store copy is read-only 444 and the file must stay writable.
  home.activation.qtctSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for d in qt5ct qt6ct; do
      conf="$HOME/.config/$d/$d.conf"
      if [ ! -e "$conf" ] || grep -qF '\n' "$conf"; then
        mkdir -p "$HOME/.config/$d"
        install -m 644 ${qtctSeed} "$conf"
      fi
    done
  '';
}
