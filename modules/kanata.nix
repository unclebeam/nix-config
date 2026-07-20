# kanata.nix — key remapping at the evdev level, below the compositor.
# Because kanata rewrites events before anything else sees them, the
# remap works everywhere: hyprland, TTYs, even the DMS greeter at login —
# unlike an xkb option, which only applies inside the graphical session.
#
# Thinkpad-only since 2026-07-20: the PC types on a ZSA board, and its
# firmware (flashed via Oryx) is the right place for remaps there — so the
# PC dropped this import rather than carry a software copy of the same idea.
{ config, lib, pkgs, ... }:

{
  services.kanata = {
    enable = true;
    keyboards.default = {
      # Empty list = grab every keyboard, so any external board plugged
      # into the thinkpad behaves exactly like the internal one.
      devices = [ ];
      # defsrc below only lists caps/f/j, so kanata would normally ignore
      # every other key. But tap-hold needs to SEE those presses —
      # "another key went down while caps is held" is exactly its signal
      # to commit to the hold action. Without this line, chords would
      # hang until the 200ms timeout.
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
