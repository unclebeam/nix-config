# home/waybar.nix — status bar. Runs as a systemd user service bound to
# sway-session.target (started by home-manager's sway integration).
# All colors are interpolated from colors.nix into the CSS below.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
in
{
  programs.waybar = {
    enable = true;
    # Start via systemd (sway-session.target) instead of an `exec` line in
    # the sway config — restarts cleanly, logs land in `journalctl --user`.
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;

      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

      "sway/workspaces" = {
        disable-scroll = true;
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
      #workspaces button.focused {
        color: ${colors.a.fg};
        background: ${colors.a.sel};
        border-bottom: 2px solid ${colors.b.yellow};
      }
      #workspaces button.urgent {
        color: ${colors.a.fg};
        background: ${colors.d.red};
      }

      #mode {
        color: ${colors.a.bg};
        background: ${colors.b.yellow};
        padding: 0 10px;
      }

      #clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
        padding: 0 10px;
        color: ${colors.a.fg};
      }

      #pulseaudio { color: ${colors.b.yellow}; }
      #network    { color: ${colors.b.cyan}; }
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
