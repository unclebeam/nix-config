# home/swaync.nix — SwayNotificationCenter, the notification daemon.
#
# It replaced mako (2026-07) for one concrete reason: ACTION BUTTONS. Agent
# prompts like blueman's Bluetooth "Pairing request" arrive as notifications
# with named Confirm/Deny actions and no default action. mako advertises the
# `actions` capability but renders no buttons and a click only fires the
# *default* action — so those prompts could never be answered and pairing
# stalled until timeout (mako#588 is the open feature request; blueman
# declined a dialog fallback in blueman#2477). swaync draws real buttons.
#
# Unlike mako (D-Bus activated), home-manager runs swaync as a systemd user
# service bound to graphical-session.target — it starts with niri, dies with
# it. swaync also has a notification-center panel (`swaync-client -t` toggles
# it); deliberately NOT wired into Waybar — the restrained look stands.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
in
{
  services.swaync = {
    enable = true;

    # Written to ~/.config/swaync/config.json. Mirrors the old mako behavior:
    # top-right, 8s, critical stays until dismissed.
    settings = {
      positionX = "right";
      positionY = "top";
      timeout = 8; # seconds (mako counted in ms)
      timeout-low = 8;
      timeout-critical = 0; # 0 = stay until dismissed
      notification-window-width = 360;
    };

    # Written to ~/.config/swaync/style.css, REPLACING swaync's stock
    # stylesheet — anything not styled here falls back to bare GTK, so this
    # covers every surface we actually see. Class names come from swaync's
    # default style.css; inspect live with GTK_DEBUG=interactive if a
    # selector stops matching after an upgrade.
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 11pt;
      }

      .notification {
        background: ${colors.a.float};
        border: 2px solid ${colors.a.com};
        border-radius: 0;
        box-shadow: none;
      }
      .notification-content {
        background: transparent;
        padding: 10px;
      }
      .summary, .body, .time {
        background: transparent;
        color: ${colors.a.fg};
      }

      /* Urgency accents — same scheme the mako config used. */
      .notification.low { border-color: ${colors.a.ui}; }
      .notification.low .summary,
      .notification.low .body { color: ${colors.a.com}; }
      .notification.critical { border-color: ${colors.b.red}; }

      /* THE reason this file exists: real, clickable action buttons
         (blueman's Confirm/Deny lands here). */
      .notification-action {
        background: ${colors.a.sel};
        color: ${colors.a.fg};
        border: 1px solid ${colors.a.ui};
        border-radius: 0;
      }
      .notification-action:hover {
        background: ${colors.a.ui};
        color: ${colors.a.bg};
      }

      .close-button {
        background: transparent;
        color: ${colors.a.com};
      }

      /* The pull-down panel (swaync-client -t). Kept to the same palette. */
      .control-center {
        background: ${colors.a.float};
        border: 2px solid ${colors.a.com};
        color: ${colors.a.fg};
      }
      .control-center .notification { border-width: 1px; }
      .widget-title { color: ${colors.a.fg}; }
      .widget-title > button {
        background: ${colors.a.sel};
        color: ${colors.a.fg};
        border: 1px solid ${colors.a.ui};
      }
    '';
  };
}
