# home/cursor.nix — mouse cursor theme + size. Without it the session falls
# back to an unthemed 24px cursor in physical pixels — tiny on 1.5×-scaled
# panels. home.pointerCursor installs the theme, exports XCURSOR_*, and
# links the icons where every toolkit finds them.
{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    # Neutral black cursor fits any wallpaper-derived palette; neither shell
    # manages cursors. The dir name (share/icons/breeze_cursors) is what
    # XCURSOR_THEME wants, not the display name.
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24; # logical px; the compositor multiplies by output scale

    # niri does NOT read XCURSOR_* — home/niri.nix mirrors name/size into
    # the generated nix.kdl. Change it HERE; the mirror follows.

    # Generates the gtk cursor settings; the gtk module that writes
    # settings.ini is switched on in home/gtk.nix.
    gtk.enable = true;
  };
}
