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
# a consistent 9-10 C LOW (measured against Tctl: 60/68, 57/65, 55/63,
# 52/62, 50/60, 48/58). The visible symptom was btop saying 69 C while the
# Noctalia bar said 79 C for the same instant — Noctalia auto-detects
# `k10temp/Tctl` correctly and was the honest one. Pinning btop to the same
# sensor makes the two agree.
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
  # expose `Package id 0`, and btop's auto-detect already finds it. Adding a
  # guessed sensor name there would be inventing a hardware fact — and with
  # no entry the settings set below is empty, so home-manager writes no
  # btop.conf at all and btop behaves exactly as it does today.
  cpuSensor = { unclebeam-pc = "k10temp/Tctl"; }.${hostName} or null;
in
{
  programs.btop = {
    enable = true;
    # Rendered to ~/.config/btop/btop.conf. Anything not listed stays at
    # btop's default; an unrecognised sensor name silently falls back to
    # "Auto", i.e. today's behaviour, so a wrong string can't break btop.
    settings = lib.optionalAttrs (cpuSensor != null) {
      cpu_sensor = cpuSensor;
    };
  };
}
