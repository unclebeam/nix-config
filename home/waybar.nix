# home/waybar.nix — status bar. Runs as a systemd user service bound to
# graphical-session.target, which BOTH sessions reach: hyprland via
# hyprland-session.target (home/hyprland.nix binds it there), niri via
# niri.service itself. All colors are interpolated from colors.nix into
# the CSS below.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;

  # `-p spotify,%any` = prefer Spotify when it's running, otherwise fall
  # back to whatever MPRIS player exists (VLC, a browser, ...).
  playerctl = "${pkgs.playerctl}/bin/playerctl -p spotify,%any";

  # Persistent script behind the custom/media module. A waybar custom
  # module with no `interval` re-renders on every stdout line, so this
  # loop prints one marquee frame per tick — that's what makes the title
  # scroll (waybar's built-in mpris module can only truncate, not scroll).
  # It is also the single source of truth for album art: on track change
  # it caches the cover and pokes the image module via SIGRTMIN+8.
  mediaTitle = pkgs.writeShellScript "waybar-media-title" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.curl pkgs.playerctl ]}:$PATH
    # Bash ''${var:offset:len} counts *characters* only under a UTF-8
    # locale — without this, non-ASCII titles garble mid-scroll.
    export LC_ALL=C.UTF-8
    # This script lives inside waybar.service's cgroup, so the SIGRTMIN+8
    # we send below is delivered to us too — and the default action of an
    # unhandled RT signal is terminate (waybar does not restart persistent
    # exec scripts). Ignore it.
    trap "" RTMIN+8

    ART_DIR="$HOME/.cache/waybar/media-art"
    mkdir -p "$ART_DIR"
    WIDTH=30   # visible title window, in characters
    SEP="   "  # gap between end and restart of the scrolling text

    signal_image() {
      # Tell the image module to re-read its `path`. --kill-whom=main
      # signals ONLY the waybar binary, not this script. (pkill by name
      # would silently match nothing: on NixOS the process is the wrapper
      # ".waybar-wrapped", not "waybar".)
      systemctl --user kill --kill-whom=main --signal=SIGRTMIN+8 waybar.service 2>/dev/null || true
    }

    update_art() {
      case "$1" in
        # Local players hand us a file:// URL — just point at the file.
        file://*) ln -sfn "''${1#file://}" "$ART_DIR/current" ;;
        # Spotify hands us https://i.scdn.co/... — cache by URL hash so
        # each cover is downloaded once ever.
        http*)
          f="$ART_DIR/$(printf %s "$1" | sha256sum | cut -c1-32)"
          [ -s "$f" ] || curl -sf --max-time 5 -o "$f" "$1" \
            || { rm -f "$ART_DIR/current"; signal_image; return; }
          ln -sfn "$f" "$ART_DIR/current" ;;
        # No/unknown art: drop the symlink so the image module hides.
        *) rm -f "$ART_DIR/current" ;;
      esac
      signal_image
    }

    last="" offset=0
    while :; do
      status=$(${playerctl} status 2>/dev/null) || status=""
      if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
        meta=$(${playerctl} metadata --format '{{artist}} - {{title}}' 2>/dev/null)
        if [ "$meta" != "$last" ]; then
          last="$meta"; offset=0
          update_art "$(${playerctl} metadata mpris:artUrl 2>/dev/null)"
        fi
        disp="$meta"
        [ "$status" = "Paused" ] && disp="⏸ $meta"
        if [ "''${#disp}" -le "$WIDTH" ]; then
          printf '%s\n' "$disp"
        else
          # Classic marquee: slide a WIDTH-char window over the doubled
          # string, one character per tick.
          s="$disp$SEP"; d="$s$s"
          printf '%s\n' "''${d:offset:WIDTH}"
          offset=$(( (offset + 1) % ''${#s} ))
        fi
      else
        # Nothing playing: an empty line hides custom/media; dropping the
        # art symlink + signalling hides the image too (no stale cover).
        if [ -n "$last" ]; then last=""; rm -f "$ART_DIR/current"; signal_image; fi
        echo ""
      fi
      sleep 0.4
    done
  '';

  # Persistent script behind custom/wifi-name: a fixed-width marquee of the
  # connected Wi-Fi SSID, mirroring mediaTitle. The network module owns the
  # icon + signal %; this only scrolls the name so the pill reads
  # "󰖩 87% - Name". Empty output when not on Wi-Fi collapses the module.
  wifiName = pkgs.writeShellScript "waybar-wifi-name" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.networkmanager ]}:$PATH
    export LC_ALL=C.UTF-8   # ''${var:off:len} counts chars only under UTF-8
    WIDTH=6    # visible name window, in characters (fixed)
    SEP="   "  # gap between end and restart of the scrolling text

    last="" offset=0 tick=0
    while :; do
      # nmcli is heavy to spawn; only re-read the SSID every ~2s (every 5th
      # 0.4s tick) — the marquee itself still advances every tick from cache.
      if [ $(( tick % 5 )) -eq 0 ]; then
        ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
               | awk -F: '/^yes:/{sub(/^yes:/,""); print; exit}')
      fi
      tick=$(( tick + 1 ))

      if [ -z "$ssid" ]; then
        # Not on Wi-Fi: empty line hides the module; network shows on its own.
        [ -n "$last" ] && { last=""; offset=0; }
        echo ""
      else
        [ "$ssid" != "$last" ] && { last="$ssid"; offset=0; }
        if [ "''${#ssid}" -le "$WIDTH" ]; then
          # Pad short names so the box width never changes (truly fixed).
          printf -- '- %-*s\n' "$WIDTH" "$ssid"
        else
          s="$ssid$SEP"; d="$s$s"
          printf -- '- %s\n' "''${d:offset:WIDTH}"
          offset=$(( (offset + 1) % ''${#s} ))
        fi
      fi
      sleep 0.4
    done
  '';
in
{
  # The media widget's scripts reference playerctl by store path; this
  # install is for interactive debugging (`playerctl status`) and future
  # media keybinds in hyprland.lua.
  home.packages = [ pkgs.playerctl ];

  programs.waybar = {
    enable = true;
    # Start via systemd (graphical-session.target) instead of an exec line
    # in the compositor config — restarts cleanly, logs land in
    # `journalctl --user`.
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;

      # Both compositors' workspace modules are listed while the niri trial
      # runs: waybar disables (with one log line) any module whose
      # compositor IPC socket is absent, so each session shows only its own.
      modules-left = [ "hyprland/workspaces" "niri/workspaces" "group/media" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "custom/wifi-name" "cpu" "memory" "battery" "tray" ];

      # Media pill (DankMaterialShell-style): cover art | waveform | title.
      # The group renders as one box (CSS id #media); each child hides on
      # its own when there's nothing to show, collapsing the pill to 0px.
      "group/media" = {
        orientation = "inherit";
        modules = [ "image" "cava" "custom/media" ];
      };

      image = {
        # A symlink maintained by the mediaTitle script; when it dangles
        # (nothing playing) the module hides itself.
        path = "${config.home.homeDirectory}/.cache/waybar/media-art/current";
        size = 20;  # bar is 28px; pill interior ~22px
        signal = 8; # re-read `path` on SIGRTMIN+8 from the title script
        tooltip = false;
        on-click = "${playerctl} play-pause";
      };

      cava = {
        # Built-in cava (compiled in via -Dcava=enabled) tapping pipewire
        # directly — no external cava process or config needed.
        method = "pipewire";
        source = "auto";
        framerate = 30;
        bars = 10;
        stereo = true;
        bar_delimiter = 0;      # bars butt up against each other
        input_delay = 2;        # give pipewire a moment at session start
        sleep_timer = 2;        # seconds of silence before...
        hide_on_silence = true; # ...the waveform disappears
        format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
      };

      "custom/media" = {
        exec = "${mediaTitle}"; # persistent: no `interval`, one frame per line
        escape = true;          # pango-escape & < > in track titles
        tooltip = false;
        on-click = "${playerctl} play-pause";
      };

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      pulseaudio = {
        # PipeWire speaks the Pulse protocol, so this module Just Works
        format = "󰕾 {volume}%";
        format-muted = "󰝟 muted";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      network = {
        format-wifi = "󰖩 {signalStrength}%";
        format-ethernet = "󰈀 {ifname}";
        format-disconnected = "󰖪 offline";
        tooltip-format = "{ifname}: {ipaddr}";
      };

      # Scrolling SSID name, glued to the right of the network module so the
      # pair reads "󰖩 87% - Name". Persistent marquee (see wifiName above);
      # empty when not on Wi-Fi, so on ethernet/offline it vanishes and the
      # network module looks exactly as it did before.
      "custom/wifi-name" = {
        exec = "${wifiName}";  # persistent: no `interval`, one frame per line
        escape = true;         # pango-escape < > & in SSIDs
        tooltip = false;
      };

      cpu.format = "󰻠 {usage}%";
      memory.format = "󰍛 {percentage}%";

      battery = {
        # Hidden automatically on the PC (no battery device).
        states = { warning = 25; critical = 10; };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
      };

      tray.spacing = 8;
    };

    # GTK CSS. Waybar ignores most of a normal GTK theme, so everything
    # visual is specified here — straight from the melange palette.
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: ${colors.a.bg};
        color: ${colors.a.fg};
        border-bottom: 2px solid ${colors.a.float};
      }

      #workspaces button {
        padding: 0 8px;
        color: ${colors.a.ui};
        background: transparent;
      }
      /* hyprland marks the current workspace .active; niri calls that one
         .focused (its .active = "visible on some monitor"). Style both so
         the bar looks identical under either session. */
      #workspaces button.active,
      #workspaces button.focused {
        color: ${colors.a.fg};
        background: ${colors.a.sel};
        border-bottom: 2px solid ${colors.b.yellow};
      }
      #workspaces button.urgent {
        color: ${colors.a.fg};
        background: ${colors.d.red};
      }

      /* Media widget. The group box stays styling-free (no background or
         padding) so that when every child hides (nothing playing) it
         collapses to 0px and the widget disappears entirely. */
      #media {
        margin-left: 6px; /* breathing room from the workspace buttons */
      }
      #image {                /* cover art, leftmost */
        margin: 0 2px 0 6px; /* margin, not padding: GtkImage */
      }
      #cava {                 /* waveform */
        padding: 0 4px 0 6px;
        color: ${colors.b.yellow};
      }
      #custom-media {         /* scrolling title */
        padding: 0 10px 0 2px;
        color: ${colors.a.com};
      }

      #clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
        padding: 0 10px;
        color: ${colors.a.fg};
      }

      #pulseaudio { color: ${colors.b.yellow}; }
      #network    { color: ${colors.b.cyan}; }
      /* Scrolling SSID: same cyan as #network, no left padding so it butts
         up against it; collapses to 0px when the script prints nothing. */
      #custom-wifi-name { color: ${colors.b.cyan}; padding: 0 10px 0 0; }
      #cpu        { color: ${colors.b.green}; }
      #memory     { color: ${colors.b.blue}; }
      #battery    { color: ${colors.b.green}; }

      #battery.warning  { color: ${colors.b.yellow}; }
      #battery.critical { color: ${colors.b.red}; }
      #pulseaudio.muted { color: ${colors.a.ui}; }
      #network.disconnected { color: ${colors.a.ui}; }
    '';
  };
}
