# home/freecad.nix — FreeCAD, the parametric CAD modeller: the AUTHORING half
# of the 3D-printing pipeline whose other half is already here. Design a part
# with real constraints and a rebuildable feature tree, export STL/3MF, then
# hand it to OrcaSlicer (home/orca-slicer.nix) to become G-code for the X1
# Carbon. One file per intent: everything that exists because of FreeCAD lives
# here. Removing it = delete this file + the import line in home/default.nix,
# and give the STEP lines below back to home/orca-slicer.nix.
#
# THE APP IS A NORMAL NIX PACKAGE — do not "unify" it with its pipeline sibling
# by moving it to flatpak. OrcaSlicer is a flatpak for one specific reason (the
# nixpkgs build dies on Bambu's network plugin: two libstdc++ copies in one
# process; the full diagnosis is in modules/orca-slicer.nix), and that flake
# input exists for that ONE app. FreeCAD has no such defect: it builds, runs,
# and lives entirely in the store like everything else here.
#
# `pkgs.freecad`, NOT `freecad-wayland`. That attribute still resolves, which
# makes it a plausible-looking wrong answer — it is an alias for plain freecad
# (nixpkgs pkgs/top-level/aliases.nix, "Added 2025-06-14"), kept only so old
# configs don't break. Upstream folded Wayland support into the one build:
# qt6.qtwayland is in freecad's own buildInputs, so this runs Wayland-native
# under niri with no XWayland detour and no separate package (which matters
# more now: X11 clients go through xwayland-satellite).
#
# No Qt block and no theme colors here: FreeCAD is Qt6, so the shared
# home/qt.nix already reaches it — QT_QPA_PLATFORMTHEME=qt6ct points it at
# Noctalia's wallpaper-derived KColorScheme and at breeze-icons. That is the
# whole difference from OrcaSlicer, which renders in a flatpak sandbox with the
# runtime's own GTK theme because a sandbox can't see our templates. Per the
# repo's theming rule an app either reaches the templates or stays at its
# defaults; this one reaches them, so there is nothing to configure.
#
# Nix does not own the app's state, same rule as the editor configs:
# ~/.config/FreeCAD/{user,system}.cfg is written by FreeCAD itself (nixpkgs'
# wrapper only seeds those files if you pass userCfg/systemCfg, which we don't),
# and workbenches installed through the built-in Addon Manager land in
# ~/.local/share/FreeCAD/Mod. Keep it that way — an addon is a click, not a
# rebuild. If a workbench ever needs to be declarative on BOTH machines,
# nixpkgs exposes `freecad.customize { modules = [ ... ]; pythons = [ ... ]; }`
# (pkgs/by-name/fr/freecad/freecad-utils.nix) rather than an overlay; reach for
# that only when a second machine actually needs the same addon.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ freecad ];

  # File associations. The desktop id below is copied from the built package
  # (org.freecad.FreeCAD.desktop, ls $out/share/applications) rather than
  # guessed — a wrong id fails SILENTLY here, the entry just points at nothing.
  #
  # Only three types are claimed, and each one is a deliberate tie-break rather
  # than a full mirror of FreeCAD's MimeType= line. That line is long (it also
  # claims IGES, DWG, DXF, COLLADA, VRML, SHP, model/obj, model/stl), but
  # registering a *default* only matters where two apps compete: for the CAD-only
  # formats FreeCAD is the sole claimant on this system, so it already wins by
  # default and an entry here would be noise. Merges with the other apps'
  # defaults; xdg.mimeApps.enable lives in home/default.nix.
  xdg.mimeApps.defaultApplications = {
    # The native project format — feature tree, sketches, parameters intact.
    "application/x-extension-fcstd" = "org.freecad.FreeCAD.desktop";
    # STEP is the one real overlap with the slicer, and it goes to FreeCAD on
    # purpose: it carries actual solid geometry (BREP), so opening it here means
    # editing a real model, while OrcaSlicer would only tessellate it to a mesh
    # for slicing. The mesh formats — STL, 3MF, OBJ, AMF — stay with OrcaSlicer
    # in home/orca-slicer.nix; that file's comment carries the other half of
    # this split. Both names matter: .step/.stp and the zipped .stpz/.stpx.
    "model/step" = "org.freecad.FreeCAD.desktop";
    "model/step+zip" = "org.freecad.FreeCAD.desktop";
  };
}
