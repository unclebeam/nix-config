# home/freecad.nix — FreeCAD, the authoring half of the 3D-printing pipeline
# (design → export STEP/STL → OrcaSlicer). A normal Nix package — do not
# "unify" it with the slicer's flatpak; OrcaSlicer is a flatpak for a defect
# FreeCAD doesn't have (modules/orca-slicer.nix).
#
# `pkgs.freecad`, NOT `freecad-wayland`: that attr still resolves but is a
# legacy alias for plain freecad — Wayland support is folded into the one
# build (qt6.qtwayland in its buildInputs), so this runs Wayland-native.
#
# No Qt/theme block: home/qt.nix already reaches it via qt6ct. App state
# (~/.config/FreeCAD, Addon Manager workbenches) is app-owned, not Nix — an
# addon is a click, not a rebuild. If a workbench ever must be declarative on
# both machines, use `freecad.customize { modules = …; }`, not an overlay.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ freecad ];

  # Desktop id copied from the built package (a wrong id fails SILENTLY —
  # the entry just points at nothing). Only deliberate tie-breaks are
  # claimed, not FreeCAD's full MimeType= line: a default only matters where
  # two apps compete; for CAD-only formats FreeCAD is the sole claimant.
  # xdg.mimeApps.enable lives in home/default.nix.
  xdg.mimeApps.defaultApplications = {
    # Native project format.
    "application/x-extension-fcstd" = "org.freecad.FreeCAD.desktop";
    # STEP is the one real overlap with the slicer and goes to FreeCAD on
    # purpose: it carries solid geometry (BREP) — editing a real model beats
    # tessellating to a mesh. The mesh formats (STL/3MF/OBJ/AMF) stay with
    # OrcaSlicer in home/orca-slicer.nix.
    "model/step" = "org.freecad.FreeCAD.desktop";
    "model/step+zip" = "org.freecad.FreeCAD.desktop";
  };
}
