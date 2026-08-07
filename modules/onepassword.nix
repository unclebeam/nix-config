# 1Password — desktop app, `op` CLI, and the browser extension (Chrome + Brave).
#
# These are NixOS modules, not plain packages in systemPackages, because
# 1Password needs privileged wrappers a normal package can't provide:
#   - the GUI gets a setgid browser-support helper (so browser extensions
#     can talk to the running app) and a polkit policy,
#   - the CLI gets a setgid wrapper so `op` can unlock through the running
#     desktop app instead of asking for the master password in the terminal.
# Installing either via home-manager would silently lose all of that.
#
# 1Password is unfree — covered by allowUnfree in core.nix. Like other
# unfree apps here, its auto-updater can't write to the read-only Nix
# store; new versions arrive via `nix flake update` + rebuild.
{ ... }:

{
  # `op` command-line tool.
  programs._1password.enable = true;

  programs._1password-gui = {
    enable = true;
    # Generates the polkit policy that lets these users unlock 1Password
    # with system authentication (the login password prompt) instead of
    # retyping the master password every time.
    polkitPolicyOwners = [ "unclebeam" ];
  };

  # Auto-install the 1Password extension via managed browser policy
  # (ExtensionInstallForcelist). programs.chromium installs no browser —
  # it only writes policy files under /etc that every Chromium-family
  # browser picks up on startup (Chrome reads /etc/opt/chrome, Brave
  # /etc/brave), so this covers Chrome AND Brave (home/chrome.nix,
  # home/brave.nix). Merges with modules/chromium-policies.nix's search
  # policy; both set `enable = true` on purpose so either file can be
  # removed alone (atomic removal).
  programs.chromium = {
    enable = true;
    # "1Password – Password Manager" (Chrome Web Store ID).
    extensions = [ "aeblfdkhhhdcdjpifhhbdiojplfjncoa" ];
  };
}
