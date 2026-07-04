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
    package = pkgs.adwaita-icon-theme; # plain GNOME cursor — matches the minimal look
    name = "Adwaita";
    size = 32; # logical px; sway multiplies by the output scale (1.5) on screen

    # Writes `seat * xcursor_theme Adwaita 32` into the sway config so the
    # compositor-drawn cursor (desktop, window borders) matches the apps.
    sway.enable = true;

    # Generates the gtk cursor settings so GTK apps pick the same theme/size.
    gtk.enable = true;
  };

  # home.pointerCursor.gtk.enable only *generates* the gtk settings; the gtk
  # module itself must be on for them to actually be written out.
  gtk.enable = true;
}
