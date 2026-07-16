# polkit-agent.nix — plasma-polkit-agent, the GUI that shows polkit's
# authentication prompts. Added 2026-07 by explicit request as part of the
# KDE-plumbing migration, REVERSING the earlier deliberate no-agent setup
# (which dated back to hyprland: 1Password ships its own polkit policy and
# nothing else had needed GUI auth). With an agent running, things like
# `fprintd-enroll` (without sudo), udisks operations beyond the default
# rules, and `pkexec` get a Breeze password/fingerprint dialog instead of a
# silent denial. Removing this file + import lines restores the old
# behavior exactly.
{ config, lib, pkgs, ... }:

{
  # polkit itself is already on (other modules pull it in); explicit here
  # because an auth agent without polkit is meaningless.
  security.polkit.enable = true;

  # The package ships its unit in share/systemd/user, which systemd.packages
  # does not scan (only etc/ and lib/systemd/user) — Plasma sidesteps that
  # by linking all of /share. So the unit is declared here, mirroring the
  # upstream one field-for-field; BusName makes it Type=dbus, i.e. systemd
  # considers it started only once the agent owns its bus name.
  systemd.user.services.plasma-polkit-agent = {
    description = "KDE PolicyKit Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      BusName = "org.kde.polkit-kde-authentication-agent-1";
      Slice = "background.slice";
      TimeoutStopSec = "5sec";
      Restart = "on-failure";
    };
  };
}
