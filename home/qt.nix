# home/qt.nix — Qt theming so Qt apps follow DMS's wallpaper-derived colors
# instead of bare Fusion defaults. Two consumers: FreeCAD (Qt6) and VLC (Qt5).
#
# Color flow: DMS's "Apply Qt Themes" toggle (first-login step, default OFF)
# renders a KColorScheme to ~/.local/share/color-schemes/DankMatugen.colors
# on every palette change; the qt6ct/qt5ct seed points color_scheme_path at
# it, and QT_QPA_PLATFORMTHEME=qt6ct routes apps there. Until the file exists
# (needs the toggle + a wallpaper) qt6ct just uses defaults.
{ config, lib, pkgs, ... }:

let
  # Palette pointer plus the look-and-feel qt6ct would leave undefined:
  # Fusion pinned (the generated palette does the work — no extra style
  # package), breeze icons pinned by name, Inter (installed by
  # modules/dms.nix). Font strings are the 10-field legacy
  # QFont::fromString form, which both Qt5 and Qt6 parse.
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
    # The KDE fork on purpose: DMS's scheme is a KColorScheme (.colors),
    # which plain qt6ct's color_scheme_path cannot parse — swapping in plain
    # qt6ct would silently untheme VLC and FreeCAD. In nixpkgs the fork IS
    # kdePackages.qt6ct; there's no separate attr.
    pkgs.kdePackages.qt6ct
    # VLC is Qt5; qt5ct reads the same generated colors.
    pkgs.libsForQt5.qt5ct
    # The seed pins icon_theme=breeze and FreeCAD's toolbars need a complete
    # icon theme behind that name — without it, missing-icon placeholders.
    pkgs.kdePackages.breeze-icons
  ];

  # Both halves matter: sessionVariables covers login shells; apps launched
  # from the shell's launcher inherit the systemd user environment.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

  # Seed/repair qt6ct.conf and qt5ct.conf so a fresh install needs no
  # qt6ct-GUI visit. Create-only: a well-formed existing file is never
  # rewritten, so DMS's sed updates and manual GUI changes survive every
  # switch. Plain writable file, never a store symlink — DMS sed-edits it in
  # place (EROFS otherwise). The grep repairs a known upstream create-branch
  # bug that wrote a one-line file with literal "\n" text, which qt6ct
  # silently ignores forever — only that bug ever puts a literal
  # backslash-n in an ini file. `install`, not cp: the store copy is 444 and
  # the file must stay writable.
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
