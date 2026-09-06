# my_dotfiles

Configuration shell et éditeur de cette machine (WSL2 / Ubuntu 22.04).

L'arborescence du repo **reflète celle de `$HOME`** : `.bashrc` ici correspond à
`~/.bashrc`. Le déploiement se fait par symlinks — éditer un fichier du repo
modifie directement la config active, et inversement.

## Installation

```bash
/mnt/z/dev_workspace/my_dotfiles/.local/bin/install-dotfiles
exec bash -l          # recharge le shell
```

Le script est idempotent : il installe `vim git ripgrep` via apt, pose **fzf**
(version épinglée, cf. `FZF_VERSION`) dans `~/.local/share/fzf`, clone les
plugins vim dans `~/.vim/pack/dotfiles/start/`, puis crée les symlinks vers
`$HOME` en sauvegardant tout fichier existant en `.bak`.

## Contenu

| Fichier | Rôle |
| --- | --- |
| `.profile` | Env exporté : XDG, `PATH`, historique, options fzf. Chargé au login. |
| `.bash_profile` | Symlink vers `.profile` — bash le lit en priorité s'il existe. |
| `.bashrc` | Shells interactifs : `shopt`, alias, fzf, prompt git, nvm. |
| `.vimrc` | Config vim + commande `:Rg`. |
| `.local/bin/install-dotfiles` | Bootstrap idempotent (outils, plugins, symlinks). |

**Règle de répartition** : ce qui est *exporté*, donc hérité par tous les
sous-shells (`PATH`, `EDITOR`, `HISTSIZE`, `FZF_DEFAULT_OPTS`…) va dans
`.profile` — défini une fois au login. Ce qu'un sous-shell **n'hérite pas** et
qu'il faut redéfinir à chaque ouverture (`shopt`, alias, fonctions `nvm` /
widgets fzf / `__git_ps1`, `PS1`) va dans `.bashrc`. `.profile` se termine en
sourçant `.bashrc` pour les shells bash interactifs.

`PATH` est construit par le helper `_path_prepend`, qui n'ajoute un répertoire
que s'il existe et n'y est pas déjà : relire `.profile` (re-login, `su -`)
n'empile pas de doublons. `~/.local/bin` est ajouté **en dernier**, donc placé
en tête du `PATH` — c'est ce qui fait gagner le fzf récent contre celui d'apt.

## Outils

Tous sont des réécritures modernes (Rust/Go) des utilitaires POSIX classiques.
Le gain commun : valeurs par défaut sensées (récursif, coloré, respecte
`.gitignore`) là où les originaux demandent d'empiler des flags.

| Outil | Remplace | Apport |
| --- | --- | --- |
| **ripgrep** (`rg`) | `grep -r` | Récursif par défaut, respecte `.gitignore`, saute les binaires, multi-thread — typiquement 5–10× plus rapide sur un gros arbre. Sortie groupée par fichier et colorée. Alias `rg --hidden` pour voir aussi les dotfiles. |
| **fzf** | `Ctrl-R` natif, `find \| grep` | Filtre flou **interactif** : on tape des bouts de mots dans le désordre et on navigue une liste avec preview. Le reverse-search bash ne cherche qu'une sous-chaîne exacte, une occurrence à la fois, sans liste. Sert de sélecteur générique (historique, fichiers, `cd`, complétion). |
| **eza** | `ls` | Successeur maintenu de `exa`. Couleurs par type et extension sans avoir à gérer `dircolors`/`LS_COLORS`, colonne d'état git (`--git`), arbre intégré (`--tree`, remplace `tree`), `--git-ignore`, en-têtes de colonnes. Sortie lisible sans empiler cinq flags. |
| **fd** | `find` | `fd motif` au lieu de `find . -iname '*motif*'` : regex par défaut, respecte `.gitignore`, parallèle, coloré. Alias `fd -HI` pour inclure cachés et ignorés. |

Alias posés seulement si le binaire existe (`ll`/`la`/`lla` retombent sur `ls`,
`fd` n'est pas aliasé) : les dotfiles restent utilisables sur une machine nue.

### Notes d'installation

- **fzf n'est pas pris sur apt** : le paquet Ubuntu est figé sur 0.29 (2021),
  sans `fzf --bash` (l'intégration shell auto-générée) et trop ancien pour le
  `fzf.vim` actuel, qui utilise des options récentes comme `--footer`.
  `install-dotfiles` pose donc le binaire officiel dans `~/.local/share/fzf`.
  Le paquet apt peut rester, il est masqué par le `PATH`. `.bashrc` gère les
  deux cas : `fzf --bash` s'il est disponible, sinon les fichiers
  `key-bindings.bash` / `completion.bash` (chemins Arch **et** Debian).
- **eza et fd sont optionnels**, donc non installés par le script : jammy ne
  package pas `eza` (seulement `exa`, abandonné). Les poser via
  `cargo install eza fd-find`. Attention : le paquet apt `fd-find` installe le
  binaire sous le nom `fdfind`, sur lequel l'alias `fd` ne se déclenche pas.

## fzf dans bash

| Touche | Effet |
| --- | --- |
| `Ctrl-R` | recherche floue dans l'historique ; `Ctrl-/` affiche la commande entière en preview |
| `Ctrl-T` | insère un chemin de fichier dans la ligne de commande |
| `Alt-C` | `cd` dans un sous-répertoire |
| `**` + `Tab` | complétion floue de chemins (`vim **<TAB>`) |

Le listage passe par ripgrep (`FZF_DEFAULT_COMMAND`) : `.gitignore` respecté,
fichiers cachés visibles, `.git` sauté. L'historique est illimité (`HISTSIZE` /
`HISTFILESIZE` vides), donc `Ctrl-R` voit toutes les commandes déjà tapées.

## vim

Plugins en *packages natifs* vim 8 (`~/.vim/pack/dotfiles/start/`) : vim les
charge seul au démarrage, aucun gestionnaire de plugins à installer.

- **fzf** — symlink vers `~/.local/share/fzf`, fournit `fzf#run` / `fzf#wrap` ;
- **fzf.vim** — [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim), fournit
  `:Rg`, `:Files` et les previews.

Ils sont clonés par `install-dotfiles` et **pas archivés** ici (`.gitignore`),
pour ne pas versionner du code tiers.

### `:Rg` — recherche plein texte

```vim
:Rg motif     " cherche « motif » dans le CONTENU des fichiers
:Rg           " liste tout, on affine ensuite au clavier dans fzf
:Rg! motif    " idem, en plein écran
```

ripgrep fait la recherche, fzf filtre les résultats de façon interactive.

| Touche | Effet |
| --- | --- |
| `Entrée` | ouvre le fichier **dans la fenêtre courante**, sur la ligne du match |
| `Ctrl-T` / `Ctrl-X` / `Ctrl-V` | onglet / split horizontal / split vertical |
| `Tab` | sélectionne plusieurs résultats → quickfix list (`:copen`) |
| `Ctrl-/` | affiche/masque la preview |

La commande est redéfinie dans `.vimrc` plutôt que reprise de fzf.vim, pour
ajouter `--hidden` (cohérent avec l'alias `rg`) en excluant `.git`. fzf.vim ne
déclare ses commandes que si elles n'existent pas déjà, et `.vimrc` est chargé
avant les packages : notre version gagne. `:Files` (recherche par nom) reste
fourni par fzf.vim.

## Config spécifique à une machine

`~/.profile.local` (variables d'env) et `~/.bashrc.local` (alias, fonctions)
sont sourcés automatiquement s'ils existent et ne sont pas trackés. C'est
l'endroit pour ce qui ne doit pas partir dans le repo : chemins d'un client,
secrets, réglages d'une seule machine.

## Points d'attention

- Le repo vit sur `/mnt/z`, un montage Windows. Si le lecteur n'est pas monté,
  les symlinks pointent dans le vide et bash démarre sans config : remonter le
  lecteur, ou repartir d'un `~/.bashrc.bak`.
- `install-dotfiles` sauvegarde en `.bak` **une seule fois** : un second
  lancement sur un `$HOME` déjà symlinké ne réécrase pas la sauvegarde.
