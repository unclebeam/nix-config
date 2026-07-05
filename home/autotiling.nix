# home/autotiling.nix — automatic split-direction switching for sway.
# autotiling watches the focused window over sway IPC and toggles the split
# h/v based on which dimension is longer, so new windows tile the natural
# way without manual $mod+v / $mod+b. Run as a user service bound to the
# sway session (same rationale as waybar: clean restarts + journalctl logs)
# rather than an `exec` line in home/sway.nix.
{ pkgs, ... }:

{
  systemd.user.services.autotiling = {
    Unit = {
      Description = "autotiling — dynamic split orientation for sway";
      # sway-session.target is brought up by home-manager's sway systemd
      # integration once SWAYSOCK is exported into the user session, so
      # binding to it guarantees autotiling can reach the IPC socket.
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.autotiling}/bin/autotiling";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "sway-session.target" ];
  };
}
