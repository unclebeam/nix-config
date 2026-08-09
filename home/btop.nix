# home/btop.nix — btop, the terminal resource monitor.
#
# It lived in modules/core.nix as a config-less system package until it grew
# exactly one setting: which hwmon sensor counts as "the CPU temperature".
#
# WHY that setting is needed on the PC. btop's auto-detection looks for a
# sensor labelled `Package id 0` (Intel) or `Tdie` (older AMD). This Ryzen's
# k10temp exposes neither — only `Tctl`, `Tccd1`, `Tccd2` — so auto-detect
# falls through to whatever hwmon entry comes first and lands on the ASUS
# EC's board sensor, `asusec/CPU`. That one is socket-side: it lags and reads
# a consistent 9-10 C LOW. Left alone, btop showed 69 C while the Noctalia
# bar showed 79 C for the same instant.
#
# WHAT THE CHANNELS ARE. `tempN` is a hwmon registration INDEX, not a core —
# k10temp on this part publishes temp1=Tctl, temp3=Tccd1, temp4=Tccd2, and no
# temp2 (that channel is Tdie, which the kernel only creates when the part
# has a nonzero control offset — the old Threadripper 1000/2000 "+27 C" case).
# So there is genuinely NO additive offset here, and Ryzen exposes no per-core
# sensor at all: the only readings that exist are one per chiplet plus the
# package value.
#
# WHY Tccd1 and not Tctl. Both are honest readings of DIFFERENT THINGS:
#   * Tccd1/Tccd2 are the raw per-CCD die sensors — the actual silicon
#     temperature, which is what we want on screen. They are also RAW in the
#     unhelpful sense: sampled live they swing wildly (Tccd1 measured
#     83 -> 54 -> 74 C within a few seconds).
#   * Tctl is the package CONTROL value the boost algorithm and the fan
#     curves consume. It behaves like a FILTERED value riding near the
#     hottest die and decaying slowly — over the same seconds the Tccd
#     sensors were thrashing, Tctl slid smoothly 79 -> 72. That filtering is
#     why it sits ~10 C above the dies at idle (brief boost spikes push it up
#     and it decays back slowly), and it is NOT an upper bound: it was
#     measured at 80 while Tccd1 read 83.
# Picking Tccd1 also makes btop's CPU box internally consistent: btop fills
# its per-core column from the Tccd sensors (its collector special-cases the
# `Tccd` label right alongside `Core`/`Package id`/`Tdie`), so with Tctl as
# the headline the box showed 54 C on top of 24 rows of 44 C. Now the
# headline is the same quantity as the rows.
#
# THE COST, stated plainly: one number cannot represent two chiplets. This
# 12-core part is 2 CCDs (L3 domains 0-5,12-17 and 6-11,18-23), and CCD1 is
# NOT reliably the hotter one — measured Tccd1=54 while Tccd2=67. So this
# headline can under-report the hottest chiplet by better than 10 C, and it
# will visibly jitter. btop's per-core rows still show both dies; that is
# where the split is readable. Deliberate trade for seeing raw silicon.
# The Noctalia bar is pinned to the same sensor, in home/noctalia/config.toml.
#
# Trade-off of managing btop at all: `settings` renders ~/.config/btop/btop.conf
# as a read-only store symlink, so tweaks made inside btop's own Options menu
# (Esc -> Options) no longer survive a restart. Future btop settings go HERE.
{
  lib,
  osConfig,
  ...
}:

let
  # WHICH machine this is, decided at EVAL time — same trick as
  # home/hyprland.nix uses to pick the per-host monitor file. `osConfig` is
  # the NixOS config, reachable from every home module because home-manager
  # is wired in as a NixOS module.
  hostName = osConfig.networking.hostName;

  # Per-host CPU sensor pin; null means "leave btop on its own Auto".
  # The thinkpad is deliberately ABSENT: it's Intel, its coretemp does
  # expose `Package id 0` — which on Intel IS the die reading, with none of
  # the control-value indirection above — and btop's auto-detect already
  # finds it. Adding a guessed sensor name there would be inventing a
  # hardware fact; and with no entry the settings set below is empty, so
  # home-manager writes no btop.conf at all and btop behaves as it does now.
  cpuSensor = { unclebeam-pc = "k10temp/Tccd1"; }.${hostName} or null;
in
{
  programs.btop = {
    enable = true;
    # Rendered to ~/.config/btop/btop.conf. Anything not listed stays at
    # btop's default; an unrecognised sensor name silently falls back to
    # "Auto", i.e. the board-sensor behaviour above, so a wrong string
    # degrades rather than breaking btop.
    settings = lib.optionalAttrs (cpuSensor != null) {
      cpu_sensor = cpuSensor;
    };
  };
}
