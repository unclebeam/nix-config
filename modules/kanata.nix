# kanata.nix — key remapping at the evdev level, below the compositor, so it
# works everywhere: niri, TTYs, the greeter. ThinkPad-only: the PC's ZSA
# board carries its remaps in firmware.
{ config, lib, pkgs, ... }:

{
  services.kanata = {
    enable = true;
    keyboards.default = {
      # Empty list = grab every keyboard, so an external board behaves like
      # the internal one.
      devices = [ ];
      # tap-hold must SEE unmapped presses ("another key went down while caps
      # is held" is its commit signal) — without this, chords hang until the
      # 200ms timeout.
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc caps f j)
        (defalias
          ;; tap-hold-press: released alone within 200ms -> esc; any other
          ;; key pressed while caps is down -> ctrl IMMEDIATELY, so
          ;; caps+c works at full typing speed instead of waiting out the
          ;; timeout. Plain capslock-toggling is gone on purpose.
          caps (tap-hold-press 200 200 esc lctl)
          ;; f/j: tap = the letter, hold = shift (home-row shift, one per
          ;; hand). tap-hold-RELEASE here, not -press like caps: on letter
          ;; keys a press-activated hold misfires during fast rolls ("fa"
          ;; would come out "A"). -release only commits to shift when the
          ;; other key is pressed AND released while f/j is still down —
          ;; the standard "permissive hold" for home-row mods. Trade-off:
          ;; holding f alone no longer auto-repeats "fff".
          f (tap-hold-release 200 200 f lsft)
          j (tap-hold-release 200 200 j rsft)
        )
        (deflayer base @caps @f @j)
      '';
    };
  };
}
