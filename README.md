# nix-config

NixOS flake for my two machines. One repo, one shell, reinstall = one command.

| Host | Hardware | Role |
|---|---|---|
| `unclebeam-pc` | AMD Ryzen 9 + AMD RDNA GPU (mesa/RADV) | Desktop, gaming |
| `unclebeam-thinkpad` | ThinkPad X1 Carbon Aura (Intel Core Ultra) | Laptop |

Both run NixOS 26.05 + Hyprland (0.55+, Lua config) +
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS):
one quickshell process is the bar, launcher, notifications, lock screen,
greeter, OSD, clipboard history, polkit agent, and power menu. Theming is
dynamic — DMS/matugen derives Material You colors from the wallpaper and
applies them to the shell, Hyprland, GTK/Qt apps, and the terminal.

## Layout

```
flake.nix       inputs (nixpkgs 26.05, home-manager) + one nixosConfiguration per host
hosts/<name>/   thin per-host config + hardware-configuration.nix (machine-generated)
modules/        shared NixOS modules: core, desktop, hyprland, dms, dms-greeter, audio, gaming, laptop
home/           shared home-manager config: hyprland, dms, alacritty, fish, ...
```

## Installing a machine
### Normal installation

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

### NixOS Anywhere installation
1. Boot the NixOS installer, connect to the internet.
2. Add password to sudo by `sudo passwd`
3. Run `ip a` to see the current ip
4. Run nixos anywhere command
   ``` sh
   nix run github:nix-community/nixos-anywhere -- --flake github:unclebeam/nix-config#unclebeam-pc root@10.2.98.30
   ```
5. After nixos-anywhere was successfully run, the target machine will be auto restarted
6. At the login screen, let's login to tty by using `ctrl+atl+F3` and login with your username and password
7. Change the password by using `passwd`
8. Reboot
9. Getting Emacs to work
 9.1 run `doom install` and then `doom sync`
 9.2 Restart emacs daemon by `systemctl --user restart emacs`

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
