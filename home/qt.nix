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
{ config, lib, pkgs, ... }:

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
}
