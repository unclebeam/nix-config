# nix-config

NixOS flake for my two machines. One repo, one palette, reinstall = one command.

| Host | Hardware | Role |
|---|---|---|
| `unclebeam-pc` | AMD Ryzen 9 + AMD RDNA GPU (mesa/RADV) | Desktop, gaming |
| `unclebeam-thinkpad` | ThinkPad X1 Carbon Aura (Intel Core Ultra) | Laptop |

Both run NixOS 26.05 + Hyprland + Waybar/fuzzel/mako/hyprlock, themed with the
[melange](https://github.com/savq/melange-nvim) dark palette. The palette is
defined once in [`home/colors.nix`](home/colors.nix) and every app references it.

## Layout

```
flake.nix       inputs (nixpkgs 26.05, home-manager) + one nixosConfiguration per host
hosts/<name>/   thin per-host config + hardware-configuration.nix (machine-generated)
modules/        shared NixOS modules: core, desktop, hyprland, audio, gaming, laptop
home/           shared home-manager config: colors, hyprland, waybar, alacritty, fish, ...
```

## Installing a machine

1. Boot the NixOS installer, partition and mount your disks at `/mnt` as usual.
2. Generate the real hardware config and copy it into this repo, replacing the placeholder:

   ```sh
   nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix hosts/<host>/hardware-configuration.nix
   git add hosts/<host>/hardware-configuration.nix   # flakes only see tracked files!
   ```

3. Install:

   ```sh
   nixos-install --flake .#unclebeam-pc        # desktop
   nixos-install --flake .#unclebeam-thinkpad  # laptop
   ```

## Day-to-day

```sh
# hostname matches the flake attr, so no #name needed on the machine itself
sudo nixos-rebuild switch --flake .

# smoke-test a config in a VM without touching the system (Linux only)
nixos-rebuild build-vm --flake .#unclebeam-pc && ./result/bin/run-unclebeam-pc-vm
```

> **⚠ Flakes only see committed/staged files.** After creating any new file,
> `git add` it before building — otherwise you get confusing
> "path does not exist" / "file not found" errors.
