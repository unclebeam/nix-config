# home/power.nix — Shutdown/Reboot as launcher entries.
#
# Instead of a dedicated power-menu keybind, these are ordinary .desktop
# entries: home-manager drops them into ~/.nix-profile/share/applications,
# the same place fuzzel (Mod+D) already finds every other app. Type
# "shut" or "reb", Enter, done.
#
# There is deliberately NO confirmation step — Enter on a fuzzy match
# powers off immediately. That tradeoff was accepted when choosing
# launcher entries over a dedicated menu; don't add a guard unprompted.
#
# No system-side half needed: the user is in wheel and logind's default
# polkit policy lets an active local session power off / reboot without
# authentication — bare systemctl just works.
{ config, lib, pkgs, ... }:

{
  xdg.desktopEntries = {
    shutdown = {
      name = "Shutdown";
      comment = "Power off this machine";
      # Exec resolves via the session PATH, like every other entry's Exec;
      # systemctl is guaranteed there on NixOS (/run/current-system/sw/bin).
      exec = "systemctl poweroff";
      # Standard freedesktop icon names; if the icon theme lacks them,
      # fuzzel just shows no icon — harmless.
      icon = "system-shutdown";
      terminal = false;
      categories = [ "System" ];
    };
    reboot = {
      name = "Reboot";
      comment = "Restart this machine";
      exec = "systemctl reboot";
      icon = "system-reboot";
      terminal = false;
      categories = [ "System" ];
    };
  };
}
