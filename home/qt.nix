# home/qt.nix — Qt theming, so Qt apps don't draw the bare Fusion default
# and instead follow DMS's wallpaper-derived colors. Promoted to its own
# file because it has two consumers (the promotion rule in CLAUDE.md):
# FreeCAD (Qt6) and VLC (Qt5). Not tied to any one app — remove it and the
# apps still run, just visibly unthemed. (The KF6 consumers — Dolphin,
# Ark — left with the 2026-08 Nautilus migration; what stayed KDE here is
# plumbing, not apps: qt6ct-kde and breeze-icons, see below.)
#
# How the colors flow: DMS's "Apply Qt Themes" toggle (Settings GUI — a
# first-login step, default OFF) renders a KColorScheme to
# ~/.local/share/color-schemes/DankMatugen.colors on every palette change
# (it also merges it into ~/.config/kdeglobals — a no-op now with no KF6
# app left to read it; harmless residue). The qt6ct/qt5ct seed below
# points color_scheme_path at that .colors file for everything that
# renders through qt6ct (plain Qt6 apps like FreeCAD, and VLC via qt5ct);
# QT_QPA_PLATFORMTHEME=qt6ct is what routes them there. The .colors file
# may not exist yet on a fresh install (first render needs the toggle plus
# a wallpaper) — qt6ct just uses defaults until it appears.
{ config, lib, pkgs, ... }:

let
  # What the seed writes: the palette pointer, plus the look-and-feel
  # qt6ct would otherwise leave undefined — Fusion pinned explicitly
  # (deliberate choice over Breeze/Darkly: no extra style package, the
  # generated palette does the work), breeze icons pinned by name instead
  # of trusting KF6's internal fallback, and Inter (installed by
  # modules/dms.nix) so Qt apps stop falling back to fontconfig's
  # pick. The font strings are the 10-field legacy QFont::fromString form,
  # which both Qt5 and Qt6 parse.
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
    # qt6ct, the KDE-flavored build — kept AFTER the KF6 apps left, and not
    # by inertia: DMS's generated scheme is a KColorScheme (.colors) file,
    # a format plain qt6ct's color_scheme_path cannot parse — only this
    # fork's KDE integration reads it. Swapping in plain qt6ct would
    # silently untheme VLC and FreeCAD. (In nixpkgs the qt6ct-kde fork IS
    # kdePackages.qt6ct; there is no separate top-level attr.)
    pkgs.kdePackages.qt6ct
    # VLC is Qt5; qt5ct reads the same generated colors for it.
    pkgs.libsForQt5.qt5ct
    # The seed below pins icon_theme=breeze, and FreeCAD's Qt toolbars need
    # a complete icon theme behind that name — without the package they
    # render missing-icon placeholders. (Only the ICONS remain of Breeze —
    # the widget style is qt6ct's Fusion. Switching Qt apps to Adwaita
    # icons would mean rewriting the seed + its repair branch for untested
    # FreeCAD coverage; not worth it.)
    pkgs.kdePackages.breeze-icons
  ];

  # Both halves matter: sessionVariables covers login shells, but apps
  # launched from the shell's launcher inherit the systemd user
  # environment — that second line is what the old qt.enable module did
  # for us and is easy to lose.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
  systemd.user.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

  # Seed/repair qt6ct.conf and qt5ct.conf so a fresh install needs no
  # qt6ct-GUI visit. Same pattern as the repo's other placeholders: create
  # only what's missing, then stay out of the way — a well-formed existing
  # file is NEVER rewritten, so DMS's own sed updates and manual qt6ct-GUI
  # changes survive every switch. Stays a plain writable file, never a
  # store symlink — DMS sed-edits it in place, and a store symlink would
  # die with EROFS.
  #
  # The repair branch is back with DMS (retired during the noctalia era —
  # noctalia never wrote these files): upstream's qt.sh CREATE branch once
  # wrote `printf '[Appearance]\\n…'` with a doubled backslash, producing a
  # one-line garbage file with literal "\n" text that qt6ct silently
  # ignores forever (both machines carried that corpse until 2026-07-22;
  # its update-an-EXISTING-file sed branch is fine). Unverified whether
  # 1.5.3 still has the bug — the grep is harmless either way: only that
  # broken create-branch ever puts a literal backslash-n in an ini file.
  # `install` (not cp) because the store copy is read-only 444 and the
  # file must stay writable.
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
