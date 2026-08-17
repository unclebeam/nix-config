# home/vscode.nix — Visual Studio Code, the FHS-wrapped Microsoft build.
# One file per intent: everything that exists because of VS Code lives here.
# Removing VS Code = delete this file + its import line in default.nix
# (and drop `uv` from modules/core.nix if nothing else wants Python).
#
# It exists for ONE job: running .ipynb notebooks (the Anthropic certification
# course ships its material that way). Neovim and Doom Emacs stay the general
# editors — this is the notebook front-end.
#
# Why `vscode-fhs` and not plain `vscode`:
#   Marketplace extensions are the whole point here (ms-python.python bundles
#   Pylance, ms-toolsai.jupyter bundles the kernel plumbing), and they ship
#   PREBUILT binaries whose ELF interpreter is hardcoded to
#   /lib64/ld-linux-x86-64.so.2 — a path NixOS deliberately doesn't have.
#   `vscode-fhs` runs the editor inside a buildFHSEnv sandbox that provides
#   exactly that layout (glibc, zlib, openssl, gcc.cc.lib, nss/dbus/gtk…), so
#   extensions install and run unmodified. The same sandbox covers the
#   integrated terminal and every Jupyter kernel launched from it, which is
#   what makes `!pip install <anything>` inside a notebook cell behave the way
#   the course author's Ubuntu machine does.
#   (Outside VS Code the same wheels still run — that's modules/nix-ld.nix,
#   a different mechanism for the same problem.)
#
# Why unstable: the Python and Jupyter extensions gate on a minimum VS Code
# engine version and silently stop updating on an older host. The 26.05 pin
# carries 1.119; unstable carries 1.130 — about eleven monthly releases. Same
# fast-moving-app pattern (and same one-line mechanism) as home/brave.nix.
#
# Deliberately NOT managed here:
#   - Extensions and settings.json stay MUTABLE — installed from VS Code's own
#     marketplace into ~/.vscode/extensions, configured in
#     ~/.config/Code/User/settings.json. home-manager's `programs.vscode` would
#     store-symlink settings.json read-only and break the Install button; that
#     is the same trap CLAUDE.md's "editor configs stay plain files" and
#     "No Mason, ever" rules exist to avoid.
#   - Native Wayland. nixpkgs' vscode wrapper adds --ozone-platform-hint=auto
#     (plus WaylandWindowDecorations) whenever NIXOS_OZONE_WL is set, and
#     modules/desktop.nix sets it globally. The -fhs variant runs that same
#     wrapped binary, so the flags survive the sandbox. Nothing to add.
#   - Python itself. There is no interpreter in this flake on purpose: `uv`
#     (modules/core.nix) builds a per-course .venv that notebooks can install
#     into at runtime, with no rebuild. See the comment there.
#
# Per-course setup, because one flag in it is load-bearing:
#
#     cd ~/code/<course-repo>          # NOT under ~/nix-config: flakes copy
#                                      # the whole tracked tree into the store
#     uv venv --seed --python 3.12     # --seed is the load-bearing part
#     uv pip install ipykernel anthropic python-dotenv
#     echo '.venv/' >> .gitignore
#     code .                           # the FOLDER, not the file — see below
#
# `uv venv` WITHOUT --seed creates a venv containing no pip at all (uv does
# its own installing and doesn't need it). That's fine until a course cell
# runs `!pip install …` — which is exactly what this whole file exists to
# support — and dies with "pip: command not found". --seed puts pip,
# setuptools and wheel in the venv so the notebooks work as written.
#
# Then: install ms-python.python + ms-toolsai.jupyter from the marketplace,
# open the notebook, Select Kernel -> Python Environments -> .venv. The
# Python extension only auto-discovers ./.venv relative to the WORKSPACE
# ROOT, which is why you open the folder rather than double-clicking a file.
# The API key belongs in a gitignored .env in the course repo (VS Code's
# python.envFile defaults to ${workspaceFolder}/.env and injects it into
# kernels) — never in home.sessionVariables, which renders verbatim into a
# world-readable /nix/store file.
{ config, lib, pkgs, pkgs-unstable, ... }:

{
  home.packages = [ pkgs-unstable.vscode-fhs ];

  # Double-clicking a notebook in Nautilus should land in VS Code. xdg.mimeApps
  # is enabled in home/default.nix — don't re-set enable here (same note as
  # vlc.nix / orca-slicer.nix). Two files claiming one mime type is a
  # home-manager option conflict and fails the eval, so this type lives here
  # and nowhere else. `code.desktop` is the id nixpkgs generates
  # (executableName = "code"), and application/x-ipynb+json is a real
  # shared-mime-info type, not one we invented — deliberately NOT
  # application/json, which it subclasses: claiming that would hijack every
  # .json file on the machine.
  xdg.mimeApps.defaultApplications."application/x-ipynb+json" = "code.desktop";
  # Needed ON TOP of the default, unlike every other app in this repo:
  # code.desktop ships no MimeType= line of its own (only the separate
  # code-url-handler.desktop declares anything), so without an explicit
  # [Added Associations] entry Nautilus's "Open With" list never offers VS
  # Code for a notebook — the double-click default would work while the
  # right-click menu looked broken.
  xdg.mimeApps.associations.added."application/x-ipynb+json" = "code.desktop";
}
