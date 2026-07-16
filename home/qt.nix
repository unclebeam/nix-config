# home/qt.nix — Qt widget/icon theming, so Qt apps don't draw the bare
# Fusion default under an otherwise GTK session. Promoted to its own file
# because it now has three consumers (the promotion rule in CLAUDE.md):
# Dolphin and Ark (Qt6/KF6) and VLC (Qt5). Not tied to any one app — remove
# it and the apps still run, just visibly unthemed.
{ config, lib, pkgs, ... }:

{
  qt.enable = true;

  # Breeze — KDE's stock widget style, the look Dolphin/Ark are designed
  # around. Naming it is enough: home-manager resolves the package to
  # kdePackages.breeze (Qt6) plus its .qt5 variant (so VLC gets it too) and
  # exports QT_STYLE_OVERRIDE + QT_PLUGIN_PATH into both the session env and
  # the systemd user env — which is what makes it apply to fuzzel-launched
  # apps under niri, where no Plasma is around to set anything.
  qt.style.name = "breeze";

  # KF6 apps hardcode "breeze" as their default icon-theme name; without the
  # theme actually installed, Dolphin/Ark render missing-icon placeholders
  # on every toolbar button.
  home.packages = [ pkgs.kdePackages.breeze-icons ];

  # Deliberately NO qt.platformTheme (restrained-by-default, per repo style):
  # the style override above covers widgets and that's what shows. If fonts
  # or file dialogs in Qt apps ever look off, the escalation path is
  # qt.platformTheme.name = "gtk3" (follow the GTK settings) or "kde"
  # (full plasma-integration, configured via qt.kde.settings).
}
