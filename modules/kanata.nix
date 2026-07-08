# kanata.nix — key remapping at the evdev level, below the compositor.
# Because kanata rewrites events before anything else sees them, the
# remap works everywhere: hyprland, TTYs, even the greetd login screen —
# unlike an xkb option, which only applies inside the graphical session.
{ config, lib, pkgs, ... }:

{
  services.kanata = {
    enable = true;
    keyboards.default = {
      # Empty list = grab every keyboard, so the thinkpad's internal
      # keyboard and any USB board on the PC behave identically.
      devices = [ ];
      # defsrc below only lists `caps`, so kanata would normally ignore
      # every other key. But tap-hold-press needs to SEE those presses —
      # "another key went down while caps is held" is exactly its signal
      # to commit to ctrl. Without this line, chords would hang until
      # the 200ms timeout.
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc caps)
        ;; tap-hold-press: released alone within 200ms -> esc; any other
        ;; key pressed while caps is down -> ctrl IMMEDIATELY, so
        ;; caps+c works at full typing speed instead of waiting out the
        ;; timeout. Plain capslock-toggling is gone on purpose.
        (defalias caps (tap-hold-press 200 200 esc lctl))
        (deflayer base @caps)
      '';
    };
  };
}
