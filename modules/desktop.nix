# desktop.nix — compositor-agnostic desktop infrastructure: Wayland-wide
# env, the GTK portal fallback, and fonts. Compositor-specific bits stay in
# modules/niri.nix; the login greeter (DMS on greetd) lives in
# modules/dms-greeter.nix. (This file was split out when hyprland briefly
# ran alongside sway; it keeps its role now that niri is the only session —
# nothing in here assumes a particular compositor.)
{ config, lib, pkgs, ... }:

let
  # TH Sarabun PSK — the 2006 DIP/SIPA font that Thai official documents
  # require. Not in nixpkgs (pkgs.sarabun-font below is Google's newer,
  # *different* "Sarabun" family — the two coexist because this one's
  # internal family name is "TH SarabunPSK"), so the TTFs are vendored
  # in-repo under fonts/th-sarabun-psk/ along with their license.
  th-sarabun-psk = pkgs.stdenvNoCC.mkDerivation {
    pname = "th-sarabun-psk";
    version = "1.0";
    src = ./fonts/th-sarabun-psk;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp *.ttf "$out/share/fonts/truetype/"
    '';
  };
in
{
  # Chromium-based apps (Brave) run native Wayland instead of XWayland when
  # this is set. Electron apps honor it too. Session-agnostic.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # xdg-desktop-portal is how sandbox-ish desktop APIs work on Wayland:
  # screen sharing, screenshots, file pickers. Since the 2026-07 KDE
  # migration nothing routes to the GTK portal directly — dialogs go to the
  # KDE portal, capture to the GNOME one (both via modules/niri.nix's
  # routing) — it's only the trailing fallback in `default=kde;gtk` for
  # interfaces neither implements. Kept here (the niri module force-installs
  # it anyway) so this file stays a working baseline for any compositor.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # ── Fonts ──────────────────────────────────────────────────────────────
  # Mono fonts (JetBrainsMono for the UI, IosevkaTerm for the terminal),
  # Sarabun for Thai text, Noto for everything else.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka-term # alacritty's terminal font (home/alacritty.nix)
    # "Symbols Nerd Font Mono" — the default family of emacs' nerd-icons
    # (doom-modeline/dired icons, home/emacs.nix). Without it Doom nags to run
    # M-x nerd-icons-install-fonts, which drops an untracked font in ~/.local.
    nerd-fonts.symbols-only
    # Emacs' last-resort glyph fallback (`doom doctor` warns without it) —
    # missing obscure glyphs can slow emacs badly. Unfree (allowUnfree is on).
    symbola
    sarabun-font # Thai text font (the fontconfig rules below prefer it)
    th-sarabun-psk # family "TH SarabunPSK" — for Thai official documents
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
    <!-- Noto's Thai faces are rejected for the same reason. Chromium/Skia
         glyph fallback never scores charset coverage: it sorts ALL fonts by
         the page language (Slack's UI is lang="en-US", so the lang=th rule
         above never fires) and takes the FIRST font in that list that has
         the glyph — and Noto Sans Thai sorts ahead of Sarabun (#152 vs #175
         for lang=en). No match rule can reorder that walk; the font has to
         leave the set. noto-fonts stays installed — every other script it
         covers is unaffected, and Thai is Sarabun's job anyway. -->
    <!-- Unifont goes too (also from fonts.enableDefaultPackages). With Noto
         Thai gone it became the next Thai-capable font in Chromium's walk:
         Chromium bundles its own fontconfig with its own caches, so ties
         break in a different order than fc-match shows, and Unifont beat
         Sarabun. Worse, it loads the bitmap unifont.otb face — its sfnt
         wrapper says fontformat=TrueType, slipping past Chromium's format
         filter, but Skia gets no outlines from it: Thai drew as INVISIBLE
         glyphs, not even tofu. Rejecting only the bitmap faces isn't
         enough (the scalable unifont.otf could still win the tie-break),
         so the whole family leaves the set — then Sarabun/TH SarabunPSK
         are the only Thai fonts left and the walk is deterministic.
         Obscure codepoints now show visible tofu, which beats invisible
         text. -->
    <selectfont>
      <rejectfont>
        <pattern><patelt name="family"><string>FreeSerif</string></patelt></pattern>
        <pattern><patelt name="family"><string>FreeSans</string></patelt></pattern>
        <pattern><patelt name="family"><string>FreeMono</string></patelt></pattern>
        <pattern><patelt name="family"><string>Noto Sans Thai</string></patelt></pattern>
        <pattern><patelt name="family"><string>Noto Sans Thai Looped</string></patelt></pattern>
        <pattern><patelt name="family"><string>Noto Serif Thai</string></patelt></pattern>
        <pattern><patelt name="family"><string>Unifont</string></patelt></pattern>
      </rejectfont>
    </selectfont>
    </fontconfig>
  '';
}
