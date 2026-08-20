# home/orca-slicer.nix — OrcaSlicer file associations, the output half of the
# 3D-printing pipeline (models authored in home/freecad.nix). THE APP IS NOT
# HERE: it's a flatpak from modules/orca-slicer.nix (the nixpkgs build aborts
# on Bambu's network plugin — read that file before adding pkgs.orca-slicer
# back). No theme block: under flatpak it renders with the runtime's own GTK
# theme — accepted; no palette gets hardcoded to fake it. Settings, printer
# profiles, and the Bambu login live in the sandbox
# (~/.var/app/com.orcaslicer.OrcaSlicer/), app-owned, not Nix.
{ config, lib, pkgs, ... }:

{
  # Mirrors the app's own MimeType= line; the id is
  # com.orcaslicer.OrcaSlicer.desktop (a wrong id fails silently). The id
  # survives the flatpak move: flatpak exports the real desktop file onto
  # XDG_DATA_DIRS. xdg.mimeApps.enable lives in home/default.nix.
  #
  # MESHES only — `model/step` moved to home/freecad.nix (STEP is solid
  # geometry; the modeller can edit it, the slicer would only tessellate).
  # Don't add it back without deleting it there: two defaultApplications
  # entries for one type is an option conflict and fails the eval.
  xdg.mimeApps.defaultApplications = {
    "model/3mf" = "com.orcaslicer.OrcaSlicer.desktop"; # Bambu/Orca native project format
    "application/vnd.ms-3mfdocument" = "com.orcaslicer.OrcaSlicer.desktop"; # same thing, older mime name
    "model/stl" = "com.orcaslicer.OrcaSlicer.desktop";
    "application/prs.wavefront-obj" = "com.orcaslicer.OrcaSlicer.desktop";
    "application/x-amf" = "com.orcaslicer.OrcaSlicer.desktop";
    # The URL scheme behind "Open in OrcaSlicer" on MakerWorld/Printables —
    # registering it is what makes one-click browser imports work.
    "x-scheme-handler/orcaslicer" = "com.orcaslicer.OrcaSlicer.desktop";
  };
}
