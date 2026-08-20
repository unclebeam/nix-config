# home/google-drive.nix — Google Drive mounted at ~/GoogleDrive via rclone
# (a FUSE mount is just a folder; Nautilus browses it natively).
#
# NOT home-manager's programs.rclone: declaring remotes there regenerates
# rclone.conf on every switch, wiping the OAuth token `rclone config`
# stored. The token is inherently stateful, so the config file stays
# imperative and only the mount unit is declared.
#
# ONE-TIME SETUP (per machine):
#   rclone config
#     n) new remote, name: gdrive     <- MUST be "gdrive", the unit uses it
#     type: drive, scope: 1 (full access), rest default, browser OAuth
#   systemctl --user start rclone-gdrive.service
#   Blank client_id works but Google throttles rclone's shared client; if
#   Drive feels slow, create your own Desktop-app OAuth client and PUBLISH
#   the consent screen to production (a "Testing" app's tokens expire in 7
#   days), then re-run `rclone config`.
{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "rclone FUSE mount: gdrive: -> ~/GoogleDrive";
      # Until `rclone config` has produced a token, skip cleanly at login
      # instead of crash-looping.
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      # rclone announces readiness via sd_notify once the FUSE filesystem is
      # actually up — dependents never see a half-mounted dir.
      Type = "notify";
      # User FUSE mounts need the setuid fusermount3 wrapper in
      # /run/wrappers/bin, which user units don't have on PATH by default.
      Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
      # vfs-cache-mode full: the only mode where every normal file operation
      # behaves like a real disk.
      ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full gdrive: %h/GoogleDrive";
      Restart = "on-failure";
    };
    # Mounts at login, unmounts at logout (rclone handles SIGTERM).
    Install.WantedBy = [ "default.target" ];
  };
}
