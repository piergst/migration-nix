# Checklist post-install — déployer ~/repositories/piergst/nixos-config sur une nouvelle machine

Choses qui ne survivent PAS automatiquement à une réinstallation NixOS ou à un
nouveau matériel, même si `~/repositories/piergst/nixos-config` est cloné/restauré à l'identique.
Deux cas : réinstall de la même machine physique (nixbook) vs vraiment un
autre appareil — les étapes marquées **[nouveau matos]** ne concernent que le
second cas.

## 0. Avant le premier rebuild

- [ ] **[nouveau matos]** Régénérer `hardware-configuration.nix` avec
      `nixos-generate-config` — celui du repo est calé sur le MacBookPro12,1,
      pas transférable tel quel.
- [ ] **[nouveau matos]** Relire `disko.nix` (chemins de disque, layout LUKS)
      avant de lancer quoi que ce soit dessus — disko **efface** le disque
      selon ce fichier.
- [ ] **[nouveau matos]** Si le hostname change, ajouter une nouvelle entrée
      `nixosConfigurations.<hostname>` dans `flake.nix` (aujourd'hui il n'y a
      que `nixbook`).
- [ ] **[nouveau matos]** Vérifier le nom de l'interface réseau (`ip -brief
      addr`) — `wlp3s0` est hardcodé dans `services.avahi.allowInterfaces`
      (`configuration.nix`) et doit être mis à jour si différent.

## 1. Premier rebuild

```
sudo nixos-rebuild switch --flake ~/repositories/piergst/nixos-config#nixbook
```

(home-manager est intégré au flake comme module NixOS — pas de `home-manager
switch` séparé à lancer.)

- [ ] Définir un mot de passe pour `pierre` (`passwd`) — `configuration.nix`
      ne déclare ni `initialPassword` ni `hashedPassword`, le compte est créé
      sans mot de passe utilisable tant que ça n'est pas fait à la main.

## 2. Après le premier rebuild — Vaultwarden / Caddy

- [ ] Le certificat `certs/caddy-root-ca.crt` versionné dans le repo
      correspond à la CA générée par Caddy sur l'**ancienne** machine — sa clé
      privée n'existe que dans `/var/lib/caddy` de cette ancienne machine,
      jamais dans le repo. Sur la nouvelle machine, Caddy génère une CA
      différente au premier démarrage : le fichier committé devient obsolète.
      Refaire l'export une fois :
      ```
      sudo cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt \
        ~/repositories/piergst/nixos-config/certs/caddy-root-ca.crt
      sudo chown pierre:users ~/repositories/piergst/nixos-config/certs/caddy-root-ca.crt
      cd ~/repositories/piergst/nixos-config && git add certs/caddy-root-ca.crt && git commit -m "update caddy CA for <hostname>"
      ```
      puis un second `nixos-rebuild switch` pour que Firefox
      (`programs.firefox.policies`) et le système
      (`security.pki.certificateFiles`) fassent confiance à la nouvelle CA.
      (Choix assumé le 2026-08-31 : pas de CA statique via agenix/sops-nix ni
      de vrai domaine ACME pour l'instant — à reconsidérer si ça devient
      pénible.)
- [ ] Restaurer les données du coffre Vaultwarden si tu migres depuis une
      autre machine : le dossier `~/.local/share/vaultwarden` (base SQLite,
      clé RSA, pièces jointes) n'est **pas** versionné, une nouvelle machine
      démarre avec un coffre vide. Copier ce dossier depuis l'ancienne
      machine (ou une sauvegarde) **avant** de démarrer le service, ou
      réimporter les données via Tools > Import data dans le vault web une
      fois le compte recréé.

## 3. Zsh / prompt

- [ ] Symlink powerlevel10k pour que oh-my-zsh le trouve (pas encore géré
      nativement par home-manager, toujours un module `programs.zsh` système
      + `ohMyZsh` classique) :
      ```
      mkdir -p ~/.oh-my-zsh/custom/themes
      ln -s /etc/profiles/per-user/pierre/share/zsh/themes/powerlevel10k \
        ~/.oh-my-zsh/custom/themes/powerlevel10k
      ```

## 4. Hyprland

- [ ] **[nouveau matos]** `~/.config/hypr/hyprland.lua` référence des noms de
      moniteurs (`CHANGE_ME_LEFT`/`CHANGE_ME_RIGHT` si jamais remplis, ou les
      valeurs actuelles du MacBook) — à vérifier/adapter avec `hyprctl
      monitors` sur le nouveau matériel.

## Notes / pièges déjà rencontrés

- **mDNS ne supporte pas les sous-domaines.** On a essayé de passer Vaultwarden
  sur `vw.nixbook.local` (pour laisser `nixbook.local` libre pour d'autres
  services futurs) : `/etc/avahi/hosts` échoue avec `Local name collision`
  (Avahi refuse une 2e adresse statique sur l'IP déjà publiée pour le hostname
  principal), et `avahi-publish` (l'alternative) demande une permission D-Bus
  qu'on n'a pas prise le temps de configurer côté root. Abandonné le
  2026-08-31, retour à `nixbook.local` tout court. Si un jour il faut
  plusieurs services HTTPS sur cette machine : soit des ports différents,
  soit creuser la permission D-Bus d'Avahi, soit reconsidérer toute la
  question de la CA/portabilité en même temps (voir la note "CA statique via
  agenix/sops-nix" ci-dessus).

## 5. Applications — configuration non déclarative

- [ ] **Bitwarden desktop** : au premier lancement, *Paramètres →
      environnement auto-hébergé* → `https://nixbook.local`, **avant** de se
      connecter (sinon il part sur bitwarden.com). Confirmé fonctionner le
      2026-09-12 sur nixbook : malgré Electron (qui ne lit ni le magasin
      Firefox ni forcément `security.pki.certificateFiles`), la CA interne de
      Caddy passe sans manipulation supplémentaire. À revérifier sur une
      nouvelle machine, où la CA de Caddy est régénérée (voir section 2).
- [ ] **Agent SSH de Bitwarden** : activer *Paramètres → Agent SSH* dans le
      client desktop (toggle UI, non automatisable). `SSH_AUTH_SOCK` est déjà
      posé déclarativement (`environment.sessionVariables` dans
      `configuration.nix`), mais le socket n'existe que si le client tourne et
      est déverrouillé. Les clés doivent être des éléments de type *Clé SSH*
      dans le coffre.
- [ ] **Zed** : config encore en dotfiles. Le paquet est déclaré
      (`zed-editor` dans `home.nix`, binaire `zeditor`), mais
      `~/.config/zed/settings.json` et `keymap.json` sont copiés à la main
      depuis `migration/zed/`. Zed écrit un `settings.json` par défaut au
      premier lancement : copier **après** ce premier lancement, ou accepter
      de l'écraser. À passer en `home.file` / `programs.zed-editor` une fois
      la config stabilisée.
- [ ] **Zed + agent Claude (ACP)** : l'adaptateur `claude-acp` télécharge son
      propre binaire `claude` précompilé (`node_modules/@anthropic-ai/
      claude-agent-sdk-linux-x64/claude`), dynamiquement lié pour un Linux
      générique → `Could not start dynamically linked executable` / exit 127,
      NixOS n'ayant qu'un `stub-ld` en `/lib64`. Corrigé en pointant
      l'adaptateur sur le `claude` du profil Nix, via `agent_servers.claude-acp.
      env.CLAUDE_CODE_EXECUTABLE = "/etc/profiles/per-user/pierre/bin/claude"`
      dans `~/.config/zed/settings.json` (l'adaptateur lit cette variable et ne
      retombe sur son binaire que si elle est absente). Alternative plus large
      si d'autres binaires génériques posent problème :
      `programs.nix-ld.enable = true` dans `configuration.nix`.
- [ ] **Lanceur `.desktop` "Firefox distant (VNC)"** : posé à la main dans
      `~/.local/share/applications/firefox-remote-vnc.desktop`, pas dans le
      flake — à recréer sur une nouvelle machine (contenu complet dans
      NOTES.md, section "Lanceur .desktop"), ou à passer en
      `xdg.desktopEntries` dans `home.nix`.
- [ ] **Difftastic en diff par défaut de git** : config manuelle pour
      l'instant (`git config --global diff.external difft` ; binaire `difft`,
      pas `difftastic`). À passer en déclaratif plus tard via le module
      home-manager `programs.difftastic` : `enable = true` + `git.enable =
      true` (mode `external` par défaut, ou `difftool`/`both`). Rappel :
      `git show` / `git log -p` exigent alors `--ext-diff` ; retour au diff
      normal via `git config --global --unset diff.external`. Delta a un
      module équivalent (`programs.delta`) pour le même jour.

## Pas d'action requise (déjà déclaratif, confirmé fonctionner après rebuild)

- Service Vaultwarden (le conteneur podman rootless crée son propre dossier
  de données au démarrage, `ExecStartPre` dans `home.nix`)
- Packages home-manager (gcc, fzf, bat, jq, zsh-powerlevel10k,
  bitwarden-desktop, tigervnc, herdr, etc.)
- Firewall (443/tcp, 5353/udp) et Avahi (une fois l'interface vérifiée ci-dessus)
