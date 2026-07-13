# home/mangohud.nix — MangoHud, the in-game FPS/performance overlay.
# Deliberately NOT session-wide: it only appears in games whose Steam launch
# options say so, e.g. `gamemoderun mangohud %command%`. Right-Shift+F12
# toggles it while playing.
{ config, lib, pkgs, ... }:

let
  colors = import ./colors.nix;
  # MangoHud wants rrggbb WITHOUT the leading '#'; palette entries carry one.
  hex = c: lib.removePrefix "#" c;
in
{
  programs.mangohud = {
    enable = true;
    # Rendered to ~/.config/MangoHud/MangoHud.conf — see mangohud(1).
    # Booleans become key=1/0; anything not listed stays at MangoHud's default.
    settings = {
      # Compact preset: framerate + stutter graph + "is the hardware maxed
      # out / overheating" at a glance, nothing more.
      fps = true;
      frametime = true;    # frametime in ms next to the FPS number
      frame_timing = true; # the frametime graph — spikes = visible stutter
      gpu_stats = true;    # GPU load %
      gpu_temp = true;
      cpu_stats = true;    # CPU load %
      cpu_temp = true;
      hud_compact = true;  # tight one-column layout instead of the wide panel

      position = "top-left";
      font_size = 20;
      background_alpha = 0.4; # keep the game visible behind the box

      # Melange palette, same source of truth as every other themed app.
      background_color = hex colors.a.bg;
      text_color = hex colors.a.fg;
      gpu_color = hex colors.c.green;
      cpu_color = hex colors.c.blue;
      frametime_color = hex colors.b.green;

      # MangoHud's stock toggle bind, written out so it's discoverable here.
      toggle_hud = "Shift_R+F12";
    };
  };
}
