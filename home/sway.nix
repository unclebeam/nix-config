# home/sway.nix — the USER half of sway: keybinds, colors, lock/idle.
# (The session/greeter/portal plumbing is system-side in modules/sway.nix.)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  colors = import ./colors.nix;
  # swaylock wants colors as rrggbb without the leading '#'
  raw = c: lib.removePrefix "#" c;

  mod = "Mod4"; # the Super/Windows key
  term = "alacritty";
in
{
  wayland.windowManager.sway = {
    enable = true;
    # Use the sway package installed by the system module (programs.sway) —
    # avoids two sway builds and keeps the session wrapper in charge.
    package = null;
    # systemd integration is on by default: home-manager exports
    # WAYLAND_DISPLAY & friends into the systemd user session and starts
    # sway-session.target — this is exactly what waybar (as a user service)
    # and xdg-desktop-portal-wlr (screen sharing) need.

    config = {
      modifier = mod;
      terminal = term;
      menu = "fuzzel"; # launched by $mod+d below (sway's default menu bind)

      # Start on workspace 1 — without this sway can land on an arbitrary
      # workspace at launch (it was coming up on 10).
      defaultWorkspace = "workspace number 1";

      # Waybar runs as a systemd user service (home/waybar.nix), so sway's
      # built-in bar is disabled entirely.
      bars = [ ];

      # Default font for window titles (tiling means you rarely see them).
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size = 10.0;
      };

      # No wallpaper manager, just a solid melange background everywhere.
      output."*".bg = "${colors.a.bg} solid_color";

      # Outputs are matched by "make model serial" (from `swaymsg -t get_outputs`),
      # never by connector name — entries that don't match a plugged-in monitor
      # are silently ignored, which is what lets both hosts share this file.
      output = {
        "Dell Inc. DELL U3225QE 27D4834" = {
          mode = "3840x2160@120Hz";
          scale = "1.5";
        };

        # GIGA-BYTE M28U — 28" 4K gaming panel (external, plugged into the
        # ThinkPad via DP-1). Pin the best mode the EDID advertises: 4K @ 144Hz.
        # Scale 1.25 gives logical 3072x1728 — more real estate than the Dell's
        # 1.5 on this slightly larger panel, without shrinking the UI to native-4K
        # size.
        "GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22060B005352" = {
          mode = "3840x2160@144Hz";
          scale = "1.25";
        };

        # The thinkpad's built-in OLED panel. Without this entry sway picks
        # 60Hz (the panel's first mode) and scale 2.0 — pinning gets us the
        # 120Hz the panel supports and 1.5 (logical 1920x1200, more real
        # estate than 2.0's 1440x900). adaptive_sync stays off on purpose:
        # VRR on OLED panels commonly causes brightness flicker.
        # ⚠ The double space before "Unknown" is real: the EDID model string
        # is "ATNA40HQ02-0 " with a trailing space. Don't "fix" it, or the
        # entry stops matching.
        "Samsung Display Corp. ATNA40HQ02-0  Unknown" = {
          mode = "2880x1800@120Hz";
          scale = "1.5";
        };
      };

      # Window borders, straight from the palette:
      # focused = warm comment-beige, everything else fades into the bg.
      colors = {
        focused = {
          border = colors.a.com;
          background = colors.a.float;
          text = colors.a.fg;
          indicator = colors.b.yellow; # split-direction hint
          childBorder = colors.a.com;
        };
        focusedInactive = {
          border = colors.a.sel;
          background = colors.a.float;
          text = colors.a.com;
          indicator = colors.a.sel;
          childBorder = colors.a.sel;
        };
        unfocused = {
          border = colors.a.float;
          background = colors.a.bg;
          text = colors.a.ui;
          indicator = colors.a.float;
          childBorder = colors.a.float;
        };
        urgent = {
          border = colors.b.red;
          background = colors.d.red;
          text = colors.a.fg;
          indicator = colors.b.red;
          childBorder = colors.b.red;
        };
      };

      window.titlebar = false; # borders only; titles waste vertical space
      window.border = 2;

      # Bind by physical keycode (--to-code), resolved against the FIRST
      # xkb layout (us). Without this, bindsym matches the keysym the active
      # layout produces — under the Thai layout $mod+1 emits "ๅ", not "1",
      # so workspace/letter shortcuts silently stop working. Keysyms that
      # don't translate to a code (the XF86 media keys) fall back to plain
      # keysym matching, so they keep working too.
      bindkeysToCode = true;

      # mkOptionDefault MERGES these into sway's default keybindings
      # ($mod+Return terminal, $mod+d menu, $mod+1..0 workspaces, etc.)
      # instead of replacing them wholesale.
      keybindings = lib.mkOptionDefault {
        # Media keys → PipeWire (wpctl is WirePlumber's control tool)
        "XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        # Backlight keys (laptop; harmless on the PC)
        "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

        # Screenshots always open the satty annotator (config in home/satty.nix),
        # which copies to clipboard AND saves a timestamped PNG to
        # ~/Pictures/Screenshots on save. Bare Print = whole screen;
        # Ctrl+Print = pick a region first. The region bind grabs slurp's
        # geometry into $sel FIRST so an Escape in slurp exits non-zero and
        # aborts the whole chain instead of handing satty an empty capture.
        "Print" = ''exec mkdir -p "$HOME/Pictures/Screenshots" && grim - | satty --filename -'';
        "Ctrl+Print" =
          ''exec sel="$(slurp)" && mkdir -p "$HOME/Pictures/Screenshots" && grim -g "$sel" - | satty --filename -'';

        # Lock now
        "${mod}+Escape" = "exec swaylock -f";
      };

      input = {
        # Keyboard: US + Thai, Alt+Shift cycles layouts. Applies to every
        # keyboard, including kanata's virtual one (kanata works below xkb,
        # so the capslock remap and the layout toggle don't fight).
        "type:keyboard" = {
          xkb_layout = "us,th";
          xkb_options = "grp:alt_shift_toggle";
        };

        # Mouse: natural scrolling, to match the touchpad below.
        "type:pointer" = {
          natural_scroll = "enabled";
        };

        # Touchpad (laptop): tap-to-click, natural scrolling, palm rejection.
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled"; # disable-while-typing
        };
      };
    };
  };

  # ── swaylock — themed lock screen ────────────────────────────────────────
  programs.swaylock = {
    enable = true;
    settings = {
      # swaylock takes rrggbb (no '#'), hence the `raw` helper.
      color = raw colors.a.bg;
      inside-color = raw colors.a.float;
      inside-clear-color = raw colors.a.sel;
      inside-ver-color = raw colors.a.sel;
      inside-wrong-color = raw colors.d.red;
      ring-color = raw colors.a.ui;
      ring-clear-color = raw colors.b.yellow;
      ring-ver-color = raw colors.b.green;
      ring-wrong-color = raw colors.b.red;
      key-hl-color = raw colors.b.yellow;
      text-color = raw colors.a.fg;
      text-clear-color = raw colors.a.fg;
      text-ver-color = raw colors.a.fg;
      text-wrong-color = raw colors.a.fg;
      separator-color = raw colors.a.bg;
      indicator-radius = 90;
      show-failed-attempts = true;
    };
  };

  # ── swayidle — lock, screen off, and lock-before-sleep ──────────────────
  services.swayidle = {
    enable = true;
    # Lock BEFORE the system suspends (lid close, systemctl suspend…).
    # Each event maps to its command string directly.
    events."before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
    timeouts = [
      # 5 min idle → lock
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      # 10 min idle → screens off (back on when you touch anything)
      {
        timeout = 600;
        command = "${pkgs.sway}/bin/swaymsg 'output * power off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * power on'";
      }
    ];
  };

  # Wayland desktop utilities used by the keybinds above.
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region selection
    wl-clipboard # wl-copy / wl-paste
    brightnessctl # backlight (keybinds above; PC just has no backlight device)
  ];
}
