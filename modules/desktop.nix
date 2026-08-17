# desktop.nix — compositor-agnostic desktop infrastructure: Wayland-wide
# env, the GTK portal fallback, and fonts. Compositor-specific bits stay in
# modules/niri.nix; the login greeter (Noctalia on greetd) lives in
# modules/noctalia-greeter.nix. (This file was split out when hyprland first
# ran alongside sway; it kept its role through every compositor era since —
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

  # IBM Plex Mono UNPATCHED, and only that — the plain-text sibling of the
  # BlexMono Nerd Font the editors now use (see fonts.packages below). Distinct
  # fontconfig family names ("IBM Plex Mono" vs "BlexMono Nerd Font"), so the
  # two coexist without the duplicate-faces problem described further down.
  # nixpkgs has no split package: pkgs.ibm-plex
  # is one ~287M bundle of Sans/Serif/Mono/Math, Condensed, and the Arabic,
  # Devanagari, Hebrew, CJK and Thai scripts. We want the coding face alone, so
  # copy the 16 Mono faces out (~1.4M) and leave the rest behind. Keeping the
  # bundle out of the font set also keeps its two Thai families out of
  # Chromium's fallback walk — see the rejectfont block below for why any new
  # Thai-capable font is a hazard here.
  # .otf and not .ttf: upstream ships the same 16 faces in both formats, and
  # installing both would show fontconfig 32 faces for one family. OTF (CFF
  # outlines) is IBM Plex's canonical format.
  # NB: the glob must stay IBMPlexMono-* — a looser IBMPlex* would drag in
  # IBMPlexMath-Regular.otf, which sits in the same directory.
  # The full bundle is still fetched ONCE as a build input; it never enters the
  # system closure (only this 1.4M subset does) and nix.gc in core.nix reclaims
  # it like any other build-time dependency.
  ibm-plex-mono = pkgs.stdenvNoCC.mkDerivation {
    pname = "ibm-plex-mono";
    inherit (pkgs.ibm-plex) version;
    src = pkgs.ibm-plex;
    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      cp share/fonts/opentype/IBMPlexMono-*.otf "$out/share/fonts/opentype/"
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
  # interfaces neither implements. Kept here so this file stays a working
  # baseline for any compositor.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # ── Fonts ──────────────────────────────────────────────────────────────
  # Mono fonts (JetBrainsMono for the Qt UI, BlexMono for the terminal AND
  # Doom, Lilex and IosevkaTerm kept as revert targets, plain Plex Mono
  # installed but unused), Sarabun for Thai text, Noto for everything else.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # The coding font for BOTH alacritty (home/alacritty.nix) and Doom
    # (home/doom/config.el) — family "BlexMono Nerd Font Mono" in each. On
    # trial as of 2026-08-09, replacing Lilex in both.
    # "BlexMono" is Nerd Fonts' patch of IBM Plex Mono: identical outlines,
    # renamed only to stay clear of IBM's trademark. Patched rather than plain
    # Plex (the derivation in the let block above) because starship's prompt
    # and Doom's nerd-icons need those glyphs IN the font — nothing installs a
    # nerd-symbols fallback rule into /etc/fonts/conf.d, so plain Plex would
    # leave them to generic fontconfig glyph fallback at another font's metrics.
    nerd-fonts.blex-mono
    # No longer referenced by anything — kept ON PURPOSE as this trial's
    # immediate revert target ("Lilex Nerd Font Mono", one string per config).
    # Lilex is itself IBM Plex Mono plus ligatures, which is why the sizes in
    # alacritty/Doom carried over to BlexMono untouched.
    nerd-fonts.lilex
    # The revert target one step further back, from before the Lilex trial.
    # Same deal: kept so backing out stays a one-line edit per config with no
    # package churn. Drop this line only once a coding font is settled.
    nerd-fonts.iosevka-term
    # "Symbols Nerd Font Mono" — the default family of emacs' nerd-icons
    # (doom-modeline/dired icons, home/emacs.nix). Without it Doom nags to run
    # M-x nerd-icons-install-fonts, which drops an untracked font in ~/.local.
    nerd-fonts.symbols-only
    # Emacs' last-resort glyph fallback (`doom doctor` warns without it) —
    # missing obscure glyphs can slow emacs badly. Unfree (allowUnfree is on).
    symbola
    # IBM Plex Mono, UNPATCHED — installed on purpose, used by NOTHING on
    # purpose. The editors are on the Nerd-patched BlexMono above; this is the
    # same design without the added glyphs, kept available for documents/GUI
    # apps and as the fallback if the patched build ever misbehaves.
    # (Definition + why it's a subset: the let block at the top of this file.)
    ibm-plex-mono
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
