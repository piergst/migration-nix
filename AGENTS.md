Projet de migration en cours d'un système arch - cachyos vers nixos

NEW_MACHINE.md permet de référencer les actions faites sur ce nouveau système
nixos en post install. Ces actions seront dans la mesures du possible à
automatiser ou décrire dans la config nix

NOTES.md contient un résumé du process global de migration. Y référencer les
différentes étapes / problème / choix fait / rencontré pendant la migration

Pour l'instant la config des différentes application est en dotfiles classique,
une fois la config stabilisée l'idée et de tout passer en déclaratif dans la
config nix / home-manager

Les fichiers de config nix se situent dans ~/repositories/piergst/nixos-config/

Les dotfiles de ce dossier sont les fichiers INITIAUX de la migration, le point
de départ dont on est parti. Ce n'est pas un miroir de la config actuelle et il
ne faut PAS y répercuter les changements faits sur la config live : ils gardent
leur valeur d'état initial.

C'est donc la config live qui fait foi (ex: `~/.config/hypr/hyprland.lua`, pas
`hyprland/hyprland.lua`). Toute modification de config se fait dans le live, et
uniquement là. Inutile aussi de corriger les erreurs des fichiers initiaux.

Seuls NOTES.md et NEW_MACHINE.md sont des documents vivants, à tenir à jour.

Quand le dépôt contient un `DOCSITE.md`, l'appliquer : c'est le contrat du site de
documentation externe qui rend ce dépôt.
