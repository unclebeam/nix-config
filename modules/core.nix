# core.nix — everything both machines need regardless of desktop or role:
# nix itself, boot loader, networking, the user account, and baseline CLI tools.
{
  config,
  lib,
  pkgs,
  inputs, # from specialArgs in flake.nix — lets us reach other flakes' packages
  pkgs-unstable, # the unstable package set (flake.nix) — for a few fast movers
  ...
}:

{
  # ── Nix ────────────────────────────────────────────────────────────────
  nix.settings = {
    # Flakes are still technically "experimental" but are the standard now.
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Let wheel users (you) use substituters, run privileged nix commands.
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # Reclaim disk space from old generations automatically.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Needed for Steam and friends. With home-manager.useGlobalPkgs this
  # applies to user packages too.
  nixpkgs.config.allowUnfree = true;

  # ── Boot ───────────────────────────────────────────────────────────────
  # Both machines are modern UEFI boxes. This lives here (not in
  # hardware-configuration.nix) because nixos-generate-config does not emit
  # boot loader settings — keeping it here means replacing the hardware file
  # during install can't accidentally drop the boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # keep /boot from filling up
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep kernel error chatter off the console (a flaky USB hub on the
  # desktop spams err-level timeouts every boot; it used to paint over the
  # login screen back when the greeter was a TUI). This only gates what's
  # echoed to the screen — everything still lands in the journal
  # (`journalctl -b -p err`).
  boot.consoleLogLevel = 3; # 3 = critical and worse; the default of 4 shows err

  # ── Networking ─────────────────────────────────────────────────────────
  # NetworkManager handles wifi + ethernet on both machines.
  # CLI: `nmcli device wifi connect <ssid> --ask`, or `nmtui` for a TUI.
  networking.networkmanager.enable = true;

  # The wifi supplicant is iwd, not the default wpa_supplicant (switched
  # 2026-07-25). Why: MT7925 failure #5 on the pc — at cold boot the radio
  # intermittently times out the WPA 4-way handshake (deauth reason 15,
  # ~4s after firmware load, mid regdom/channel-list churn; see the numbered
  # MT7925 failure comments in hosts/unclebeam-pc/default.nix).
  # wpa_supplicant surfaces that timeout to NetworkManager, which reads it
  # as "wrong password", invalidates the stored PSK for the attempt, and —
  # since no secret agent exists pre-login — fails the activation and later
  # made the shell's agent re-prompt for a password that was on disk and
  # correct all along. iwd retries failed handshakes internally instead of
  # bubbling a bad-password verdict up, so a flaky first handshake becomes
  # a silent retry, not a prompt. NM stays the manager: existing profiles,
  # nmcli, and the shell's network widget all keep working — iwd only replaces
  # wpa_supplicant underneath (this option auto-enables iwd's service; iwd's
  # own network/DHCP config stays off, NM keeps doing IP). iwd caches
  # network state under /var/lib/iwd; NM hands it the profile PSK on first
  # connect, so at most a one-time re-prompt right after the switch.
  networking.networkmanager.wifi.backend = "iwd";

  # ── Locale / time ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── User ───────────────────────────────────────────────────────────────
  # fish must be enabled system-wide to be a legal login shell
  # (it registers itself in /etc/shells and wires up completions).
  programs.fish.enable = true;

  users.users.unclebeam = {
    isNormalUser = true;
    description = "unclebeam";
    extraGroups = [
      "wheel" # sudo
      "networkmanager" # manage connections without a password prompt
      "video" # backlight control on the laptop
    ];
    shell = pkgs.fish;
    # First-login password — CHANGE IT immediately after install with `passwd`.
    # (nixos-install also asks for the root password interactively.)
    initialPassword = "changeme";
  };

  # ── Baseline packages ──────────────────────────────────────────────────
  # System-wide CLI + the browser. Desktop apps with per-user *config*
  # (alacritty, dolphin…) live in home/ instead; these are config-less here.
  environment.systemPackages = with pkgs; [
    fastfetch
    btop
    fzf
    ripgrep
    fd # file finder; promoted from home/neovim.nix when Doom Emacs became a second consumer
    pkgs-unstable.lazygit # fast-moving; tracks unstable (see flake.nix)
    git
    # neovim moved to home/neovim.nix — it grew per-user config (LazyVim),
    # and apps with per-user config live in home/.
    # claude-code moved to home/claude.nix — it grew per-user config
    # (settings + statusline), and apps with per-user config live in home/.
    # brave moved to home/brave.nix — it grew per-user config (xdg
    # default-browser handlers), and apps with per-user config live in home/.
    wget
    curl
    # Global Node = whatever nixpkgs calls "latest" at each `nix flake update`
    # (currently 26.x). Projects that need a SPECIFIC version don't fight this:
    # they get theirs from a dev shell activated by direnv (home/direnv.nix),
    # which shadows this one inside the project dir.
    nodejs_latest
    # Electron (native Wayland via NIXOS_OZONE_WL) and unfree.
    obsidian # markdown notes — vaults live in $HOME, nothing for Nix to configure
    # Also Electron + unfree, same Wayland story as obsidian; fast-moving,
    # so it tracks unstable (updates at each `nix flake update`).
    pkgs-unstable.slack
    # Discord via Vesktop: the stock discord client's screenshare can't capture
    # on Wayland, while Vesktop captures through the xdg-desktop-portal
    # ScreenCast path (routed to xdg-desktop-portal-hyprland here — see
    # modules/hyprland.nix; the restore-token tuning in hypr/xdph.conf keeps
    # re-shares picker-free).
    vesktop
    libreoffice
    # DBeaver Community Edition. nixpkgs only carries the upstream binary
    # release (-bin); there is no from-source `dbeaver` attribute.
    dbeaver-bin
    # Zen Browser — not in nixpkgs, comes from the zen-browser flake input
    # (see flake.nix). `default` is Zen's mainline release channel (their
    # "beta"); the flake also offers the bleeding-edge `twilight`.
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
