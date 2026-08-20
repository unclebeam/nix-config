# home/vscode.nix — VS Code (FHS build), for one job: running .ipynb
# notebooks. Neovim and Doom stay the general editors.
#
# vscode-fhs, not vscode: marketplace extensions ship prebuilt binaries with
# the ELF interpreter hardcoded to /lib64/ld-linux-x86-64.so.2; the FHS
# sandbox provides that layout so extensions, the integrated terminal, and
# `!pip install` in notebook cells all work unmodified. Unstable because the
# Python/Jupyter extensions gate on a minimum engine version and silently
# stop updating on an older host.
#
# Deliberately NOT managed: extensions and settings.json stay mutable
# (programs.vscode would store-symlink settings.json read-only and break the
# Install button); native Wayland comes free via NIXOS_OZONE_WL; Python
# comes per-course from uv (modules/core.nix).
#
# Per-course setup (one flag is load-bearing):
#     cd ~/code/<course-repo>          # NOT under ~/nix-config
#     uv venv --seed --python 3.12     # --seed puts pip in the venv —
#                                      # without it `!pip install` dies
#     uv pip install ipykernel anthropic python-dotenv
#     echo '.venv/' >> .gitignore
#     code .                           # the FOLDER: the Python extension only
#                                      # auto-discovers ./.venv at workspace root
# API keys go in a gitignored .env (python.envFile injects it) — never in
# home.sessionVariables, which renders into a world-readable store file.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [ pkgs-unstable.vscode-fhs ];

  # xdg.mimeApps.enable lives in home/default.nix. application/x-ipynb+json
  # is a real shared-mime-info type — deliberately NOT application/json,
  # which it subclasses: claiming that would hijack every .json file.
  xdg.mimeApps.defaultApplications."application/x-ipynb+json" = "code.desktop";
  # Needed on top of the default: code.desktop ships no MimeType= line, so
  # without an [Added Associations] entry Nautilus's "Open With" never
  # offers VS Code even though the double-click default works.
  xdg.mimeApps.associations.added."application/x-ipynb+json" = "code.desktop";
}
