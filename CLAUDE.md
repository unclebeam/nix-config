# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A NixOS flake for two x86_64-linux machines: `unclebeam-pc` (AMD Ryzen 9 desktop + AMD GPU, gaming) and `unclebeam-thinkpad` (ThinkPad X1 Carbon Aura, Intel). Both run NixOS 26.05 with the **niri** compositor (KDL config) and the **DMS** (DankMaterialShell) desktop shell. The repo is edited on the Linux machines; the Mac is only a remote install trigger and can only `nix eval` — never build or switch.

## Commands

```sh
# Validate after edits (works cross-platform, evaluation only — the main "did I break it" check):
nix eval .#nixosConfigurations.unclebeam-pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.unclebeam-thinkpad.config.system.build.toplevel.drvPath

# Check the compositor config after editing the KDL (on a machine):
niri validate

# Apply on a machine (hostname == flake attr):
sudo nixos-rebuild switch --flake .

# Smoke-test in a VM (Linux only):
nixos-rebuild build-vm --flake .#unclebeam-pc && ./result/bin/run-unclebeam-pc-vm

# Update pins (stays within nixos-26.05):
nix flake update
```

**⚠ Flakes only see git-tracked files** — `git add` any new file before evaluating, or you get misleading "path does not exist" errors.

## Hard-won rules

- **Two-stage completion gate.** First: `nix eval` passes for BOTH hosts, then `git add .`, then **stop** — do not commit or push. The human rebuilds and confirms on their machine; only then commit, push, and print the sha. When adding a flake input, verify all three places: input in `flake.nix`, wiring in `mkHost`, import in the host.
- **Never invent hardware facts** (disk `/dev/disk/by-id/` paths, UUIDs, monitor/EDID strings, `hardware-configuration.nix` contents). Ask, or leave a loud placeholder — a plausible guess can format the wrong disk. niri matches output names against the FULL string from `niri msg outputs`, no prefix matching, and a mismatch fails silently.
- **Installs/reinstalls pin an exact sha** — `github:unclebeam/nix-config/<sha>#<host>` — to bypass flake tarball caching. Branch refs are only for on-machine `--flake .` rebuilds.
- **Check how a PAM service is generated before adding per-service toggles.** greetd's service has default rules, so toggles on `security.pam.services.greetd` work; the DMS lock screen authenticates against `login`.
- **If a compositor/session package changes, list its `share/wayland-sessions/`** before trusting the greeter menu — a broken second session file can kill logins. (niri currently ships exactly one.)

## Architecture

`flake.nix` defines `mkHost`; each host = host dir + disko + DMS modules + home-manager as a NixOS module (`useGlobalPkgs`, so one `nixos-rebuild switch` builds system + user config, and `allowUnfree` applies to user packages). `nixpkgs-unstable` feeds only fast-moving leaf apps (claude-code, lazygit, starship, brave, chrome, vscode, slack) — never the compositor.

- **`hosts/<name>/`** — deliberately thin: hostname, hardware quirks, `stateVersion`, and imports of shared modules (importing *is* enabling — e.g. gaming.nix is one uncommented line). Plus `hardware-configuration.nix` (machine-generated; no `fileSystems` — disko owns those) and `disko.nix` (GPT → ESP → btrfs `@`/`@home`, zstd; used by nixos-anywhere to **wipe and format**, and at runtime for mounts; disks pinned by `/dev/disk/by-id/`, never `/dev/nvme0n1`).
- **`modules/`** — shared system modules: `core.nix` (nix settings, boot loader, network, user, base packages), `nix-config.nix` (first-boot clone of `~/nix-config`), `desktop.nix`, `niri.nix`, `dms.nix`, `dms-greeter.nix`, `gnome-keyring.nix`, `nautilus.nix`, `audio.nix`, `gaming.nix`, `ddc.nix` (DDC/CI brightness, both hosts), `laptop.nix`, etc.
- **`home/`** — shared home-manager config, identical on both machines; entrypoint `home/default.nix`.

Config-less system packages go in core.nix; apps with per-user config go in home/.

## Desktop stack

- **niri split**: `modules/niri.nix` = system half (session, portal routing, xwayland-satellite); `home/niri.nix` + `home/niri/config.kdl` = the compositor config, **out-of-store symlinked** into the `~/nix-config` checkout. niri watches the config and live-reloads on save — no rebuild, no reload command; `niri validate` checks syntax first.
- **Includes are positional and merge last-wins**; relative include paths resolve against `~/.config/niri/` (not the symlink target). A missing non-`optional=true` include fails the WHOLE config. **Every `dms/` fragment include must stay `optional=true`** — on a fresh install the fragments don't exist yet, and a failed config drops to built-in defaults with no session spawn → dms.service never starts → deadlock.
- **Display config is not in this repo.** DMS Settings → Displays writes the untracked `~/.config/niri/dms/outputs.kdl` (last include, so it wins). Never re-add tracked `output` blocks, generate them from Nix, or add a hostname branch. Cost accepted: a fresh install runs niri auto-config until one GUI Displays pass.
- **DMS is the one shell**: bar, launcher, notifications, lock screen, idle, OSD, clipboard, polkit agent, power menu, wallpaper, screenshots — plus the greetd greeter (`dms-greeter.nix`). The flake input is mandatory (nixpkgs' package is too old; its `follows nixpkgs` is intentional — quickshell comes from cache, only the Go daemon rebuilds). Use the **NixOS module only** — never the flake's homeModules, **especially not `homeModules.niri`** (it takes over our config.kdl symlink). Never spawn `dms run` from config.kdl.
- **Keybinds are ours** in `home/niri/config.kdl` via `dms ipc call`; DMS's `binds.kdl` is unused and `dms setup` is never run. ipc signatures are not stable and arity is enforced (a short call silently does nothing) — after a DMS bump, re-run argument-taking verbs bare to see the current signature. An unexplained `include` line in `git diff config.kdl` means DMS wrote through the symlink; the `dms/` includes keep their bare relative spelling so DMS's grep matches them.
- **DMS settings are GUI-owned**: `~/.config/DankMaterialShell/settings.json`, machine-local, untracked. Fresh installs need a first-login GUI pass: wallpaper, idle/lock timeouts (default 0 = never locks), GTK/Qt theme toggles, Displays, per-screen brightness-device pins (multi-monitor), `fprintd-enroll` (thinkpad). Doom Emacs also needs a manual `doom install` + `systemctl --user restart emacs.service`.
- **Files/secrets/capture are GNOME**: Nautilus + gvfs (`useNautilus = true` makes it the file dialog everywhere), gnome-keyring (PAM-unlocked on `greetd` — the greeter must stay password-only; Seahorse is the GUI), and the gnome portal for ScreenCast/Screenshot (niri's only capture path). **Never route the capture family to `kde`** — its capture code only works under KWin. Print-key screenshots go through the `screenshot-annotate` wrapper (`home/satty.nix`), not the portal.
- **Theming**: DMS owns color via matugen — it renders `dms/colors.kdl`, alacritty's `dank-theme.toml`, GTK css, and a KColorScheme (qt6ct-kde parses it; keep `kdePackages.qt6ct` and breeze even with no KDE apps) on every wallpaper change. All template outputs are imperative, machine-local, untracked — configs reference them via includes/imports, never store symlinks. No repo palette; don't hardcode theme colors in app configs.

## Invariants

- `nixosConfigurations` attribute names == each machine's `networking.hostName` (makes bare `--flake .` work).
- `stateVersion` (system and home) is set once at install; never bump it.
- The checkout lives at `~/nix-config` on every machine — every out-of-store symlink hardcodes that path (failure mode is silent dangling), and `modules/nix-config.nix` self-heals fresh installs by cloning it.
- Keep the session pair intact: `home/niri.nix` declares `niri-session.target` (no Install section — reached only explicitly) and config.kdl's `spawn-at-startup "systemctl" "--user" "start" "niri-session.target"` starts it after niri imports WAYLAND_DISPLAY. Don't convert the spawn into a `Wants=` on niri.service (races the env import).
- Boot loader settings live in `core.nix`, not hardware-configuration.nix.
- home-manager's release branch must match the nixpkgs release when bumping either.

## Deliberate decisions (do not "fix")

- **Editor configs stay plain files** symlinked via home-manager — never nixvim or other Nix-generated equivalents.
- **No Mason** — LSPs and formatters are Nix packages in `home/`.
- **DMS is the one shell** — no second bar/launcher/locker/notification daemon/polkit agent, no extra compositors, unless explicitly asked.
- **DMS settings are GUI-owned on purpose** — never manage `settings.json` from Nix; the first-login GUI pass is the accepted cost.
- **`home/niri/config.kdl` tracks stock niri defaults** — every departure is marked `// DEVIATION` (DMS binds, session spawn, prefer-no-csd, natural-scroll, includes, the steam/mpv VRR window-rule). No convenience binds, no hyprland-era binds, no static workspace emulation.
- **HDR is parked** — niri has no color management yet; don't re-add HDR plumbing until it ships.

## Style

Keep comments short and only where necessary: one line for a non-obvious constraint or the reason a setting exists. No narrative, no history — git history and commit messages carry that. When editing an existing heavily-commented file, trimming its comments to match is fine.
