# desktop.nix — desktop infrastructure shared by BOTH sessions (sway and
# hyprland): the greeter that picks a session, Wayland-wide env, the GTK
# portal, and fonts. Compositor-specific bits stay in modules/sway.nix and
# modules/hyprland.nix. This file exists because a second session appeared —
# per the repo rule, settings are only promoted to a shared file once a
# second consumer shows up.
{ config, lib, pkgs, ... }:

{
  # ── greetd + tuigreet ──────────────────────────────────────────────────
  # greetd is a tiny display manager; tuigreet is its console UI.
  # After login it execs the chosen compositor directly — no
  # desktop-manager layer at all.
  services.greetd = {
    enable = true;
    # New in 26.05: proper TTY handling for text greeters (stops kernel
    # messages from scribbling over the UI). The VT is fixed to VT1.
    useTextGreeter = true;
    settings.default_session = {
      # --remember: pre-fill last username. --time: clock in the greeter.
      # --sessions: F3 opens a menu of every installed wayland session —
      #   sessionData.desktops collects the .desktop files that
      #   programs.sway / programs.hyprland install (sway, hyprland).
      #   NB: the menu also shows "Hyprland (UWSM)" — the nixpkgs hyprland
      #   package ships that second session file and it can't be filtered
      #   out without breaking the sessionPackages assertion. Don't pick
      #   it; uwsm is deliberately not used here.
      # --remember-session: a manual pick sticks across reboots.
      # --cmd Hyprland: the default when nothing was ever picked ("Hyprland"
      #   is the cap_sys_nice security wrapper from programs.hyprland).
      command =
        "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session "
        + "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions "
        + "--cmd Hyprland";
      user = "greeter";
    };
  };

  # Chromium-based apps (Brave) run native Wayland instead of XWayland when
  # this is set. Electron apps honor it too. Session-agnostic.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # xdg-desktop-portal is how sandbox-ish desktop APIs work on Wayland:
  # screen sharing, screenshots, file pickers. The GTK portal covers the
  # generic interfaces (file chooser…) for both sessions; each compositor
  # module adds its own ScreenCast/Screenshot backend (wlr for sway,
  # xdg-desktop-portal-hyprland for hyprland) plus the portals.conf that
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
