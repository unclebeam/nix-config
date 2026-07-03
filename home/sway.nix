# home/sway.nix — the USER half of sway: keybinds, colors, lock/idle.
# (The session/greeter/portal plumbing is system-side in modules/sway.nix.)
{ config, lib, pkgs, ... }:

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

        # Screenshots: full screen / region → clipboard
        "Print" = "exec grim - | wl-copy";
        "Shift+Print" = ''exec grim -g "$(slurp)" - | wl-copy'';

        # Lock now
        "${mod}+Escape" = "exec swaylock -f";
      };

      input = {
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
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
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
    grim          # screenshot
    slurp         # region selection
    wl-clipboard  # wl-copy / wl-paste
    brightnessctl # backlight (keybinds above; PC just has no backlight device)
  ];
}
