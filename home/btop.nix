# home/btop.nix — btop with one setting: which hwmon sensor is "the CPU
# temperature" on the PC.
#
# Why: btop's auto-detect looks for `Package id 0` (Intel) or `Tdie` (older
# AMD); this Ryzen's k10temp exposes only Tctl/Tccd1/Tccd2, so auto-detect
# falls through to the ASUS EC's socket-side board sensor, which lags and
# reads ~10 C low. Tccd1 rather than Tctl: Tccd is the raw die silicon
# (jittery), Tctl is the filtered package control value the fan curves use
# (~10 C above the dies at idle, and not an upper bound) — and btop fills its
# per-core rows from the Tccd sensors, so Tccd1 keeps headline and rows the
# same quantity. Cost, stated plainly: this part is 2 CCDs and CCD1 is not
# reliably the hotter one, so the headline can under-report the hottest
# chiplet by >10 C; the per-core rows show both dies. Deliberate trade for
# raw silicon. (The DMS bar auto-detects and has no equivalent pin —
# accepted; btop is where temperature gets read.)
#
# Trade-off of managing btop at all: `settings` renders btop.conf as a
# read-only store symlink, so in-app Options tweaks don't survive a restart.
# Future btop settings go here.
{
  lib,
  osConfig,
  ...
}:

let
  # osConfig = the NixOS config, reachable because home-manager is wired in
  # as a NixOS module.
  hostName = osConfig.networking.hostName;

  # Per-host pin; null = btop's own Auto. The thinkpad is deliberately
  # absent: Intel coretemp exposes `Package id 0` (which IS the die reading)
  # and auto-detect finds it — a guessed sensor name would be inventing a
  # hardware fact. With no entry the settings set is empty and no btop.conf
  # is written at all.
  cpuSensor = { unclebeam-pc = "k10temp/Tccd1"; }.${hostName} or null;
in
{
  programs.btop = {
    enable = true;
    # An unrecognised sensor name silently falls back to Auto, so a wrong
    # string degrades rather than breaking btop.
    settings = lib.optionalAttrs (cpuSensor != null) {
      cpu_sensor = cpuSensor;
    };
  };
}
