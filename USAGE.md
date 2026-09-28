---
description: Suivi de la migration d'Arch/CachyOS vers NixOS — dotfiles de départ, notes et checklist post-install.
---

# migration-nix

Suivi de la migration d'un système Arch/CachyOS vers NixOS. Ce dépôt contient
les **dotfiles du point de départ** et les **notes vivantes** de la migration.
La configuration NixOS effective vit dans `~/repositories/piergst/nixos-config`.

## Documents

- `NOTES.md` — choix, pièges rencontrés et résolutions.
- `NEW_MACHINE.md` — actions à refaire sur une nouvelle machine.
- `STATUS.md` — état d'avancement.

## Reconstruire le système

```
sudo nixos-rebuild switch --flake ~/repositories/piergst/nixos-config#nixbook
```

home-manager est intégré au flake comme module NixOS : pas de `home-manager
switch` séparé.

## Déployer sur une nouvelle machine

1. Cloner ce dépôt et `nixos-config`.
2. Régénérer `hardware-configuration.nix` (`nixos-generate-config`).
3. Relire `disko.nix` avant tout rebuild — il **efface** le disque.
4. Dérouler `NEW_MACHINE.md` (mot de passe, CA Caddy, coffre Vaultwarden,
   powerlevel10k, moniteurs Hyprland).

## Dotfiles

Les dossiers de ce dépôt (`hyprland/`, `zsh/`, `nvim/`, `alacritty/`, …) sont
l'état initial de la migration, pas un miroir de la config actuelle. Le mapping
dossier → destination est dans `NOTES.md`, section « Where each folder goes ».
La config live fait foi ; la consolidation déclarative via home-manager est la
phase 2.
