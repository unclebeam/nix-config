# home/gtk.nix — the GTK-side icon theme (Qt counterpart: home/qt.nix's
# breeze-icons). GTK's compiled-in default icon-theme name is "Adwaita", but
# without the theme installed apps only get GTK's tiny bundled symbolic set
# and render missing-image boxes for the rest. adw-gtk3 doesn't help — it's
# the widget/color theme, zero icons. Adwaita, not Breeze, on purpose: GTK
# apps are designed against Adwaita icon names; each toolkit gets its native
# icon language.
{ config, lib, pkgs, ... }:

{
  # Module switch for home-manager's generated GTK settings. Lives here, not
  # cursor.nix, because it carries ALL gtk settings — the cursor lines just
  # ride along.
  gtk.enable = true;

  # No conflict with DMS: its "Apply GTK Themes" pipeline writes colors via
  # a separate dank-colors.css and switches theme through gsettings, never
  # settings.ini.
  gtk.iconTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
}
