# home/qt.nix — Qt theming, so Qt apps don't draw the bare Fusion default
# and instead follow Noctalia's wallpaper-derived colors. Promoted to its
# own file because it has three consumers (the promotion rule in
# CLAUDE.md): Dolphin and Ark (Qt6/KF6) and VLC (Qt5). Not tied to any one
# app — remove it and the apps still run, just visibly unthemed.
#
# How the colors flow: Noctalia's kcolorscheme template (builtin_ids in
# home/noctalia/config.toml) renders a KColorScheme to
# ~/.local/share/color-schemes/noctalia.colors on every palette change,
# then merges it into ~/.config/kdeglobals and pings running apps — KF6
# apps (Dolphin, Ark) recolor live from kdeglobals. The qt6ct/qt5ct seed
# below points color_scheme_path at the same .colors file for everything
# that renders through qt6ct instead (plain Qt6 apps, and VLC via qt5ct);
# QT_QPA_PLATFORMTHEME=qt6ct is what routes them there. The .colors file
# may not exist yet on a fresh install (first render needs a wallpaper) —
# qt6ct just uses defaults until it appears.
{ config, lib, pkgs, ... }:

let
  # What the seed writes: the palette pointer, plus the look-and-feel
  # qt6ct would otherwise leave undefined — Fusion pinned explicitly
  # (deliberate choice over Breeze/Darkly: no extra style package, the
  # generated palette does the work), breeze icons pinned by name instead
  # of trusting KF6's internal fallback, and Inter (installed by
  # modules/noctalia.nix) so Qt apps stop falling back to fontconfig's
  # pick. The font strings are the 10-field legacy QFont::fromString form,
  # which both Qt5 and Qt6 parse.
  qtctSeed = pkgs.writeText "qtct-seed.conf" ''
    [Appearance]
    custom_palette=true
    color_scheme_path=${config.home.homeDirectory}/.local/share/color-schemes/noctalia.colors
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
    # variant carries the KDE integration so the generated scheme actually
    # reaches them. (In nixpkgs the qt6ct-kde fork IS kdePackages.qt6ct;
    # there is no separate top-level attr.)
    pkgs.kdePackages.qt6ct
    # VLC is Qt5; qt5ct reads the same generated colors for it.
    pkgs.libsForQt5.qt5ct
    # KF6 apps hardcode "breeze" as their default icon-theme name; without
    # the theme actually installed, Dolphin/Ark render missing-icon
    # placeholders on every toolbar button. (Only the ICONS survive the
    # Breeze exit — the widget style is qt6ct's now.)
    pkgs.kdePackages.breeze-icons
  ];

  # Both halves matter: sessionVariables covers login shells, but apps
  # launched from the shell's launcher inherit the systemd user
  # environment — that second line is what the old qt.enable module did
  # for us and is easy to lose.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

  # Seed qt6ct.conf and qt5ct.conf so a fresh install needs no qt6ct-GUI
  # visit. Same pattern as the repo's other placeholders: create only
  # what's missing, then stay out of the way — an existing file is NEVER
  # rewritten, so manual qt6ct-GUI changes survive every switch. Stays a
  # plain writable file, never a store symlink, so the GUI can keep
  # editing it. (The DMS-era literal-\n corruption repair left with DMS —
  # noctalia never writes these files.) `install` (not cp) because the
  # store copy is read-only 444 and the file must stay writable.
  home.activation.qtctSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for d in qt5ct qt6ct; do
      conf="$HOME/.config/$d/$d.conf"
      if [ ! -e "$conf" ]; then
        mkdir -p "$HOME/.config/$d"
        install -m 644 ${qtctSeed} "$conf"
      fi
    done
  '';
}
