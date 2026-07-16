# home/google-drive.nix — Google Drive mounted at ~/GoogleDrive via rclone.
#
# Why rclone and not KDE's kio-gdrive: Google revoked KDE's OAuth client in
# June 2024 and upstream removed the Drive scope entirely (KDE bug 480779),
# so kio-gdrive can no longer be granted Drive access — it's a dead end.
# An rclone FUSE mount is just a folder, which Dolphin (and every other
# app) browses natively.
#
# Why NOT home-manager's programs.rclone: declaring any remotes.<name> there
# makes home-manager regenerate ~/.config/rclone/rclone.conf on every switch,
# wiping the OAuth token that `rclone config` stored (home-manager issue
# #8334). The token is inherently stateful, so the rclone config file stays
# imperative and only the mount unit is declared here.
#
# ONE-TIME SETUP (per machine):
#   rclone config
#     n) new remote, name: gdrive     <- MUST be "gdrive", the unit uses it
#     type: drive, scope: 1 (full access), leave the rest default,
#     auto config -> browser OAuth dance
#   systemctl --user start rclone-gdrive.service
#
#   client_id/secret: blank works (rclone's shared client), but that client
#   is throttled by Google. If Drive feels slow, create your own at
#   console.cloud.google.com: new project -> enable "Google Drive API" ->
#   OAuth consent screen (External) -> PUBLISH to production (a "Testing"
#   app's tokens expire after 7 days!) -> add a "Desktop app" OAuth client,
#   then re-run `rclone config` and paste the id/secret.
{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "rclone FUSE mount: gdrive: -> ~/GoogleDrive";
      # Until the one-time `rclone config` has produced a token, skip
      # cleanly at login (status: condition failed) instead of crash-looping.
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      # rclone mount announces readiness via sd_notify once the FUSE
      # filesystem is actually up — dependents never see a half-mounted dir.
      Type = "notify";
      # Mounting FUSE as a plain user needs the setuid fusermount3 wrapper,
      # which lives in /run/wrappers/bin — systemd user units don't have it
      # on PATH by default. (Same trick home-manager's rclone module uses.)
      Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
      # vfs-cache-mode full: local read/write cache (~/.cache/rclone), the
      # only mode where every normal file operation (seek-then-write, open
      # existing file for writing) behaves like a real disk.
      ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full gdrive: %h/GoogleDrive";
      Restart = "on-failure";
    };
    # default.target = "user session is up": mounts at login, unmounts at
    # logout (rclone handles SIGTERM and releases the FUSE mount).
    Install.WantedBy = [ "default.target" ];
  };
}
