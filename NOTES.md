# Migration notes

Phase 1 (now): deploy these as plain dotfiles, validate everything works.
Phase 2 (later): fold whatever survives into `home.nix` / `configuration.nix` via home-manager.

## Where each folder goes

| Folder | Destination | Notes |
|---|---|---|
| `hyprland/hyprland.lua` | `~/.config/hypr/hyprland.lua` | Charge `monitors.lua`/`workspaces.lua` générés par nwg-displays (voir "Écrans multiples"). Several `hl.dsp.*` calls are unverified against the live Lua API — check with `hyprctl binds` after reload (`hl.dsp.workspace.move_to_monitor` **n'existe pas**, confirmé). |
| `hyprland/hypridle.conf` | `~/.config/hypr/hypridle.conf` | Needs the `hypridle` package (see below). |
| `hyprland/powermenu.sh` | `~/.local/bin/powermenu.sh` (chmod +x) | Wofi-based lock/logout/suspend/reboot/shutdown menu. |
| `hyprland/wallpapers/trees.png` | `~/Pictures/wallpapers/trees.png` | Already copied there live by mistake before the "don't touch live files" rule — matches this. |
| `wofi/config` | `~/.config/wofi/config` | Your current config + `key_up`/`key_down` for vim-style row nav (was in the old rofi config). |
| `zsh/zshenv` | `~/.zshenv` | Deploy this one first — sets `ZSH_CUSTOM`/`ZSH_THEME` early enough, see "oh-my-zsh conflict" below. |
| `zsh/zshrc` | `~/.zshrc` | No longer redeclares `plugins`/re-sources oh-my-zsh, see below. |
| `zsh/aliases.zsh` | `~/.oh-my-zsh/custom/aliases.zsh` | Picked up automatically once `zshenv` is in place. |
| `zsh/keybindings.zsh` | `~/.oh-my-zsh/custom/keybindings.zsh` | Same. |
| `zsh/p10k.zsh` | `~/.p10k.zsh` | Needs a powerlevel10k theme source (see below). |
| `tmux/tmux.conf` | `~/.tmux.conf` | Trivial, just `mouse on`. |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Unchanged from the old config. |
| `nvim/` | `~/.config/nvim/` | Unchanged LazyVim config, WM-independent. |
| `vscodium/*.json` | `~/.config/VSCodium/User/` | Deployed. |
| `exegol/` | `~/.exegol/` | Skipped for now — `exegol` binary not installed on this machine, low priority. |
| `profile/profile` | **skipped** | `~/.profile` isn't reliably read by a UWSM/Hyprland session anyway. Only `BROWSER=firefox` and `MAIL=thunderbird` were worth keeping (`TERM`/`EDITOR` are redundant or handled elsewhere) — carry those two into `home.sessionVariables` in phase 2 instead. |

## oh-my-zsh conflict — RESOLVED via ~/.zshenv, no nix changes needed

`configuration.nix` enables `programs.zsh.ohMyZsh` at the system level, which generates `/etc/zshrc`. That file sets `ZSH` to a **Nix store path**, hardcodes `plugins=(git history-substring-search)`, and calls `source $ZSH/oh-my-zsh.sh` itself — all of that runs **before** `~/.zshrc` is even read.

Fix applied: `zsh/zshenv` (→ `~/.zshenv`) sets `ZSH_CUSTOM` and `ZSH_THEME` early enough (zsh always reads `.zshenv` first, ahead of `/etc/zshrc`), so oh-my-zsh picks them up when `/etc/zshrc` sources it. `zsh/zshrc` no longer redeclares `ZSH`/`plugins`/re-sources `oh-my-zsh.sh` — that would conflict with what NixOS already does.

One thing still needs an actual `configuration.nix` edit, no way around it: the `plugins=(git history-substring-search)` list is baked into `/etc/zshrc` at build time, so `zsh-completions` can only be added by editing `programs.zsh.ohMyZsh.plugins`. `zoxide` doesn't need that — `zsh/zshrc` now calls `zoxide init zsh` directly instead of relying on the omz plugin.

## powerlevel10k theme — RESOLVED

`pkgs.zsh-powerlevel10k` added to `home.nix` + `home-manager switch` done. Home-manager exposes it at `/etc/profiles/per-user/pierre/share/zsh/themes/powerlevel10k` (contains `powerlevel10k.zsh-theme`). oh-my-zsh looks for `ZSH_THEME="powerlevel10k/powerlevel10k"` under `$ZSH_CUSTOM/themes/powerlevel10k/`, so it needed a symlink there:

```sh
mkdir -p ~/.oh-my-zsh/custom/themes
ln -s /etc/profiles/per-user/pierre/share/zsh/themes/powerlevel10k ~/.oh-my-zsh/custom/themes/powerlevel10k
```

Confirmed working. When this moves into home-manager (phase 2), this symlink step becomes unnecessary — home-manager's `programs.zsh.oh-my-zsh` handles theme wiring itself.

## /etc/hosts entries — RESOLVED via networking.extraHosts

Old machine had static entries for internal/lab hosts (pentest lab, homelab services) in `/etc/hosts` directly. On NixOS `/etc/hosts` is generated at build time, so it's set via `networking.extraHosts` in `~/repositories/piergst/nixos-config/configuration.nix` instead (not part of this chezmoi repo — that's a separate flake-based nix config):

```nix
networking.extraHosts = ''
  204.168.131.115 gstcloud.srv
  178.105.24.184  bugbounty.srv
  192.168.1.140   proxmox.local
  192.168.1.97    wazuh.local
  192.168.1.194   elfrad.local
'';
```

Applied via `sudo nixos-rebuild switch --flake ~/repositories/piergst/nixos-config#nixbook`.

## Missing Nix packages (found while porting)

- `hypridle` — needed for `hyprland/hypridle.conf` to do anything
- `playerctl` — media-key bindings in `hyprland.lua`
- `fzf` — `my-fzf-history` widget in `zsh/zshrc`
- `bat` — alias `c`, function `jbat` in `zsh/aliases.zsh`
- `jq` — function `jbat` in `zsh/aliases.zsh`
- `qt5ct` (or `qt6ct`) — `QT_QPA_PLATFORMTHEME` in `profile/profile`, for Qt apps (KeePassXC) to match the dark GTK theme
- ~~`zsh-powerlevel10k`~~ — done, see "powerlevel10k theme" below
- a C compiler (`gcc` or `clang`) — nvim-treesitter needs one to build parsers, found while testing `nvim/` live; `pkgs.tree-sitter` alone isn't enough

## Dropped as obsolete (not carried over, on purpose)

- `dot_Xresources` — only had URxvt and rofi Xresources theming, neither alacritty nor wofi read Xresources
- `picom.conf` — replaced by Hyprland's native compositor (already configured in `hyprland.lua`)
- `polybar/` and `rofi/` — replaced by `wayle` (your own UI-managed config) and `wofi`
- pacman-related aliases (`pacup`, `pa`, `paclean`) — no pacman on NixOS
- `m1`/`m3` xrandr screenlayout aliases — monitor setup now lives in `hyprland.lua`
- `cm='chezmoi'` alias — dotfiles now live here instead

## Écrans multiples — RESOLU via nwg-displays

Remplace l'ancien duo `arandr` + alias `m1`/`m3` de l'ancien setup i3.

**Outil retenu : `nwg-displays`** (dans `home.nix`). Il détecte que la config
Hyprland est en Lua et génère directement du `hl.monitor()` / `hl.workspace_rule()` :

- `~/.config/hypr/monitors.lua` — positions / résolutions / scale
- `~/.config/hypr/workspaces.lua` — répartition des workspaces par écran

`hyprland.lua` charge les deux via `require("monitors")` / `require("workspaces")`.
Il écrit aussi les `.conf` équivalents, inutilisés ici.

**Workflow :**

| Besoin | Commande |
|---|---|
| Arranger les écrans | `nwg-displays` (GUI), glisser-déposer puis "Apply" |
| Sauver la disposition | Bouton de sauvegarde de la GUI → `~/.config/nwg-displays/profiles/<nom>.json` |
| Basculer en CLI | alias `m1` / `m2` (profil + workspaces) |
| Basculer automatiquement | Hook `hl.on("monitor.added"/"monitor.removed")` dans `hyprland.lua` |

Profils actuels : `m1` (laptop seul) et `m2` (laptop + Lenovo D27-20B en HDMI,
externe à gauche). `m3` n'existe pas encore — le hook l'ignore tant qu'il n'est
pas créé.

**Workspaces par profil.** nwg-displays ne gère que les écrans, donc la
répartition vit dans la table `workspace_layout` de `hyprland.lua` (m1 → les 12
sur `eDP-1` ; m2 → 1-10 sur le Lenovo, 11-12 sur le laptop). `workspaces.lua`
généré par la GUI n'est plus chargé. Les alias `m1`/`m2` font
`nwg-displays-apply -p <nom>` puis `hyprctl eval 'apply_profile("<nom>")'` —
d'où l'exposition de `apply_profile` en globale : `hyprctl eval` partage l'état
Lua de la config mais ne voit pas les `local`.

**Pièges rencontrés :**

- `nwg-displays --help` et son README ne mentionnent **pas** `nwg-displays-apply` :
  le binaire existe pourtant et c'est le seul moyen de switcher en CLI.
- nwg-displays applique en écrivant ses fichiers **puis** `hyprctl reload` — il
  n'applique rien en live. Ses fichiers doivent donc rester chargés par
  `hyprland.lua`, sinon son bouton "Apply" n'a aucun effet.
- Les profils nwg-displays ne couvrent **que** les écrans, pas les workspaces.
- Les `workspace_rule` doivent être déclarées **au chargement** du fichier, pas
  dans `hl.on("hyprland.start")` : le `hyprctl reload` que fait
  nwg-displays-apply rejoue la config mais ne refire pas cet événement, les
  règles étaient perdues à chaque changement d'écran.
- La GUI plafonne à 10 workspaces par défaut → lancer `nwg-displays -n 12`
  pour pouvoir assigner les workspaces 11 et 12.
- Les `workspace_rule` ne s'appliquent qu'à la **création** d'un workspace. Un
  workspace déjà ouvert sur le mauvais écran n'est pas déplacé rétroactivement
  (typiquement le workspace 6, créé par l'autostart Firefox au démarrage).
- `hyprctl keyword` et la syntaxe legacy de `hyprctl dispatch` sont refusés avec
  une config Lua ("keyword can't work with non-legacy parsers"). Utiliser
  `hyprctl eval '<lua>'` à la place.

## API Lua — dispatchers vérifiés par introspection

Le contenu de `hl.dsp` est inspectable en direct :

```
hyprctl eval 'local f=io.open("/tmp/k.txt","w"); local k={}
for key,_ in pairs(hl.dsp.workspace) do table.insert(k,key) end
f:write(table.concat(k,", ")); f:close()'
```

- `hl.dsp.workspace` = `change_id, move, rename, swap_monitors, toggle_special`
- `hl.dsp.window` = `alter_zorder, bring_to_top, center, clear_tags, close,
  cycle_next, deny_from_group, drag, float, fullscreen, fullscreen_state, kill,
  move, pin, pseudo, resize, set_prop, signal, swap, tag, toggle_swallow`
- `hl.timer(fn, { timeout = <ms>, type = "oneshot"|"repeat" })` — signature
  trouvée en lisant les messages d'erreur, un argument à la fois.
- `hl.dsp.dpms` = **toggle**, pas d'état absolu (voir plus haut).
- Objets : `mon.name`, `ws.id` sont lisibles ; `pairs()` sur eux échoue
  (`HL.Monitor` / `HL.Workspace` ne sont pas des tables).

**`move_to_monitor` et `move_into_direction` n'existent pas.** Déplacer vers un
écran se fait avec `.move({ monitor = "l" })` (ou `"r"`, `"+1"`, `"-1"`, un nom
de sortie). Les sélecteurs relatifs suivent la position réelle des écrans, donc
ils marchent à 2 comme à 3 écrans. Corrigé pour les binds workspace et fenêtre ;
les 8 binds `hl.dsp.window.move_into_direction` (hjkl/flèches + SHIFT) sont
**encore à corriger** — probablement `hl.dsp.window.move({ direction = ... })`.

**Éteindre le 2e écran en gardant m1 — NON RÉSOLU.** Objectif : `m1` doit
éteindre le Lenovo même câble branché. Deux impasses, ne pas y revenir sans
lire ceci :

- `disabled = true` dans le profil : éteint bien l'écran, mais une sortie
  désactivée disparaît de `hl.get_monitors()` (et `hl.get_monitor()` renvoie
  `nil`) → le rebranchement du câble devient indétectable, l'auto-switch ne
  repart jamais.
- `hl.dsp.dpms` : c'est un **toggle**, la clé `state = "on"/"off"` est ignorée.
  Enchaîner des appels finit par éteindre toutes les dalles — a fait tomber la
  session (Hyprland relancé par le watchdog `start-hyprland`).
- Retirer la règle fourre-tout `hl.monitor({ output = "" ... })` ne change
  rien : Hyprland active de toute façon en mode préféré tout écran ne
  correspondant à aucune règle, la règle ne fait qu'expliciter ce défaut.

Piste non explorée : lire `/sys/class/drm/card1-HDMI-A-2/status`
(`connected`/`disconnected`), source indépendante d'Hyprland, et ne réagir
qu'aux **changements** — ce qui laisserait aussi survivre un `m1` forcé.

**Alternatives évaluées et écartées :** `kanshi` (pas de GUI, format de config
séparé à apprendre), `wdisplays` (pas de profils), `hyprmoncfg` (bon outil, gère
écrans + workspaces dans un même profil avec un daemon d'auto-switch, mais fait
doublon une fois `nwg-displays-apply` découvert).

## Dwindle — `togglesplit` inopérant sans `preserve_split`

Symptôme : `togglesplit` (bascule côte à côte ↔ empilé de la fenêtre active)
ne changeait rien sur deux fenêtres côte à côte.

Cause (source v0.56.2, `src/layout/algorithm/tiled/dwindle/DwindleAlgorithm.cpp`) :
`toggleSplit()` inverse bien `x->pParent->splitTop`, mais `recalcSizePosRecursive()`
recalcule l'orientation juste après et écrase le flag :

    if (*PPRESERVESPLIT == 0 && *PSMARTSPLIT == 0 && *PPRECISEMOUSEMOVE == 0)
        splitTop = box.h * *PFLMULT > box.w;

Avec les trois options à 0 (défaut), l'orientation est déduite du ratio de la
boîte à chaque recalc → le toggle est annulé. Le template livré par Hyprland
(`/nix/store/.../share/hypr/hyprland.lua`) met `preserve_split = true` avec le
commentaire « You probably want this » ; la ligne manquait dans le live.

Corrigé : `preserve_split = true` ajouté au bloc `dwindle` de
`~/.config/hypr/hyprland.lua`. Vérifié : `getoption dwindle:preserve_split` →
`true`, et deux Alacritty côte à côte s'empilent puis reviennent côte à côte.

Bind : `togglesplit` sur `mod + V`. `mod + V` était `togglefloating`, désormais
non bindé (à replacer sur une autre touche si besoin).

Non résolu, piste écartée pour l'instant : rendre `mod + shift + j` (move down)
« intelligent » (empiler quand il n'y a pas de voisine en dessous). En dwindle
`movewindow` ne permute pas : `moveTargetInDirection()` fait `removeTarget()` +
réinsertion au point focal, et avec `force_split = 2` la fenêtre retombe à
droite → no-op. Il faudrait un wrapper lisant la géométrie et choisissant
`movewindow` ou `togglesplit`.

## Still placeholder / needs your input

- `zsh/aliases.zsh`: exegol alias commented out (binary not installed on this machine yet)

## Écran de login — tuigreet remplacé par nwg-hello

`greetd` reste le daemon, seul le greeter change : le TUI `tuigreet` laisse place
à **nwg-hello** (GTK3, layer-shell, même auteur que nwg-displays).

nwg-hello est une simple appli GTK : elle ne sait pas piloter un tty, il lui faut
un compositeur hôte. On réutilise **Hyprland** (déjà présent) avec une config
minimale dédiée plutôt que d'ajouter `cage` :

```
services.greetd.settings.default_session.command =
  "${config.programs.hyprland.package}/bin/start-hyprland -- --config /etc/nwg-hello/hyprland.lua";
```

Le `hl.on("hyprland.start", ...)` de cette config lance `nwg-hello` puis
`hyprctl dispatch 'hl.dsp.exit()'` : le compositeur du greeter meurt dès que la
session utilisateur est choisie.

**Lancer le greeter comme la session utilisateur.** Deux warnings s'affichaient
à l'écran de login sur la première version (config `.conf` copiée du paquet,
appel direct de `Hyprland`), tous deux parce que le greeter était démarré
autrement que la session normale :

- *"You are using the .conf config format, support for which will be removed in
  Hyprland 0.57"* — Hyprland choisit son parseur **à l'extension du fichier** :
  `[cfg] Config is NOT lua, loading regular mgr` vs `Config is lua, loading lua
  mgr` dans le log. La conf du greeter est donc en `.lua`, comme
  `hyprland.lua`. Vérifiable sans rien casser :
  `Hyprland --verify-config -c <fichier>`.
- *"Hyprland is being launched without start-hyprland"* — `start-hyprland` est
  le **binaire de supervision** livré avec Hyprland (fork de `Hyprland` avec
  `--watchdog-fd`, redémarrage en cas de sortie sale, gestion nixGL). C'est lui
  qui est déclaré dans `hyprland.desktop` (`Exec=…/bin/start-hyprland`), donc la
  session utilisateur ne voit jamais ce warning ; le greeter appelait `Hyprland`
  directement. Les arguments Hyprland se passent après `--`.
  (Alternative écartée : garder l'appel direct et poser
  `misc:disable_watchdog_warning = true` — ça masque le message au lieu de
  l'aligner sur la session. Option trouvée via `hyprctl descriptions`.)

**Pièges rencontrés :**

- Le paquet nixpkgs **patche le chemin `/etc/nwg-hello` vers son propre préfixe
  dans le store** (`substituteInPlace nwg_hello/main.py`). Poser des fichiers
  dans `/etc/nwg-hello/` ne suffit donc pas : ils ne sont jamais lus. Il faut
  les passer explicitement avec `-c` (json) et `-s` (css). Vérifié en lisant
  `main.py` dans le store, pas dans le README.
- Pas de module NixOS pour nwg-hello (contrairement à `regreet`, `ly`, `sddm`…) :
  tout est écrit à la main dans `configuration.nix` (`services.greetd` +
  `environment.etc` + `systemd.tmpfiles`).
- Le json par défaut déclare une session custom `"exec": "/usr/bin/bash"` qui
  n'existe pas sur NixOS → `custom_sessions = []`.
- Équivalent du `--remember` de tuigreet : nwg-hello écrit dernier utilisateur
  et dernière session dans `/var/cache/nwg-hello/cache.json`. Le dossier n'est
  pas créé par le paquet → règle `systemd.tmpfiles` avec propriétaire `greeter`
  (le module greetd ne crée d'office que `/var/cache/tuigreet`).
- La config Hyprland du greeter tourne hors de `hyprland.lua` : le clavier
  repartirait en QWERTY sans un `input = { kb_layout = "fr" }` explicite dedans.
- Le `exec-once = ...; hyprctl dispatch exit` de la conf fournie par le paquet
  ne survit pas au passage en Lua : la syntaxe legacy de `hyprctl dispatch` est
  refusée par le parseur Lua (même piège que pour `hyprctl keyword`, voir plus
  haut). Il faut `hyprctl dispatch 'hl.dsp.exit()'`, sinon le compositeur du
  greeter ne quitte jamais une fois la session choisie.

**Test avant bascule :** `nwg-hello -t -d` (mode test, sans daemon greetd) lancé
dans un Hyprland imbriqué (`Hyprland --config <conf de test>` depuis la session
courante) affiche le greeter réel — sessions détectées, vocabulaire `fr_FR`,
CSS chargé — sans toucher au login de la machine.

La feuille de style pointe pour l'instant sur le CSS par défaut du paquet
(`${pkgs.nwg-hello}/etc/nwg-hello/nwg-hello-default.css`) — à personnaliser.

## Wayle — couleur du clignotement "urgent" des workspaces

Quand une appli demande le focus (ex : un lien ouvert vers Firefox depuis une
autre appli), Hyprland marque le workspace `urgent` et wayle le fait clignoter.
Le style intégré se contente de :

```css
.workspace.urgent:not(.urgent-application) { opacity: 0.5; }
.workspace-icon.urgent { opacity: 0.5; }
```

…donc un gris qui pulse sur un gris — quasi invisible. **Aucune option de
couleur pour ça dans `config.toml` ni dans wayle-settings** : le schéma
(`~/.config/wayle/schema.json`, `HyprlandWorkspacesConfig`) n'expose que
`urgent-show` (bool) et `urgent-mode` (`workspace` | `application`), à côté de
`active-color` / `occupied-color` / `empty-color` qui, eux, ne couvrent pas
l'état urgent.

Ça se règle donc en SCSS custom dans `~/.config/wayle/styles/index.scss` (chargé
après le style intégré, rechargé à chaud par le watcher de wayle) : on remet
`opacity: 1` et on fait clignoter la **couleur** à la place, via la variable
`--red` de la palette (`#e06c75`). Variables disponibles côté palette :
`--red` / `--yellow` / `--green` / `--blue` / `--accent`, plus les
`--status-error|warning|success|info`.

Pour repérer les sélecteurs d'un futur tweak de style : le CSS compilé est
embarqué dans le binaire, `strings $(readlink -f $(which wayle)) | grep -n '\.workspace'`
le sort tel quel.

## Paquets ajoutés le 2026-09-12 — bitwarden-desktop, tigervnc, herdr

Trois ajouts dans `home.packages` (`~/repositories/piergst/nixos-config/home.nix`), tous libres :
aucun changement nécessaire dans `nixpkgs.config.allowUnfreePredicate`.

| Paquet | Version | Licence | Bloc |
|---|---|---|---|
| `bitwarden-desktop` | 2026.8.0 | GPL-3 | securite / pentest |
| `tigervnc` | 1.16.2 | GPL-2+ | securite / pentest |
| `herdr` | 0.8.2 | Apache-2.0 | terminal |

Points relevés :

- **`tigervnc` n'installe aucune commande `tigervnc`** — c'est le nom du
  paquet. Le client est `vncviewer` ; le paquet fournit aussi `Xvnc`,
  `vncserver`, `vncsession`, `x0vncserver`, `w0vncserver`, `vncconfig`,
  `vncpasswd`. `vncviewer` est une appli X11, elle tourne sous Xwayland
  (option `-Scale` si le rendu est trop petit sur l'écran du MacBook).
- **`herdr`** avait déjà un `~/.config/herdr` (sessions, release-notes) alors
  que le binaire n'était pas dans le PATH : il tournait hors Nix avant cet
  ajout. La version du store reprend la config existante telle quelle.
- **`bitwarden-desktop`** est le client officiel : il faut le pointer sur le
  Vaultwarden self-hosted (*Paramètres → environnement auto-hébergé*,
  `https://nixbook.local`) **avant** le login, sinon il part sur
  bitwarden.com. C'est une appli Electron, donc elle n'utilise ni le magasin
  de Firefox (`programs.firefox.policies`) ni forcément celui du système
  (`security.pki.certificateFiles`) pour la CA interne de Caddy. **Testé et
  fonctionnel le 2026-09-12** : le client se connecte à
  `https://nixbook.local` sans manipulation supplémentaire sur la CA.

Rappel URL du service : **`https://nixbook.local`** (le conteneur n'écoute que
sur `127.0.0.1:8222`, Caddy fait le reverse proxy). Le vhost
`vaultwarden.local` présent dans `configuration.nix` pointe sur le même
backend mais **ne résout pas** — c'est le sous-domaine mDNS abandonné le
2026-08-31 (voir NEW_MACHINE.md, "mDNS ne supporte pas les sous-domaines").
À supprimer au prochain nettoyage.

## Lanceur .desktop "Firefox distant (VNC)" — posé à la main

Un Firefox tourne sur une machine distante, accessible en VNC. Pour le lancer
depuis wofi sans passer par le terminal :
`~/.local/share/applications/firefox-remote-vnc.desktop`

```ini
[Desktop Entry]
Type=Application
Name=Firefox distant (VNC)
GenericName=Navigateur distant
Comment=Ouvre la session VNC 192.168.1.189:5901 qui heberge Firefox
Exec=vncviewer 192.168.1.189:5901
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;RemoteAccess;
Keywords=vnc;firefox;distant;remote;
StartupNotify=false
```

Validé par `desktop-file-validate`. Repéré par wofi (`Super + D`, config en
`show=drun`) via les `Keywords` : "firefox", "vnc" ou "distant".
`~/.local/share/applications` est bien le `XDG_DATA_HOME/applications` de la
session, rien d'autre à déclarer.

`StartupNotify=false` est volontaire : `vncviewer` est X11/Xwayland et
n'émet pas de notification de démarrage, sinon curseur d'attente jusqu'au
timeout.

Fichier **hors Nix** (il persiste aux reboots et aux rebuilds, mais n'est pas
décrit dans le flake). Passage en déclaratif = `xdg.desktopEntries` dans
`home.nix` — attention, home-manager refusera alors d'écrire par-dessus le
fichier posé à la main : même piège que `mimeapps.list`, résolu par
`xdg.configFile."mimeapps.list".force = true` (`home.nix:135`).

## Agent SSH via Bitwarden desktop — déclaratif dans configuration.nix

Les clés SSH sont stockées dans le coffre Vaultwarden (éléments de type **Clé
SSH**, pas des notes sécurisées) ; le client Bitwarden desktop expose un agent
ssh-agent sur un socket Unix et demande une approbation lors des signatures
(voir la sous-section « Fenêtre d'approbation » plus bas : modal interne, pas une
fenêtre).

Vérifié dans le module natif du paquet installé
(`opt/Bitwarden/resources/app.asar.unpacked/.../desktop_napi.linux-x64-gnu.node`,
sources `core/src/ssh_agent/unix.rs` et `ssh_agent/src/server/listener/unix.rs`) :

- socket par défaut `~/.bitwarden-ssh-agent.sock` (codé en dur) ;
- surchargeable **côté Bitwarden** par `BITWARDEN_SSH_AUTH_SOCK` — si on s'en
  sert, il faut aligner `SSH_AUTH_SOCK` dessus ;
- l'implémentation est en Rust dans le module natif, **pas** dans `app.asar` :
  inutile de grepper le JS.

### Pourquoi `environment.sessionVariables` et pas `home.sessionVariables`

`home.sessionVariables` écrit dans
`/etc/profiles/per-user/pierre/etc/profile.d/hm-session-vars.sh`, **qui n'est
sourcé par rien dans cette config** : home-manager ne gère pas zsh ici (zsh est
déclaré au niveau système à cause du conflit oh-my-zsh, voir plus haut), et
`~/.zshenv` / `~/.zshrc` / `/etc/zshrc` ne le chargent pas.

Constaté empiriquement : `GTK2_RC_FILES`, que ce fichier définit, est absent à
la fois du shell et de `systemctl --user show-environment`. Donc
`home.sessionVariables` serait un no-op silencieux.

`environment.sessionVariables` (configuration.nix) atterrit dans
`/etc/set-environment`, lui effectivement chargé dans la session — c'est de là
que viennent `GTK_PATH`, `INFOPATH`, `NIX_PATH` visibles dans l'env systemd
user. Ça couvre donc les shells **et** les applis GUI lancées par
Hyprland/UWSM (le git de VSCodium, par exemple), ce qu'un `~/.zshenv` ne
faisait pas.

```nix
environment.sessionVariables.SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
```

Vérifié après `nix build` sur le toplevel : la ligne
`export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"` est bien présente dans
`$out/etc/set-environment` (`$HOME` est expansé au chargement, c'est un fichier
shell).

Le réglage temporaire posé dans `~/.zshenv` a été retiré au profit de celui-ci.

### Fenêtre d'approbation — un modal interne, pas une fenêtre

Vérifié dans `app.asar` de 2026.9.0 (`app/main.js` = bundle renderer, `main.js`
= process Electron principal) :

- le prompt est un composant Angular `app-approve-ssh-request` ouvert en
  `bit-dialog` **dans la fenêtre principale** : `processSignRequest()` fait
  `ipc.platform.focusWindow()` puis `Z.open(this.dialogService, ...)` ;
- le preload traduit `ipc.platform.focusWindow()` en IPC `window-focus`, traité
  côté main par `this.win.show(); this.win.focus();` ;
- il n'y a **aucune seconde fenêtre** : aucune `window_rule` / `layer_rule`
  Hyprland ne peut le déplacer, le prompt apparaît toujours sur le workspace de
  la fenêtre Bitwarden (d'où la contrainte initiale : aller sur le workspace 3
  pour valider une demande déclenchée depuis le 5).

Contournement retenu, côté Hyprland : `misc.focus_on_activate = true` dans
`~/.config/hypr/hyprland.lua:362` (bloc `misc`). La demande d'activation émise
par `win.focus()` est alors honorée → bascule sur le workspace de Bitwarden et
focus de la fenêtre à chaque requête. C'est « on t'amène à la fenêtre », pas
« la fenêtre vient à toi ». Vérifié après `hyprctl reload` :
`hyprctl getoption misc:focus_on_activate` → `bool: true`. Le déclenchement
réel de la bascule sur une requête SSH (activation Electron via XWayland ou
Wayland selon le lancement) reste à confirmer par un `ssh` réel.

Second levier, côté client : *Paramètres → Agent SSH* → « Ask for authorization
when using SSH agent » — `always` (défaut) / `never` / `rememberUntilLock`.
En `rememberUntilLock`, le cache `authorizedHosts` est indexé par clé SSH et la
clé de cache vaut `local` quand la requête n'est pas *forwardée* : **une seule
approbation couvre alors toutes les signatures locales**, toutes applications
confondues, jusqu'au verrouillage du coffre (en forwarding, clé de cache par
empreinte d'hôte). C'est un toggle d'UI, non automatisable.

### Solution retenue — Bitwarden en scratchpad (2026-09-27)

Problème concret : en workgroup 4, une signature SSH déclenche `win.focus()` →
`focus_on_activate = true` fait basculer Hyprland sur le workspace de Bitwarden
(wg1) à chaque demande.

Solution : mettre Bitwarden sur un **workspace spécial** (`special:bitwarden`).
Un special a un id **négatif**, donc hors des bandes `1..60` : `omarchy-wsgroup`
l'ignore (`occupied_groups` filtre `.id >= 1`, `group_of` retombe sur
`current_group`). L'activation **révèle le special en overlay** par-dessus le
workgroup courant → on valide la demande sans changer de workgroup.

- `~/.config/hypr/hyprland.lua` :
  - `window_rule` `bitwarden-scratchpad` (`match.class = "^(bitwarden)$"`,
    `workspace = "special:bitwarden"`) ;
  - bind `Super+B` → `hl.dsp.workspace.toggle_special("bitwarden")`.
- `~/.config/wayle/runtime.toml` : `[modules.hyprland-workspaces]
  show-special = false`, sinon le special apparaît dans la barre sous son id brut
  (`-98`, non couvert par `workspace-ignore` qui ne liste que les ids positifs).

Vérifié en live :

- déplacer une fenêtre de test sur un special puis la focus →
  `monitors[].specialWorkspace` non nul, **workspace actif inchangé** (resté 5) ;
- instance Bitwarden déjà ouverte : une `window_rule` ne s'applique qu'à
  l'ouverture, donc déplacement ponctuel via
  `hyprctl dispatch 'hl.dsp.window.move({window="class:bitwarden",
  workspace="special:bitwarden", follow=false})'` (selecteur de fenêtre accepté par
  l'API Lua ; `dsp_focusWindowBySelector` confirme les selecteurs `class:`/`address:`) ;
- `toggle_special` → overlay Bitwarden affiché, barre toujours sur le ws 5 ;
- **focus d'une fenêtre normale → l'overlay se referme seul**
  (`specialWorkspace` repasse à 0), donc aucun handler d'auto-hide nécessaire.

Conséquence d'usage : Bitwarden est désormais **caché par défaut**, accessible via
`Super+B` ; au prochain démarrage du client la `window_rule` le place directement
dans le special.

Piège : pour masquer le scratchpad c'est **`Super+B`** (toggle), pas `Super+G` qui
est le bind « fermer la fenêtre » → ça ferme Bitwarden (part en tray) et laisse un
scratchpad **vide** (Super+B n'affiche alors qu'un vide et fait juste perdre le
focus). Le scratchpad se referme aussi seul quand on re-focus une autre fenêtre.

### Limites

- Le client doit **tourner et être déverrouillé**, sinon le socket n'existe
  pas : `ssh` affiche une ligne d'erreur puis retombe sur `~/.ssh/id_ed25519`,
  qui reste utilisable en parallèle.
- L'activation de l'agent est un **toggle dans l'UI du client**
  (*Paramètres → Agent SSH*), non automatisable depuis Nix.
- Rien ne définissait `SSH_AUTH_SOCK` avant (ni `programs.ssh.startAgent`, ni
  gnome-keyring) : pas de conflit à gérer.

## Clavier interne du MacBook — remappage via une keymap XKB dédiée

Le clavier du MacBook n'a ni la disposition de modificateurs d'un PC, ni la
touche `<>` de l'ISO, ni de flèche droite utilisable. Tout est corrigé dans une
keymap XKB complète appliquée **au seul clavier interne** ; un clavier externe
branché plus tard retombe sur le bloc `input` global (`kb_layout = "fr"`),
inchangé.

- `~/.config/hypr/mbp-fr-keymap.xkb` — la keymap (commentée en tête)
- `~/.config/hypr/hyprland.lua` — le bloc `hl.device` qui la branche

```lua
hl.device({
    name    = "apple-inc.-apple-internal-keyboard-/-trackpad",
    kb_file = "/home/pierre/.config/hypr/mbp-fr-keymap.xkb",
})
```

Le nom du périphérique vient de `hyprctl devices`. `hid_apple` reste en config
par défaut (`swap_opt_cmd=0`) : tout se joue au niveau XKB.

### Mapping obtenu

| Touche physique | Avant | Après | Moyen |
|---|---|---|---|
| Option gauche | Alt | **Super** | `altwin:swap_lalt_lwin` |
| Command gauche | Super | **Alt** | idem |
| Command droite | Super droit | **AltGr** | `level3(rwin_switch)` |
| Option droite | AltGr | **`<` / `>`** | override `<RALT>` |
| Fn + Gauche | Home | **Droite** | override `<HOME>` |
| Fn + Maj + Gauche | — | **Home** | niveau 2 du même override |

Les deux premières lignes sont des options XKB standard ; le reste demande des
overrides de keysym, d'où le choix de `kb_file` (keymap complète) plutôt que
`kb_options`. Hyprland 0.56.2 expose bien `kb_file`, vérifié dans le binaire.

### Trois pièges, tous coûteux en temps

**1. `hyprctl reload` ne relit PAS le `kb_file`.** Tant que le *chemin* dans la
config ne change pas, Hyprland garde la keymap déjà compilée, même si le
contenu du fichier a changé. On a débogué pendant plusieurs itérations une
keymap correcte qui n'était simplement jamais chargée. Pour forcer :

```sh
cd ~/.config/hypr
cp mbp-fr-keymap.xkb .reload-tmp.xkb
sed -i 's|hypr/mbp-fr-keymap.xkb"|hypr/.reload-tmp.xkb"|' hyprland.lua && hyprctl reload
sed -i 's|hypr/.reload-tmp.xkb"|hypr/mbp-fr-keymap.xkb"|' hyprland.lua && hyprctl reload
rm .reload-tmp.xkb
```

**2. Alt (Mod1) ne peut pas servir de sélecteur de niveau.** Un type maison
`{ modifiers = Mod1; map[Mod1] = Level2; }` compile sans erreur et fonctionne
côté XKB, mais les applications ne consomment pas Mod1 : elles reçoivent un
vrai `Alt + Right`. Symptômes observés — un terminal affiche `C` (la séquence
`\e[1;3C` qui fuit), un shell saute en fin de ligne, Firefox ne fait rien.
Seuls Shift / LevelThree / LevelFive sont traités correctement en aval. Pour un
vrai `Alt + Gauche`, il faudrait un remappeur au niveau evdev (`keyd`, dispo en
2.6.0 dans nixpkgs), en amont de XKB.

**3. `hid_apple` traduit les combinaisons Fn lui-même** (`fnmode=3`). `Fn +
Gauche` n'existe pas au niveau XKB : le driver envoie `<HOME>`. Fn *est* bien
visible séparément (`<I472>` / `XF86Fn`), mais la touche qui suit est déjà
traduite. D'où l'override sur `<HOME>` et non sur `<LEFT>`. Idem pour
`Fn + Droite` → End, `Fn + Haut/Bas` → PageUp/PageDown.

### Outils de diagnostic

`xkbcli` (paquet `libxkbcommon`, pas installé — passer par le store ou
`nix shell nixpkgs#libxkbcommon`) :

```sh
# valider la keymap et inspecter le resultat compile
xkbcli compile-keymap --keymap ~/.config/hypr/mbp-fr-keymap.xkb | \
  grep -E 'key <(LALT|LWIN|RALT|RWIN|LEFT|HOME)>' -A3

# voir ce que le compositeur envoie REELLEMENT (keycode, keysym, niveau, mods)
xkbcli interactive-wayland
```

`interactive-wayland` est l'outil décisif : c'est lui qui a montré
`level [ 0 ]` alors que le modificateur `Mod5 LevelThree` était bien actif,
révélant le piège n°1, puis que `Fn + Gauche` sortait en `HOME`.

À noter : `hyprctl getoption 'device[...]:<option>'` répond toujours
« no such option », **même pour une option valide** — y compris sur le
`epic-mouse-v1` de la config d'exemple. `getoption` ne sait pas lire les
sections device ; ce n'est pas un signal d'échec, ne pas s'en servir pour
diagnostiquer.

### Reste à faire

Ces deux fichiers sont des dotfiles classiques, hors Nix. En phase 2, la keymap
devient un `xdg.configFile."hypr/mbp-fr-keymap.xkb".source` dans `home.nix` —
avec le même piège d'écrasement que `mimeapps.list` si le fichier posé à la
main est encore là.

## Alacritty — copie par surlignage souris (comportement tmux)

Par défaut Alacritty n'alimente que la sélection PRIMARY (collable au clic
milieu) ; le presse-papier que lisent `Ctrl+V` et `wl-paste` reste vide. Une
seule option suffit, dans `~/.config/alacritty/alacritty.toml` :

```toml
[selection]
save_to_clipboard = true
```

Confirmé dans `man 5 alacritty` de la 0.17.0 : *"When set to true, selected
text will be copied to the primary clipboard"*, `false` par défaut. La config
est rechargée à chaud, pas besoin de relancer le terminal. `cliphist` récupère
ces copies comme les autres, et le `Alt+y` (`Copy`) du mode Vi n'est pas
affecté.

### Limite acceptée : la sélection reste affichée après le relâchement

Contrairement à tmux, le surlignage ne disparaît pas quand on lâche le bouton
— il persiste jusqu'au clic suivant. **Ce n'est pas configurable** :

- `[selection]` n'expose que `semantic_escape_chars` et `save_to_clipboard` ;
- l'action `ClearSelection` existe, mais les bindings souris ne se déclenchent
  que sur un **appui** (*"Mouse button which needs to be pressed to trigger
  this binding"*), il n'y a pas d'événement de relâchement exposé ;
- binder `Left` sans modificateur pour la déclencher écraserait le démarrage de
  la sélection elle-même.

Choix fait le 2026-09-15 : on vit avec, c'est purement visuel et la sélection
part au clic suivant. Si ça devient gênant, les deux replis sont un raccourci
clavier `ClearSelection` hors mode Vi (il en existe déjà un en mode Vi, `x`),
ou passer par tmux qui gère lui-même la sélection (`mouse on` est déjà dans
`~/.tmux.conf`).

## Claude Desktop — repackagé depuis le .deb officiel (2026-09-19)

L'app de bureau Claude n'est **pas dans nixpkgs** (une quinzaine de paquets
`claude-*` y existent — CLI, adaptateurs ACP, monitors — mais aucun desktop).
Anthropic publie en revanche une build Linux officielle, en bêta, sous forme
de `.deb` pour Ubuntu/Debian (x64 et arm64), distribuée via un dépôt apt.

Choix : **repackager le .deb officiel** dans une dérivation maison plutôt que
d'utiliser le flake communautaire `k3d3/claude-desktop-linux-flake`. Ce dernier
date d'avant la sortie Linux officielle et remplace la bibliothèque native
`claude-native-bindings` par des stubs ; le `.deb` officiel embarque la vraie
(`resources/app.asar.unpacked/node_modules/@ant/claude-native/`), le flake est
donc devenu redondant.

Résultat : `pkgs/claude-desktop.nix` (version 2.2553.1), appelé depuis
`home.nix` via `pkgs.callPackage`. Electron classique : `dpkg` +
`autoPatchelfHook` + `wrapGAppsHook3`.

### Obtenir l'URL et le hash d'une nouvelle version

Le `.deb` n'a pas d'URL « latest » stable ; il faut lire l'index du dépôt :

```sh
curl -s "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages" \
  | grep -E '^(Version|Filename|SHA256):'
```

Prendre la dernière version (`sort -V`), l'URL est
`https://downloads.claude.ai/claude-desktop/apt/stable/<Filename>`, et le
SHA256 de l'index se convertit en SRI avec `nix-hash --to-sri --type sha256`.

### Pièges rencontrés

- **`dpkg-deb -x` échoue dans le sandbox nix** : il tente de restaurer le bit
  setuid de `chrome-sandbox` (`Cannot change mode to rwsr-xr-x`). Contourné par
  `dpkg-deb --fsys-tarfile | tar -x --no-same-permissions --no-same-owner`.
- **`chrome-sandbox` est inutilisable depuis /nix/store** (monté nosuid, bits
  setuid effacés). Supprimé de la dérivation, l'app est lancée avec
  `--no-sandbox` via le wrapper. C'est le compromis habituel pour les Electron
  repackagés ; l'alternative propre serait `security.wrappers`.
- **`virtiofsd` embarqué** (composant Cowork) réclame `libseccomp` et
  `libcap-ng` — attribut nixpkgs `libcap_ng`, pas `libcap-ng`.
- **Nom du `.desktop`** : `com.anthropic.Claude.desktop`, pas
  `claude-desktop.desktop`.
- **Attributs `xorg.libX*` dépréciés** dans nixpkgs 26.11 : utiliser `libx11`,
  `libxcb`, `libxtst`, etc. en top-level.
- **Enregistrement du schéma `claude://`** : l'app essaie de s'inscrire toute
  seule au démarrage et échoue, `~/.config/mimeapps.list` étant un symlink vers
  le store géré par home-manager (`Failed to create file
  "/nix/store/...-mimeapps.list": Read-only file system`). Ce n'est **pas** un
  défaut de packaging : l'association est déclarée dans `xdg.mimeApps` de
  `home.nix`.
- **Fichier non tracké par git** : un flake ne voit que les fichiers indexés,
  `git add pkgs/claude-desktop.nix` est obligatoire avant le rebuild.

### Vérifié

Build OK et lancement testé sous Hyprland : la fenêtre apparaît en
**Wayland natif** (`hyprctl clients` → `com.anthropic.Claude`, `xwayland:
false`) grâce à `--ozone-platform-hint=auto`. `nixos-rebuild build` passe sur
la config complète.

Non testé : la connexion au compte, et **Cowork**, qui demande KVM
(virtualisation matérielle, appartenance au groupe `kvm`, `qemu-system-x86`,
`ovmf`, `virtiofsd`) — rien de tout ça n'est câblé côté NixOS pour l'instant.
Computer Use et la dictée sont absents de la bêta Linux.

## Paseo — build local du fork, auto-fetch coupé (2026-09-26)

Orchestrateur d'agents de codage (GUI desktop + CLI + daemon local), absent de
nixpkgs. Le repack du `.deb` officiel (`pkgs/paseo.nix`) est abandonné au profit
d'un **build local d'un fork** du dépôt, ajouté à `~/repositories/piergst/nixos-config` comme input
flake.

Raison : Paseo exécute un `git fetch` automatique (au lancement puis toutes les
3 min) sur chaque dépôt ayant une remote `origin`, sans flag pour le couper.

### Le fork et le flag `daemon.git.autoFetch`

Dépôt : `~/repositories/external/paseo`, HEAD détaché sur le tag `v0.9.2` plus
des modifications non committées. Le patch est décrit dans `PATCH-AUTOFETCH.md`
à la racine du dépôt.

Il ajoute un flag de config `daemon.git.autoFetch` (défaut `true`) qui gate la
boucle de fetch de fond (`workspace-git-service.ts`) : interval de 3 min + fetch
immédiat à l'enregistrement d'un workspace avec `origin`. Résolution de la
valeur, dans l'ordre : `PASEO_GIT_AUTO_FETCH` → `daemon.git.autoFetch` → `true`.

Fichiers modifiés : `packages/protocol/src/messages.ts` et
`packages/server/src/server/{persisted-config,daemon-config-store,config,workspace-git-service,bootstrap}.ts`.

### Câblage dans ~/repositories/piergst/nixos-config

- `flake.nix` : input `paseo.url = "path:/home/pierre/repositories/external/paseo"`.
- `home-manager.extraSpecialArgs = { inherit inputs; }` pour exposer l'input à `home.nix`.
- `home.nix` : remplace `(pkgs.callPackage ./pkgs/paseo.nix { })` par
  `inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop` (app) et
  `inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.paseo` (CLI `paseo`
  + `paseo-server`). `pkgs/paseo.nix` n'est plus référencé.

### Pièges du fork et du build Nix

- **`nix/npm-deps.hash` du tag `v0.9.2` obsolète** : `package-lock.json`
  identique à `main`, mais le hash divergeait → `hash mismatch in fixed-output
  derivation … npm-deps`. Corrigé avec la valeur de `main` :
  `git checkout main -- nix/npm-deps.hash`.
- **Un input `path:` ignore `.gitignore`** : le symlink `result` laissé par
  `nix build` dans le dépôt entre dans la source du flake, change le `src` et
  force un rebuild complet. Ne pas créer `result` dans le dépôt (`nix build -o
  /tmp/…`), ou le supprimer avant de relocker.
- **Un input `path:` est verrouillé par `narHash`** : après toute modif du fork,
  `nix flake update paseo` est obligatoire, sinon la source verrouillée
  (l'ancienne) reste utilisée sans erreur.
- **`.#desktop` (Nix) plantait au lancement du daemon** : `Cannot find module
  '.../@getpaseo/server/dist/server/server/exports.js'`. Le lanceur résout le
  paquet serveur via `require.resolve("@getpaseo/server")`
  (`packages/desktop/src/daemon/runtime-paths.ts`,
  `packages/cli/src/commands/daemon/local-daemon.ts`), que `@vercel/nft` ne suit
  pas à travers `createRequire(import.meta.url)` — `exports.js` n'était pas
  embarqué. Corrigé localement en l'ajoutant à `additionalInputs` dans
  `scripts/trace-daemon.mjs`. La CI ne le voit pas : `nix.yml` build `.#desktop`
  sans le lancer, et teste le daemon via `result/bin/paseo-server` (qui
  contourne `require.resolve`) ; le `.deb`/`.rpm` officiel passe par
  electron-builder (node_modules complet).
- **`~/.paseo/config.json` est réécrit par le daemon** : une édition manuelle
  cassée (JSON invalide, mauvaise casse de clé) fait échouer
  `loadPersistedConfig` et empêche le daemon de démarrer. Passer par
  `paseo daemon config set daemon.git.autoFetch false --home ~/.paseo`.

### Déploiement

```bash
cd ~/repositories/piergst/nixos-config
nix flake update paseo                    # après toute modif du fork
sudo nixos-rebuild switch --flake ~/repositories/piergst/nixos-config#nixbook
```

Couper le fetch côté runtime — `~/.paseo/config.json` :

```json
{ "version": 1, "daemon": { "git": { "autoFetch": false } } }
```

ou `PASEO_GIT_AUTO_FETCH=0` au lancement.

### Ce que Paseo fait (et ne fait pas)

Vérifié dans le source, pas sur la foi des docs : Paseo **n'embarque pas
d'agent**, il lance les CLI déjà installées sur la machine. Pour pi
(`packages/server/src/server/agent/providers/pi/`) :

```js
// cli-runtime.ts
const DEFAULT_PI_COMMAND = [ process.env.PI_COMMAND ?? process.env.PI_ACP_PI_COMMAND ?? "pi" ];
```

lancé en `pi --mode rpc` (le mode programmatique de pi), avec selon les
réglages `--model`, `--thinking`, `--session`, `--mcp-config`. La boucle
agentique, les clés, les sessions et les serveurs MCP restent ceux de pi.

Nuance : Paseo injecte **systématiquement** une extension générée dans un
fichier temporaire (`--extension /tmp/paseo-pi-extension-*/paseo-integration.mjs`,
`agent.ts:2537`). C'est essentiellement de l'observabilité — elle s'accroche au
`sessionManager` pour réémettre les messages via `ctx.ui.notify` et permettre au
GUI de reconstruire l'arbre de conversation. Elle contient aussi un hook
`before_agent_start` qui **ajoute** au system prompt, mais seulement si
`config.systemPrompt` / `daemonAppendSystemPrompt` est renseigné côté Paseo.

À noter : `PI_ACP_PI_COMMAND` est la même variable que celle utilisée par
l'adaptateur `pi-acp` de Zed — un seul réglage vaut pour les deux.

### Historique — repack du .deb officiel (2026-09-19, abandonné)

Première approche, remplacée par le fork ci-dessus. `pkgs/paseo.nix`
repackageait le `.deb` des releases GitHub (Apache-2.0 ; URL stable
`.../releases/download/v<version>/Paseo-<version>-amd64.deb`).

Pièges du repack, à connaître si on y revient : Paseo parse son propre `argv`
(commander) et rejette `--ozone-platform-hint=auto` (contourné par
`ELECTRON_OZONE_PLATFORM_HINT=auto`) ; layout `/opt/Paseo` ; `chrome-sandbox`
setuid inutilisable depuis le store ; `.desktop` nommé `Paseo.desktop` ; CLI du
bundle = script sh qui suit ses symlinks (un `ln -s` suffit) ;
`gsettings-desktop-schemas` requis.

Vérifié alors : `paseo --version` → `0.8.0`, fenêtre Wayland native, daemon
démarré.

## hyprkool — « bureaux virtuels » à la Windows (tenté le 2026-09-27, abandonné)

**Objectif.** Des bureaux virtuels façon Windows : N bureaux, chacun avec ses 12
workspaces ; changer de bureau donne 12 workspaces neufs, revenir rend les
appli du bureau d'origine.

**Ce qu'est hyprkool.** Un CLI + daemon (Rust) et un plugin C++ optionnel. Ce
n'est **pas** un gestionnaire de bureaux : une « activité » n'est qu'une
**convention de nommage** de workspaces — `activité:(x y)`, grille `X×Y` par
activité (`workspaces = [12, 1]` → 12 cases en ligne). hyprkool ne déplace
aucune fenêtre : il faut y ranger les appli soi-même. Et un workspace d'activité
**vide est détruit par Hyprland** dès qu'on le quitte.

### Blocage principal : la config Lua d'Hyprland casse le dispatch

Quand la config est en **Lua** (`hyprland.lua`), Hyprland 0.56.2 réécrit tout
`dispatch` reçu par l'IPC (`src/ipc/s1/Commands.cpp`, `dispatchRequest`) :

```cpp
if (Config::mgr()->type() == CONFIG_LUA)
    eval("return hl.dispatch(" + in + ")");
```

Donc la syntaxe **classique** ne passe plus, même pour un dispatcher natif :

```
hyprctl dispatch workspace 3
→ error: [string "return hl.dispatch(workspace 3)"]:1: ')' expected near '3'
```

hyprkool 0.9.2 (`master`) émet exactement cette syntaxe (via `hyprland-rs`) :
dans une config Lua, **toutes** ses commandes d'action échouent (seul `info`,
pur lecture, marche).

C'est corrigé sur la branche **`dev`** (0.9.3) : `271fe73` (« change all
dispatches to use lua syntax » — tout passe par `DispatchType::Custom("hl.dsp.…")`),
`92b3a60` (préfixe `name:` sur les workspaces nommés) et `074a03c` (animations en
Lua). Vérifié en live sur 0.56.2 : `switch-to-activity`, `move-*`,
`toggle-special-workspace`, `remember_activity_focus` et le harpoon fonctionnent.

### Blocage secondaire : le plugin C++ est mort

Le plugin (animations directionnelles) hooke
`CDesktopAnimationManager::startAnimation`, classe **supprimée** des headers
0.56.2 (`managers/animation/` n'existe plus). `dev` le supprime (Hyprland 0.51.1+
gère ça nativement) et stubbe `obsolete.cpp`. Optionnel de toute façon.

### Blocage décisif : la barre (wayle)

wayle 0.7.0 n'offre que deux options, aucune ne convient :

- module **natif** `hyprland-workspaces` : cliquable, icônes par app, et il gère
  déjà `name:`/Lua pour le clic (chaînes présentes dans `.wayle-wrapped`). Mais
  **aucun filtre par activité** : il liste tous les workspaces, triés par ID,
  avec le nom complet → `2:(2 1) 1:(5 1) 1:(6 1) 1:(7 1) 1:(4 1) …`, illisible.
- module **`custom`** : on peut afficher les 12 cases du bureau courant
  (`hyprkool info -m` → `{"text":"1 | 1 2 [3] …"}`), mais un module `custom`
  n'est **qu'un libellé** : ni clic ni icône par case.

Patcher wayle (MIT) est possible — filtrer par activité, trier par case, libellé
= n° de case — mais coûte un patch Rust sur 3-4 fichiers, un `overrideAttrs`
nixpkgs, un build long, et un rebasage à chaque update. Jugé disproportionné.

### Pièges rencontrés (valables au-delà de hyprkool)

- **PATH de Hyprland.** `exec`/`exec-once` tournent avec le PATH de la session
  systemd (`systemctl --user show-environment`), qui ne contient **pas**
  `~/.local/bin`. Un binaire posé là est « introuvable » depuis un bind →
  chemins absolus (`$HOME/.local/bin/…`), ou `home.sessionPath`.
- **`HYPRLAND_INSTANCE_SIGNATURE` périmée.** Le shell de l'agent garde une
  ancienne signature ; relancer un process de session (ex. `wayle panel
  restart`) depuis ce shell le branche sur une instance morte (service hyprland
  wayle HS). → relancer avec la signature vivante ou via un `exec` Hyprland.
- **Collision de bind.** `mainMod + ALT + L` = hyprlock, et la casse est ignorée
  → `ALT+l` est pris.
- **hyprshell** réserve `Super+Tab` (window switcher : `~/.config/hyprshell/config.ron`,
  `switch = { modifier = "super", key = "Tab" }`) — à déplacer si on veut
  `Super+Tab` pour autre chose.

### Verdict

Abandonné. Le modèle (bureaux × 12 workspaces) est exactement celui de hyprkool,
mais il exige (a) une version non releasée (`dev`), (b) une migration manuelle
forçant les fenêtres dans les activités, et surtout (c) une barre incapable de
l'afficher. La barre tue l'expérience.

### Remis en état

- `~/.config/hypr/hyprland.lua` restauré depuis
  `hyprland.lua.bak-20260927-185252` (0 occurrence de hyprkool).
- Fenêtres remises des workspaces `activité:(N 1)` vers les numériques `N`.
- Supprimés : `~/.config/hypr/hyprkool.toml`, `~/.local/bin/hyprkool`,
  `~/.local/bin/hyprkool-bar` ; daemon arrêté.
- `~/.config/wayle/runtime.toml` restauré depuis
  `runtime.toml.bak-20260927-195011` (natif `hyprland-workspaces`, sans
  `label-use-name`).
- Builds/clones temporaires dans `/tmp` supprimés.

## Bureaux virtuels — omarchy-desktop-groups adapté (2026-09-27)

**Besoin.** Des bureaux virtuels façon Windows : N bureaux, chacun avec ses 12
workspaces ; `Super+1..0` agit sur le bureau courant ; la barre n'affiche que le
bureau courant. C'est la suite de la section hyprkool (qui a échoué).

**Ce qui marche (et pourquoi).** Le modèle est celui des « groupes de
desktops » : le groupe `g` possède la bande de workspaces
`(g-1)*PER_GROUP+1 .. g*PER_GROUP`. La différence avec hyprkool : ce sont de
**vrais workspaces numériques**, donc la barre wayle native (clics + icônes)
fonctionne — c'est précisément ce que hyprkool rendait impossible.

Base : [`burakTanBilgi/omarchy-desktop-groups`](https://github.com/burakTanBilgi/omarchy-desktop-groups)
(MIT, bash, ~200 lignes) ; clone local dans
`~/repositories/external/omarchy-desktop-groups`. Attention à l'homonyme
`mdelgert/omarchy-desktop-groups` (multi-écran, désactivé en mono-écran).

### Adaptations faites au script

1. **Dispatchs en Lua.** Le script fait `hyprctl dispatch workspace N` /
   `movetoworkspace`, syntaxe classique refusée par une config Hyprland en Lua
   (voir la section hyprkool). Remplacé par des helpers
   `hyprctl dispatch "hl.dsp.focus({workspace = N})"` et
   `hl.dsp.window.move({workspace = N[, follow = false]})`.
2. **Filtrage barre : Waybar → wayle.** Waybar utilise `ignore-workspaces` +
   `SIGUSR2` ; wayle n'a pas d'équivalent direct. Le script écrit à la place
   `~/.config/wayle/wsgroup.toml`, importé par `~/.config/wayle/config.toml`
   (`imports = ["wsgroup.toml"]`), et wayle recharge tout seul (il surveille son
   répertoire de config). Ce fichier contient :
   - `workspace-ignore` : les IDs hors de la bande courante (recalculé à chaque
     bascule de groupe) ;
   - `workspace-map` : table **statique** mappant chaque ID à son **slot**
     (`13 → 1`, `24 → 12`, `25 → 1`, …), pour afficher `1..12` et non l'ID absolu.
     Wayle expose `workspace-map.<id>.label` là où Waybar a `format-icons`.
3. L'indicateur de groupe `● ○ ○` : **un module `custom` wayle PAR groupe**
   (`custom-wsg1` .. `custom-wsg5`), pour que **chaque point soit cliquable vers
   SON groupe** (un module = une action `left-click = "omarchy-wsgroup go N"`,
   impossible avec un seul module texte puisqu'un module n'a qu'un clic). Chaque
   module lance `omarchy-wsgroup indicator N` en **mode `watch`** : la commande
   émet une ligne puis suit le socket d'événements Hyprland (`nc -U
   $XDG_RUNTIME_DIR/hypr/$SIG/.socket2.sock`) et ré-émet à chaque `workspace`,
   `focusedmon`, **et** `openwindow`/`closewindow`/`movewindow` (l'occupation d'un
   groupe change aussi à l'ouverture/fermeture d'une fenêtre) : pas de polling,
   donc pas de lag. Un `nc` par module (5) reste bien moins coûteux qu'un poll :
   un `hyprctl` coûte ~20 ms, 5 modules en poll à 1 s satureraient un c½ur.
   `indicator N` émet `●` si N est le groupe courant, `○` s'il est occupé, rien
   sinon ; `hide-if-empty = true` masque alors le bouton **et son espace**. Filtre
   identique au module workspaces (`min-workspace-count=0`) : seuls les groupes
   occupés s'affichent, **plus toujours le groupe courant** même vide — un groupe
   n'existe pas en soi, c'est une bande d'IDs, et Hyprland ne matérialise un ws
   qu'avec une fenêtre. Clic gauche = groupe N ; `Super+CTRL+n` reste l'accès direct.
   (Les commandes wayle vivent dans `~/.config/wayle/runtime.toml`, la couche
   « runtime override » — `wayle config set` y écrit ; `config.toml` ne fait que
   `imports = ["wsgroup.toml"]`. Wayle charge les deux : `include = ["config.toml",
   "runtime.toml"]`.)
   **Compacité** : chaque module gardant le padding de label de bouton de la barre
   (`.bar-button-content { margin: var(--bar-btn-label-padding) }` et pastille de
   fond `menubutton.bar-button > button.toggle`), 5 modules = 5 pastilles larges →
   bien plus large que l'ancien single module. Corrigé dans le CSS utilisateur
   `~/.config/wayle/styles/index.scss` : les 5 modules sont mis dans une `BarGroup`
   `{ name = "wsgroups", modules = [...] }` (le nom devient un sélecteur CSS `#wsgroups`,
   cf. `factory.rs` `set_widget_name`), et le CSS scoped `#wsgroups` remet le padding
   à zéro (les points gardent la hauteur d'un bouton), supprime la pastille par point
   et met le fond de groupe transparent. Résultat : `● ○ ○` nu, taille de l'ancien
   module.

### Réglages

- `PER_GROUP=12`, `GROUP_COUNT=5` → groupe 1 = `1..12` (l'ancienne disposition),
  groupe 2 = `13..24`, … groupe 5 = `49..60`.
- Binds (`hyprland.lua`) : `Super+1..0` **et** `code:20`/`code:21` → slot 1..12 du
  groupe courant ; `Super+SHIFT+…` → y déplacer la fenêtre ; `Super+CTRL+1..5` →
  changer de groupe ; `Super+CTRL+SHIFT+1..5` → y envoyer la fenêtre ;
  `Super+Tab` / `+SHIFT` / `+CTRL` / `Super+molette` → cycler dans le groupe.
  Sur la barre, **clic gauche sur un point → son groupe** ; plus de « groupe
  suivant » au clic. Les commandes `next`/`prev` (qui sautent les groupes vides)
  restent disponibles pour un bind éventuel.
- État : `~/.local/state/omarchy/wsgroup.state` (dernier ws par groupe).
- `omarchy-wsgroup refresh` est appelé à l'autostart (réapplique le filtre barre).

### Pièges

- **`wayle panel restart` peut time-out** (« Timeout waiting for panel to stop »)
  et laisser le panel arrêté → repartir sur `wayle panel start`.
- **Relancer un process de session depuis le shell de l'agent** (ex. `wayle panel
  restart`) l'héberge avec la `HYPRLAND_INSTANCE_SIGNATURE` périmée du shell →
  panel branché sur une instance morte. Toujours exporter la signature vivante.
- **Multi-écran** (corrigé le 2026-09-28) : `apply_workspace_layout` ne posait des
  `workspace_rule` que pour `1..12` ; les workspaces `13..60` n'avaient aucune
  assignation d'écran et atterrissaient sur l'écran au focus. `workspace_layout`
  décrit désormais la répartition en **slots** (`m2` : slots `1..10` → HDMI-A-2,
  `11..12` → eDP-1) et la déploie sur les 5 groupes (IDs `(g-1)*12+s`). `default`
  reste posé une seule fois par écran (slot 1 du groupe 1), comme avant. Vérifié
  au `hyprctl` (ws 13/14/25 → HDMI, ws 23/59 → eDP). Un workspace déjà ouvert sur
  le mauvais écran n'est pas rapatrié par la règle (elle ne vaut qu'à la
  création) : relancer l'alias `m2`/`m1` (ou `hyprctl eval 'apply_profile("m2")'`)
  déplace les ouverts.
- **hyprshell** : son window switcher est resté désactivé depuis l'essai hyprkool
  (`~/.config/hyprshell/config.ron`, `switch = None`), ce qui a libéré `Super+Tab`
  pour « cycle groupe ». À réactiver si on veut récupérer le switcher.
- **`nc` qui s'empile** : wayle ne tue pas le `nc` petit-fils du module `watch`
  quand il le relance — chaque restart en laisse un, reparenté à systemd
  (`ppid 1660`). Corrigé dans `pkgs/omarchy-wsgroup.sh` : chaque module lance son
  `nc` avec un argv marqué (`exec -a "wsgroup-nc-$N"`) et `indicator $N` fait
  `pkill -f "wsgroup-nc-$N"` au démarrage → il ne tue que l'instance de SON
  module, pas les 4 autres. Effectif (rebuild fait).
- **Modules `watch` résidents après rebuild** : chaque `custom-wsgN` lance un
  process long `omarchy-wsgroup indicator N` (il tient `nc -U` sur le socket) ;
  un `nixos-rebuild switch` remplace le binaire mais **ne relance pas** ces
  process, qui continuent d'exécuter l'ancien code en mémoire (ex. ancien
  `GROUP_COUNT`, ancien `emit_status`). Symptôme observé : la barre affichait
  encore 3 points sans filtre après le rebuild. Correctif immédiat, sans toucher
  à wayle : `pkill -f "omarchy-wsgroup indicator"` → wayle les respawn
  (`restart-policy = on-exit`) avec le script neuf. Sinon `wayle panel restart`.

### Ce qui est figé en nix, et ce qui ne l'est pas

**Déclaratif (fait le 2026-09-27).** Le script est packagé :
`~/repositories/piergst/nixos-config/pkgs/omarchy-wsgroup.{nix,sh}` (`writeShellScriptBin`, vendorisé
car il diverge de l'amont — dispatchs en Lua, filtre wayle), ajouté à
`home.packages`. Installé à `/etc/profiles/per-user/pierre/bin/omarchy-wsgroup`,
donc visible dans le **PATH de session** (celui des exec Hyprland et de wayle) —
plus de chemin absolu, plus de copie dans `~/.local/bin`. Les binds et le module
wayle pointent maintenant sur `omarchy-wsgroup` (nom du PATH) et non plus sur un
chemin absolu. Au passage, l'appel d'autostart `$HOME/.local/bin/omarchy-wsgroup
refresh` (chemin mort, le seed de login ne tournait donc jamais) a été corrigé en
`omarchy-wsgroup refresh`.

**Encore manuel.**
- `~/.config/hypr/hyprland.lua` — les binds. Ce fichier n'est pas déclaratif (la
  ligne `xdg.configFile."hypr/hyprland.conf"` est commentée dans `home.nix`).
  Le figer = embarquer `hyprland.lua` dans `~/repositories/piergst/nixos-config/dotfiles/` et le
  déclarer — c'est une étape de la migration Hyprland, pas propre à cette feature.
- Les fichiers wayle : `config.toml` (l'`imports`), `runtime.toml` (layout de la
  barre + 5 modules `custom-wsg1..5` + la `BarGroup` `wsgroups` +
  `show-special = false`), `styles/index.scss` (CSS scoped `#wsgroups`), et
  `wsgroup.toml` (généré à chaud par le script, à ne **pas** déclarer).

### Pourquoi wayle reste manuel (le blocage à trancher plus tard)

wayle a **deux couches** : `config.toml` (fait main) et `runtime.toml` (écrit par
la GUI et par `wayle config set`), et `runtime.toml` **l'emporte champ par champ**.

1. Déclarer `config.toml` → si la GUI wayle est utilisée, elle écrit dans
   `runtime.toml`, qui **écrase silencieusement** la valeur déclarée sur les
   champs touchés ; un rebuild ne rattrape rien (runtime.toml non géré).
2. Déclarer `runtime.toml` → c'est le fichier que la GUI écrit ; dans le store il
   est en lecture seule, donc l'édition graphique casse.

Détail en plus : `bar.layout` et `modules.custom` sont des **tableaux** TOML, et
le merge TOML **remplace les tableaux** au lieu de fusionner (« tables merge key
by key; scalars and arrays replace »). On ne peut donc pas les injecter via un
fichier importé — il faudrait posséder tout le layout et tout `modules.custom`.
C'est pourquoi `wsgroup.toml` ne contient que des **tables** (`workspace-ignore`,
`workspace-map`), qui, elles, fusionnent clé par clé.

**Options quand on s'y mettra :**
- (a) déplacer tout `runtime.toml` vers `config.toml`, déclarer `config.toml` dans
  Nix, et **renoncer à la GUI/au CLI wayle** (sinon divergence) → reproductible ;
- (b) garder le wayle manuel (statut quo).

À trancher selon si l'édition graphique de wayle est utilisée.
