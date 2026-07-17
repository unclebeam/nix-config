# home/gtk.nix — the GTK-side icon theme, mirror of what home/qt.nix's
# breeze-icons does for KF6 apps. GTK's compiled-in default icon-theme
# name is "Adwaita", but nothing installed that theme — so GTK apps could
# only draw the tiny symbolic set bundled inside GTK/libadwaita itself
# (chevrons, hamburger, close) and rendered missing-image placeholder
# boxes for everything else (Cameractrls' warning triangles were the
# giveaway). adw-gtk3 (home/dms.nix) doesn't help here: it's the
# widget/COLOR theme DMS recolors, and ships zero icons.
#
# Deliberately Adwaita, not Breeze: GTK apps are designed against the
# Adwaita icon names, so every lookup resolves; Qt/KDE apps keep Breeze
# (home/qt.nix) — each toolkit gets its native icon language.
{ config, lib, pkgs, ... }:

{
  # The module switch for home-manager's generated GTK settings
  # (~/.config/gtk-3.0/settings.ini + gtk-4.0). Lives here rather than in
  # cursor.nix because it carries ALL gtk settings — the cursor lines from
  # home.pointerCursor.gtk just ride along in the same files.
  gtk.enable = true;

  # Installs the theme into the user profile (already on XDG_DATA_DIRS)
  # and writes gtk-icon-theme-name=Adwaita into settings.ini. No conflict
  # with DMS: its "Apply GTK Themes" toggle writes colors via a separate
  # dank-colors.css, never settings.ini.
  gtk.iconTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
}
