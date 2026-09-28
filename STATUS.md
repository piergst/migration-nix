---
state: active
next: passer les dotfiles restants en déclaratif via home-manager (phase 2)
---

## Fait

- NixOS fonctionnel sur `nixbook` (MacBookPro12,1), rebuild déclaratif via le
  flake `~/repositories/piergst/nixos-config`.
- Zsh / oh-my-zsh / powerlevel10k, greeter nwg-hello, Vaultwarden + Caddy +
  Avahi (`nixbook.local`), agent SSH Bitwarden.
- Paquets : bitwarden-desktop, tigervnc, herdr, zed, claude-desktop, Paseo
  (build du fork local), difftastic/delta, nodejs, rust.
- Bureaux virtuels `omarchy-wsgroup` packagés en nix.

## Reste

- Phase 2 : figer les dotfiles restants en déclaratif — `hyprland.lua`, les
  fichiers wayle, la config Zed, le lanceur `.desktop` VNC, `diff.external`.
- Trancher le sort de wayle : `runtime.toml` déclaratif sans GUI, ou statu quo.
- Hyprland : corriger les 8 binds `move_into_direction` ; `m1` n'éteint pas le
  2e écran (impasses documentées dans `NOTES.md`).
