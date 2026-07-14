# home/onlyoffice.nix — OnlyOffice Desktop Editors (docx/xlsx/pptx suite).
# One file per intent: everything that exists because of OnlyOffice lives
# here. Removing it = delete this file + its import line in default.nix.
#
# Installed ALONGSIDE LibreOffice (modules/core.nix) — deliberate, not a
# duplicate to clean up. No xdg.mimeApps defaults registered: office files
# keep whatever handler they already have; OnlyOffice is opened by hand.
# Its settings live in ~/.config/onlyoffice, managed by the app, not Nix.
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ onlyoffice-desktopeditors ];
}
