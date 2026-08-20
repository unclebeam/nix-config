# modules/flatpak.nix — the flatpak MECHANISM, and nothing else: the service
# itself plus the update policy. No app is named here. Each app that happens to
# be a flatpak contributes its own line from its own module, so this file never
# needs touching when one is added or removed.
#
# ── WHY A NIX-NATIVE CONFIG HAS FLATPAK AT ALL ──────────────────────────────
# Everything else on these machines comes from nixpkgs, pinned by flake.lock.
# Two apps deliberately don't, for two DIFFERENT reasons — which is exactly why
# the mechanism was pulled out of the app module it used to live inside
# (modules/orca-slicer.nix, when OrcaSlicer was the only one):
#
#   OrcaSlicer (modules/orca-slicer.nix) — CANNOT be a Nix package here. The
#     nixpkgs build aborts ~2s into every launch the moment Bambu's proprietary
#     network plugin loads: two copies of libstdc++ in one process, a
#     std::locale built through one and destroyed through the other. That's a
#     build-level ABI defect, not something config can fix. The full backtrace
#     is in that module's header. Not a preference — a hard blocker.
#
#   RustDesk (modules/rustdesk.nix) — CHOOSES not to be. nixpkgs has working
#     `rustdesk` and `rustdesk-flutter` attributes; Flathub is simply ahead
#     (1.4.9 vs 1.4.7/1.4.5 on the 26.05 pin) and is upstream's own build. This
#     one is a judgement call and could be reverted to nixpkgs in one line.
#
# So do NOT "tidy up" flatpak on the grounds that it's the odd one out. Removing
# it reintroduces a slicer that cannot start. But equally: if BOTH app modules
# ever go away, this file and the `nix-flatpak` flake input are deleted together
# — nothing else here uses flatpak.
#
# ── WHY THE nix-flatpak INPUT ───────────────────────────────────────────────
# nixpkgs' own `services.flatpak` has ONLY `enable` — it installs flatpak and
# starts nothing else. There is no way to declare a remote or an app, which
# would make installing each flatpak a manual per-machine step and defeat the
# point of a declarative config. The `nix-flatpak` input (flake.nix) extends
# that SAME `services.flatpak` namespace with `remotes`/`packages`/`update`.
#
# Flathub is already in the module's default remotes, so no remote is declared
# anywhere in this repo.
{ config, lib, pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    # `packages` is deliberately NOT set here. It is an ordinary list option, so
    # definitions from several modules MERGE — which is what lets each app own
    # its own entry next to its own rationale (and its own firewall rules, in
    # OrcaSlicer's case) instead of piling up in one anonymous list. Check the
    # merge result with:
    #   nix eval --json .#nixosConfigurations.unclebeam-pc.config.services.flatpak.packages

    # Updates run on a systemd timer, NOT `update.onActivation`. Activation-time
    # updates would make every `nixos-rebuild switch` reach out to Flathub, so a
    # rebuild on a flaky connection — or on the train — could fail for reasons
    # that have nothing to do with the change being applied. A rebuild must stay
    # independent of the network.
    #
    # NB the INSTALL of a newly declared package still happens at activation, so
    # the one switch that first adds an app does need network. Steady-state
    # rebuilds don't.
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    # uninstallUnmanaged stays at its default (false): flatpaks installed by
    # hand are not this module's business to remove.
  };
}
