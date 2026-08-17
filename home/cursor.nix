# home/cursor.nix — mouse cursor theme + size.
# Without this the session has NO cursor config at all: apps fall back to an
# unthemed 24px cursor drawn in *physical* pixels, which looks tiny on our
# 1.5×-scaled HiDPI panels. home.pointerCursor fixes that in one place — it
# installs the theme, exports XCURSOR_THEME/XCURSOR_SIZE for the session, and
# links the icons into ~/.local/share/icons so every toolkit can find them.
{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    # Breeze cursors (KDE's default, the black variant) — switched from
    # Adwaita 2026-07 with the KDE-plumbing migration, and deliberately
    # KEPT through the DMS and Noctalia migrations: a neutral black cursor
    # fits any wallpaper-derived palette, and neither shell manages
    # cursors. kdePackages.breeze ships the theme as
    # share/icons/breeze_cursors; the dir name is what XCURSOR_THEME
    # wants, not the display name ("Breeze Dark").
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24; # logical px; the compositor multiplies by the output scale (1.5) on screen

    # niri does NOT read XCURSOR_* — it takes the cursor from its own
    # config, so home/niri.nix mirrors name/size from here into the
    # Nix-generated ~/.config/niri/nix.kdl. Change it HERE; the mirror
    # follows. (The env vars above still cover apps.)

    # Generates the gtk cursor settings so GTK apps pick the same theme/size.
    # Only *generates* them — the gtk module that actually writes settings.ini
    # is switched on in home/gtk.nix (which also owns the GTK icon theme).
    gtk.enable = true;
  };
}
