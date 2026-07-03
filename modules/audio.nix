# audio.nix — PipeWire, the one audio server to rule ALSA/Pulse/JACK.
{ config, lib, pkgs, ... }:

{
  # rtkit hands out realtime scheduling priority to the audio server —
  # without it you get crackling under load. The pipewire module
  # integrates with it automatically when enabled.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    # Pretend to be ALSA for old apps talking straight to the kernel API…
    alsa.enable = true;
    alsa.support32Bit = true; # …including 32-bit games under Steam/Proton
    # …and pretend to be PulseAudio for everything built against Pulse
    # (browsers, most desktop apps). pavucontrol etc. just work.
    pulse.enable = true;
    # WirePlumber (the session manager) is enabled by default; JACK
    # emulation is off by default — enable services.pipewire.jack.enable
    # if you ever do pro audio.
  };
}
