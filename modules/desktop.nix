# desktop.nix — compositor-agnostic desktop infrastructure: the greeter,
# Wayland-wide env, the GTK portal, and fonts. Compositor-specific bits stay
# in modules/niri.nix. (This file was split out when hyprland briefly ran
# alongside sway; it keeps its role now that niri is the only session —
# nothing in here assumes a particular compositor.)
{ config, lib, pkgs, ... }:

let
  colors = import ../home/colors.nix;
in
{
  # ── SDDM + SilentSDDM ──────────────────────────────────────────────────
  # SDDM is the display manager; SilentSDDM (a flake input, module wired in
  # by mkHost) is its QML theme. Enabling programs.silentSDDM does ALL the
  # SDDM plumbing itself: services.displayManager.sddm.enable, the Qt6
  # build (kdePackages.sddm — the theme needs sddm ≥ 0.21 / Qt ≥ 6.5), the
  # theme's Qt deps (svg/virtualkeyboard/multimedia/imageformats), and
  # wayland.enable — so there is deliberately no sddm.enable line here.
  # It also installs `test-sddm-silent`, which previews the greeter in a
  # window from a running session — use that instead of logging out.
  #
  # Sessions: SDDM scans the same wayland-sessions dir regreet (the old
  # greeter) did, so the .desktop file that programs.niri installs appears
  # with zero wiring here. SDDM remembers the last user + session across
  # reboots (/var/lib/sddm/state.conf) — NB: after a session is REMOVED
  # (sway→hyprland→niri), the remembered entry dangles and the menu needs
  # one manual pick of the surviving session.
  programs.silentSDDM = {
    enable = true;
    theme = "rei"; # the upstream default preset; melange-skinned below

    # Melange over the rei preset, same spirit as the CSS overlay the old
    # ReGreet greeter had. These are appended to the preset's INI config
    # (last key wins), so only the keys we change are listed: rei's video
    # background becomes a flat palette color, its lavender accent becomes
    # melange yellow, and its bundled RedHatDisplay font becomes ours.
    # QColor wants '#'-prefixed hex — exactly what colors.nix holds — and
    # string values are quoted to match how the preset's own config is
    # written. Everything else (sizes, layout, animations) stays stock.
    settings =
      let
        q = s: ''"${s}"''; # quote a string value for the INI file
        font = q "JetBrainsMono Nerd Font"; # already in fonts.packages below
        accent = q colors.b.yellow; # interactive highlight (buttons, borders)
        text = q colors.a.fg;
        onAccent = q colors.a.bg; # dark text/icons on a filled accent
        surface = q colors.a.float; # inputs, popups, tooltips
        border = q colors.a.ui;
      in
      {
        # The pre-login screen ("press any key"): flat melange, big clock.
        LockScreen = {
          use-background-color = true;
          background-color = q colors.a.bg;
        };
        "LockScreen.Clock" = {
          font-family = font;
          color = text;
        };
        "LockScreen.Date" = {
          font-family = font;
          color = q colors.a.com; # secondary text, like comments
        };

        # The user/password screen: same flat background.
        LoginScreen = {
          use-background-color = true;
          background-color = q colors.a.bg;
        };
        "LoginScreen.LoginArea.Avatar" = {
          active-border-color = accent;
          inactive-border-color = border;
        };
        "LoginScreen.LoginArea.Username" = {
          font-family = font;
          color = text;
        };
        "LoginScreen.LoginArea.PasswordInput" = {
          font-family = font;
          content-color = text;
          background-color = surface;
          background-opacity = 1.0; # rei has this transparent
          border-color = border;
        };
        "LoginScreen.LoginArea.LoginButton" = {
          font-family = font;
          content-color = text; # idle: outline + cream arrow…
          border-color = border;
          background-color = accent;
          active-background-color = accent; # …focused: filled yellow,
          active-content-color = onAccent; #  dark arrow on it
        };
        "LoginScreen.LoginArea.Spinner" = {
          font-family = font;
          color = text;
        };
        "LoginScreen.LoginArea.WarningMessage" = {
          font-family = font;
          normal-color = text;
          warning-color = accent;
          error-color = q colors.b.red;
        };

        # The bottom-left menu row (session / layout / keyboard / power):
        # each button is its own section, all skinned identically — cream
        # icon at rest, filled yellow with a dark icon when open.
        "LoginScreen.MenuArea.Buttons".font-family = font;
        "LoginScreen.MenuArea.Session" = {
          background-color = accent;
          content-color = text;
          active-content-color = onAccent;
        };
        "LoginScreen.MenuArea.Layout" = {
          background-color = accent;
          content-color = text;
          active-content-color = onAccent;
        };
        "LoginScreen.MenuArea.Keyboard" = {
          background-color = accent;
          content-color = text;
          active-content-color = onAccent;
        };
        "LoginScreen.MenuArea.Power" = {
          background-color = accent;
          content-color = text;
          active-content-color = onAccent;
        };
        "LoginScreen.MenuArea.Popups" = {
          font-family = font;
          background-color = surface;
          content-color = text;
          active-option-background-color = accent;
          active-content-color = onAccent;
          border-color = border;
        };

        # The tap-to-type keyboard the menu row can summon (SDDM runs it
        # via qtvirtualkeyboard; the module wires that up).
        "LoginScreen.VirtualKeyboard" = {
          background-color = surface;
          key-color = surface;
          key-content-color = text;
          selection-background-color = q colors.a.sel;
          selection-content-color = text;
          primary-color = accent;
          border-color = border;
        };

        Tooltips = {
          font-family = font;
          content-color = text;
          background-color = surface;
        };
      };
  };

  # The SDDM greeter itself needs a Wayland compositor to draw in; SDDM's
  # Wayland mode runs it inside a kiosk session on VT1 (no X11 anywhere).
  # NOT the "weston" default: Weston 15.0.1 aborts on startup on the
  # RX 9070 XT (assertion in weston_drm_format_add_modifier — Mesa 26.1.4
  # advertises a duplicate DRM modifier), which killed the greeter and left
  # a black screen. KWin drives the same hardware fine, at the cost of
  # pulling kdePackages.kwin into the closure.
  services.displayManager.sddm.wayland.compositor = "kwin";

  # Chromium-based apps (Brave) run native Wayland instead of XWayland when
  # this is set. Electron apps honor it too. Session-agnostic.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # xdg-desktop-portal is how sandbox-ish desktop APIs work on Wayland:
  # screen sharing, screenshots, file pickers. The GTK portal covers the
  # generic interfaces (file chooser…); modules/niri.nix adds the GNOME
  # portal (niri's ScreenCast backend) plus the niri-portals.conf that
  # routes each interface to the right backend.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # ── Fonts ──────────────────────────────────────────────────────────────
  # Mono fonts (JetBrainsMono for the UI, IosevkaTerm for the terminal),
  # Sarabun for Thai text, Noto for everything else.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka-term # alacritty's terminal font (home/alacritty.nix)
    sarabun-font # Thai text font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Prefer Sarabun whenever the text is Thai. Installing a font only makes
  # it *available* — without these rules Thai renders in FreeSerif instead.
  # Two rules because apps reach Thai glyphs by two different paths:
  # lang-tagged queries (pango/harfbuzz, pages with lang="th") and raw
  # per-character charset fallback (Chromium on pages without lang="th").
  # NB: localConf becomes /etc/fonts/local.conf verbatim, so it must be a
  # complete XML document — one <fontconfig> root. Multiple top-level
  # elements are "junk after document element" and fontconfig silently
  # drops the WHOLE file.
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
    <!-- binding="strong" is load-bearing: NixOS's generated default-fonts
         conf prefers DejaVu with strong binding, and a strong family match
         outranks a lang match — a weak prepend here silently loses and
         "sans-serif" resolves to DejaVu even for Thai. -->
    <match target="pattern">
      <test name="lang" compare="contains"><string>th</string></test>
      <edit name="family" mode="prepend" binding="strong"><string>Sarabun</string></edit>
    </match>

    <!-- Chromium falls back per-character by charset (not lang) on pages
         without lang="th", and GNU FreeFont (pulled in by NixOS's
         fonts.enableDefaultPackages) wins that query — Thai renders in
         FreeSerif instead of Sarabun. Nothing else needs these fonts;
         Noto/DejaVu/Liberation cover everything they do. -->
    <selectfont>
      <rejectfont>
        <pattern><patelt name="family"><string>FreeSerif</string></patelt></pattern>
        <pattern><patelt name="family"><string>FreeSans</string></patelt></pattern>
        <pattern><patelt name="family"><string>FreeMono</string></patelt></pattern>
      </rejectfont>
    </selectfont>
    </fontconfig>
  '';
}
