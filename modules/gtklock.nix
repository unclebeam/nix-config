# gtklock.nix — the lock screen, skinned to match the SilentSDDM greeter.
#
# Why a SYSTEM module when a lock screen is user-facing: home-manager 26.05
# has no programs.gtklock module, so this is a marked exception to the
# "apps with per-user config go in home/" rule. The nixpkgs module earns it:
# enabling programs.gtklock installs the package, writes
# /etc/xdg/gtklock/config.ini (gtklock searches XDG config dirs, user first,
# so a ~/.config/gtklock/ would override this), resolves each plugin package
# to its .so path, and — crucially — sets security.pam.services.gtklock.
# Without that PAM service, unlocking would silently fail (the same trap
# swaylock had; its PAM came from programs.niri). Hand-rolling all of that
# in home/ would just re-implement this module, badly.
#
# The other half of the lock pipeline stays user-side in home/niri.nix:
# swayidle's lock event runs `gtklock -d` (and the Super+Alt+L bind in
# home/niri/config.kdl routes through `loginctl lock-session`, unchanged).
# Removing gtklock = delete this file + the import in both hosts + point
# swayidle's lock event back at another locker.
#
# gtklock speaks ext-session-lock-v1 — the Wayland protocol niri requires
# from a locker (SDDM itself can never lock a session; it's a greeter only,
# which is why this file exists).
{ config, lib, pkgs, ... }:

let
  colors = import ../home/colors.nix;
in
{
  programs.gtklock = {
    enable = true;

    # Plugin modules (each is its own package; the NixOS module turns the
    # list into module= paths in config.ini):
    #  * userinfo  — avatar + username above the password box, like the
    #    greeter's login area. Data comes from AccountsService (below).
    #  * powerbar  — suspend/reboot/poweroff buttons, like the greeter's
    #    power menu. Defaults are already right: those three buttons,
    #    icon-only, running systemctl; user-switch/logout stay hidden
    #    because they have no default command.
    #  * playerctl — now-playing card with prev/play-pause/next via MPRIS
    #    (same mechanism as the XF86Audio* binds; playerctl the CLI is
    #    already in home/niri.nix). Only appears while media is playing.
    modules = with pkgs; [
      gtklock-userinfo-module
      gtklock-powerbar-module
      gtklock-playerctl-module
    ];

    # No [main] settings needed: gtklock's defaults already match the
    # greeter's clock — time "%R" (24h HH:MM) and date "%a, %b %d".

    # GTK3 CSS, same skin as the SilentSDDM "rei" overrides in
    # modules/desktop.nix: flat melange canvas, cream text, yellow accent.
    # Selectors are the widget *names* gtklock assigns (from its gtklock.ui
    # and each module's source) — NB the toplevel window's name is the
    # monitor connector, so the canvas matches the `window` type instead.
    # Colors interpolate straight from home/colors.nix: GTK CSS wants
    # '#'-prefixed hex, exactly what the palette holds.
    style = ''
      /* The canvas: everything inherits melange + the greeter's font. */
      window {
        background-color: ${colors.a.bg};
        color: ${colors.a.fg};
        font-family: "JetBrainsMono Nerd Font";
      }

      /* Big clock + date — the greeter's pre-login LockScreen look. */
      #clock-label {
        font-size: 88px;
      }
      #date-label {
        font-size: 20px;
        color: ${colors.a.com}; /* secondary, like the greeter's Date */
      }

      /* userinfo: the username under the avatar. */
      #user-name {
        font-size: 18px;
      }

      /* Password box — the greeter's PasswordInput: dark surface, quiet
         border at rest, yellow border once focused. background-image and
         box-shadow are cleared everywhere below because Adwaita paints
         its own gradients/shadows over plain background-color. */
      #input-label {
        color: ${colors.a.com};
      }
      #input-field {
        background-color: ${colors.a.float};
        background-image: none;
        color: ${colors.a.fg};
        caret-color: ${colors.a.fg};
        border: 1px solid ${colors.a.ui};
        border-radius: 8px;
        padding: 8px 12px;
        box-shadow: none;
      }
      #input-field:focus {
        border-color: ${colors.b.yellow};
      }

      /* Unlock button — the greeter's LoginButton when focused: filled
         yellow with dark content. Hover shifts to the muted yellow so
         the press reads. */
      #unlock-button {
        background-color: ${colors.b.yellow};
        background-image: none;
        color: ${colors.a.bg};
        border: none;
        border-radius: 8px;
        box-shadow: none;
        text-shadow: none;
      }
      #unlock-button:hover {
        background-color: ${colors.c.yellow};
      }

      /* PAM feedback — the greeter's WarningMessage colors. */
      #warning-label {
        color: ${colors.b.yellow};
      }
      #error-label {
        color: ${colors.b.red};
      }

      /* powerbar — skinned like the greeter's bottom menu row: cream
         icon on a quiet surface at rest, filled yellow under the
         pointer. */
      #powerbar-box button {
        background-color: ${colors.a.float};
        background-image: none;
        color: ${colors.a.fg};
        border: 1px solid ${colors.a.ui};
        border-radius: 8px;
        box-shadow: none;
      }
      #powerbar-box button:hover {
        background-color: ${colors.b.yellow};
        border-color: ${colors.b.yellow};
        color: ${colors.a.bg};
      }

      /* playerctl — the now-playing card: floating surface, secondary
         text for artist/album, bare icon buttons that light up yellow. */
      #playerctl-box {
        background-color: ${colors.a.float};
        border-radius: 12px;
        padding: 8px;
      }
      #album-label,
      #artist-label {
        color: ${colors.a.com};
      }
      #playerctl-box button {
        background-color: transparent;
        background-image: none;
        color: ${colors.a.fg};
        border: none;
        box-shadow: none;
      }
      #playerctl-box button:hover {
        color: ${colors.b.yellow};
      }
    '';
  };

  # The userinfo module reads the avatar and display name from the
  # AccountsService D-Bus daemon — without it the module has nothing to
  # query. Nothing else here enabled it (SDDM doesn't), and it's the same
  # source SilentSDDM reads avatars from, so setting one (an image at
  # /var/lib/AccountsService/icons/<user> + Icon= in
  # /var/lib/AccountsService/users/<user>) themes greeter and lock at once.
  services.accounts-daemon.enable = true;
}
