# audio.nix — PipeWire, the one audio server for ALSA/Pulse/JACK.
{ config, lib, pkgs, ... }:

{
  # Realtime scheduling for the audio server; without it audio crackles
  # under load.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # 32-bit games under Steam/Proton
    pulse.enable = true;
    # WirePlumber is on by default; JACK emulation off — enable
    # services.pipewire.jack.enable for pro audio.
  };

  # Here, not core.nix: the mixer GUI should be removed with the audio stack.
  environment.systemPackages = [ pkgs.pavucontrol ];
}
