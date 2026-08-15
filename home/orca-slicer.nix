# home/orca-slicer.nix — OrcaSlicer, the slicer for the Bambu Lab X1 Carbon
# (3D model in → G-code/3MF out → sent to the printer). One file per intent:
# everything that exists because of OrcaSlicer lives here. It is the OUTPUT
# half of the pipeline; the models are authored in FreeCAD (home/freecad.nix),
# which is why the two files split the CAD/mesh mime types between them below.
#
# NOTE THE APP ITSELF IS NOT HERE. OrcaSlicer is installed as a FLATPAK from
# modules/orca-slicer.nix, because the nixpkgs build aborts on startup as soon
# as Bambu's network plugin loads — two libstdc++ copies in one process. That
# file carries the full diagnosis and the backtrace; read it before "fixing"
# this one by adding `pkgs.orca-slicer` back to home.packages. The same file
# also owns the LAN-discovery firewall holes. So this file is now down to the
# one thing that genuinely belongs to the user: file associations.
#
# Removing OrcaSlicer = delete both files + the import line here and in BOTH
# hosts + the nix-flatpak input in flake.nix.
#
# No Qt block and no theme colors: OrcaSlicer is GTK3/wxWidgets. Under flatpak
# it renders with the runtime's own GTK theme rather than picking up
# home/gtk.nix and Noctalia's GTK template — a sandbox has no view of those.
# That's accepted, not overlooked: per the repo's theming rule, an app either
# reaches the templates or stays at its defaults, and no palette gets
# hardcoded to fake it. Settings, printer profiles and the Bambu account login
# live inside the sandbox at ~/.var/app/com.orcaslicer.OrcaSlicer/, managed by
# the app itself, not Nix (same rule as the editor configs). That is also
# where it downloads Bambu's proprietary network plugin on first cloud use —
# deliberately NOT packaged, and nothing in Nix should try to own it.
{ config, lib, pkgs, ... }:

{
  # Model files get handed to the slicer. This list mirrors the MimeType= line
  # of OrcaSlicer's
  # own desktop entry rather than being invented: the id is
  # com.orcaslicer.OrcaSlicer.desktop, NOT `OrcaSlicer.desktop` (a wrong id
  # here fails silently — the entry just points at nothing). It survived the
  # move to flatpak unchanged: flatpak exports the app's real desktop file to
  # /var/lib/flatpak/exports/share/applications, which services.flatpak puts on
  # XDG_DATA_DIRS, so the same id resolves. Merges with the directory/archive/
  # media defaults; xdg.mimeApps.enable lives in home/default.nix.
  #
  # What's here is MESHES only, and the missing type is deliberate: `model/step`
  # moved to home/freecad.nix when FreeCAD arrived. STEP carries real solid
  # geometry, so it belongs to the modeller that can edit it — the slicer would
  # only tessellate it. Don't add it back without deleting it there; two
  # defaultApplications entries for one type is a home-manager option conflict
  # and fails the eval.
  xdg.mimeApps.defaultApplications = {
    "model/3mf" = "com.orcaslicer.OrcaSlicer.desktop"; # the Bambu/Orca native project format
    "application/vnd.ms-3mfdocument" = "com.orcaslicer.OrcaSlicer.desktop"; # the same thing under its older mime name
    "model/stl" = "com.orcaslicer.OrcaSlicer.desktop";
    "application/prs.wavefront-obj" = "com.orcaslicer.OrcaSlicer.desktop";
    "application/x-amf" = "com.orcaslicer.OrcaSlicer.desktop";
    # Not a file type: the URL scheme behind the "Open in OrcaSlicer" button
    # on MakerWorld/Printables. Registering it is what makes those one-click
    # imports from the browser work at all.
    "x-scheme-handler/orcaslicer" = "com.orcaslicer.OrcaSlicer.desktop";
  };
}
