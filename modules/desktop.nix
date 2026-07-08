# desktop.nix — compositor-agnostic desktop infrastructure: the greeter,
# Wayland-wide env, the GTK portal, and fonts. Compositor-specific bits stay
# in modules/hyprland.nix. (This file was split out when hyprland briefly ran
# alongside sway; it keeps its role now that hyprland is the only session —
# nothing in here assumes a particular compositor.)
{ config, lib, pkgs, ... }:

let
  colors = import ../home/colors.nix;
in
{
  # ── greetd + ReGreet ───────────────────────────────────────────────────
  # greetd is a tiny display manager; ReGreet is its graphical (GTK4) UI.
  # After login it execs the chosen compositor directly — no
  # desktop-manager layer at all.
  #
  # There is deliberately NO services.greetd block here: enabling regreet
  # sets services.greetd.enable and the default_session command (regreet
  # inside cage, a single-app kiosk compositor, on VT1) itself — both via
  # mkDefault, so an explicit command here would silently REPLACE regreet
  # with whatever we wrote. The greeter user is defaulted by greetd too.
  #
  # Sessions: regreet scans $XDG_DATA_DIRS/wayland-sessions, which NixOS
  # points at the .desktop files that programs.hyprland installs — the
  # session appears with zero wiring here.
  #   NB: the dropdown shows TWO hyprland entries — the nixpkgs hyprland
  #   package unconditionally ships "Hyprland (uwsm-managed)" next to plain
  #   "Hyprland" (it can't be filtered out without breaking the
  #   sessionPackages assertion). Both work: modules/hyprland.nix sets
  #   withUWSM so uwsm's user units exist, and the hyprland.lua session
  #   hook is dual-mode.
  # There is no "default session" knob: pick a session once on first boot,
  # and regreet remembers the last user AND last session per user across
  # reboots (/var/lib/regreet/state.toml).
  #
  # Side effect to know about: this enables services.accounts-daemon —
  # that's how regreet lists users instead of asking for a typed username.
  programs.regreet = {
    enable = true;

    # The greeter's UI font. The package is already in fonts.packages
    # below, but the module wants the pair (name + package) so the font is
    # guaranteed present even if the list changes; without an override the
    # greeter would pull in Cantarell just for itself.
    font = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };

    # cursorTheme is left at its default (Adwaita, 24px) — the same theme
    # home/cursor.nix sets for the session, so the pointer doesn't change
    # style at the login → desktop boundary.

    # Adwaita's dark variant as the base widget theme; the melange palette
    # is layered on top via CSS below.
    settings.GTK.application_prefer_dark_theme = true;

    # Melange over Adwaita-dark, kept minimal on purpose: a flat palette
    # background, stock widgets. colors.nix values keep their leading '#',
    # which is exactly what CSS wants. (GTK4 CSS, not a full theme — see
    # https://docs.gtk.org/gtk4/css-properties.html for what's tweakable.)
    extraCss = ''
      window {
        background-color: ${colors.a.bg};
      }
    '';
  };

  # Chromium-based apps (Brave) run native Wayland instead of XWayland when
  # this is set. Electron apps honor it too. Session-agnostic.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # xdg-desktop-portal is how sandbox-ish desktop APIs work on Wayland:
  # screen sharing, screenshots, file pickers. The GTK portal covers the
  # generic interfaces (file chooser…); modules/hyprland.nix adds the
  # ScreenCast/Screenshot backend (xdg-desktop-portal-hyprland) plus the
  # portals.conf that routes each interface to the right backend.
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
