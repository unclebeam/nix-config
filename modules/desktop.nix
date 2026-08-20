# desktop.nix — compositor-agnostic desktop infrastructure: Wayland-wide env,
# the GTK portal fallback, and fonts. Compositor-specific bits stay in
# modules/niri.nix; the greeter in modules/dms-greeter.nix.
{ config, lib, pkgs, ... }:

let
  # TH Sarabun PSK — the DIP/SIPA font Thai official documents require. Not in
  # nixpkgs (pkgs.sarabun-font is Google's different "Sarabun"; internal family
  # names differ so both coexist), so the TTFs are vendored in-repo.
  th-sarabun-psk = pkgs.stdenvNoCC.mkDerivation {
    pname = "th-sarabun-psk";
    version = "1.0";
    src = ./fonts/th-sarabun-psk;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp *.ttf "$out/share/fonts/truetype/"
    '';
  };

  # IBM Plex Mono only — nixpkgs' pkgs.ibm-plex is one ~287M bundle whose Thai
  # families would join Chromium's fallback walk (see rejectfont below), so
  # copy out just the 16 Mono faces. OTF only (upstream ships both formats;
  # installing both doubles the face count). The glob must stay IBMPlexMono-*:
  # IBMPlex* would drag in IBMPlexMath from the same directory.
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
  # Chromium/Electron apps run native Wayland instead of XWayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Trailing entry in niri's `default=gnome;gtk` routing, and the direct
  # target for Access/Notification. Kept here so this file stays a working
  # baseline for any compositor.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # ── Fonts ──────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Qt UI mono
    # The coding font for both alacritty and Doom ("BlexMono Nerd Font Mono").
    # Nerd-patched IBM Plex Mono, patched rather than plain because starship
    # and nerd-icons need the glyphs IN the font — nothing installs a
    # nerd-symbols fontconfig fallback.
    nerd-fonts.blex-mono
    # Unreferenced revert targets for the coding font (one string per config
    # to back out); drop once a font is settled.
    nerd-fonts.lilex
    nerd-fonts.iosevka-term
    # Default family of emacs' nerd-icons; without it Doom nags to install an
    # untracked font into ~/.local.
    nerd-fonts.symbols-only
    # Emacs' last-resort glyph fallback (`doom doctor` warns without it).
    symbola
    # Installed but used by nothing on purpose: the unpatched sibling of
    # BlexMono, for documents and as fallback if the patched build misbehaves.
    ibm-plex-mono
    sarabun-font # Thai text (fontconfig rules below prefer it)
    th-sarabun-psk # family "TH SarabunPSK" — Thai official documents
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Prefer Sarabun for Thai. NB: localConf becomes /etc/fonts/local.conf
  # verbatim and must be ONE complete XML document — extra top-level elements
  # make fontconfig silently drop the whole file.
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
