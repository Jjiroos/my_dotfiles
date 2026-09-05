# my_dotfiles

Configuration shell et éditeur de cette machine (WSL2 / Debian).

L'arborescence du repo **reflète celle de `$HOME`** : `.bashrc` ici correspond
à `~/.bashrc`, `.local/bin/install-dotfiles` à `~/.local/bin/install-dotfiles`.
Le déploiement se fait par symlinks, donc éditer un fichier du repo modifie
directement la config active — et inversement.

## Installation

```bash
/mnt/z/dev_workspace/my_dotfiles/.local/bin/install-dotfiles
exec bash -l          # recharge le shell
```

Le script est idempotent. Il :

1. installe `vim`, `git`, `ripgrep` via apt s'ils manquent ;
2. installe **fzf** (version épinglée, cf. `FZF_VERSION`) dans
   `~/.local/share/fzf`, exposé par `~/.local/bin/fzf` ;
3. installe les plugins vim dans `~/.vim/pack/dotfiles/start/` ;
4. crée les symlinks vers `$HOME`, en sauvegardant tout fichier existant
   en `.bak`.

## Contenu

| Fichier | Rôle |
| --- | --- |
| `.profile` | Variables d'environnement : XDG, `PATH`, historique, options fzf. Chargé au login. |
| `.bash_profile` | Symlink vers `.profile` — bash lit `.bash_profile` en priorité s'il existe. |
| `.bashrc` | Shells interactifs : options `shopt`, alias, intégration fzf, prompt git, nvm. |
| `.vimrc` | Config vim + commande `:Rg`. |
| `.local/bin/install-dotfiles` | Bootstrap idempotent (outils, plugins, symlinks). |

### Répartition `.profile` / `.bashrc`

La règle est celle du contenu, pas celle du moment de chargement :

- **`.profile`** contient ce qui est **exporté**, donc hérité par tous les
  sous-shells : `PATH`, `EDITOR`, `HISTSIZE`, `FZF_DEFAULT_OPTS`…
  Défini une fois au login, ça suffit.
- **`.bashrc`** contient ce qu'un sous-shell **n'hérite pas** et qu'il faut
  redéfinir à chaque ouverture : options `shopt`, alias, fonctions shell
  (`nvm`, les widgets fzf, `__git_ps1`) et `PS1`.

`.profile` se termine en sourçant `.bashrc` pour les shells bash interactifs,
si bien qu'un shell de login obtient l'ensemble.

`PATH` est construit avec un helper `_path_prepend` qui n'ajoute un répertoire
que s'il existe et n'y est pas déjà : relire `.profile` (re-login, `su -`)
n'empile pas de doublons. `~/.local/bin` est ajouté **en dernier**, donc placé
en tête du `PATH` : c'est ce qui fait gagner le fzf récent contre le
`/usr/bin/fzf` d'apt.

## fzf dans bash

`Ctrl-R` ouvre l'historique dans fzf au lieu du reverse-search natif.

| Touche | Effet |
| --- | --- |
| `Ctrl-R` | recherche floue dans l'historique ; `Ctrl-/` affiche la commande entière en preview |
| `Ctrl-T` | insère un chemin de fichier dans la ligne de commande |
| `Alt-C` | `cd` dans un sous-répertoire |
| `**` + `Tab` | complétion floue de chemins (`vim **<TAB>`) |

Le listage de fichiers passe par ripgrep (`FZF_DEFAULT_COMMAND`) : il respecte
`.gitignore`, voit les fichiers cachés et saute `.git`.

L'historique est illimité (`HISTSIZE` / `HISTFILESIZE` vides), ce qui donne à
`Ctrl-R` la totalité des commandes déjà tapées.

### Pourquoi fzf n'est pas installé via apt

Le paquet Debian est figé sur fzf **0.29** (2021). Deux conséquences : pas de
`fzf --bash` (l'intégration shell auto-générée), et une version trop ancienne
pour le `fzf.vim` actuel, qui utilise des options récentes comme `--footer`.
`install-dotfiles` pose donc le binaire officiel dans `~/.local/share/fzf`.
Le paquet apt peut rester installé, il est simplement masqué par le `PATH`.

`.bashrc` gère les deux cas : `fzf --bash` s'il est disponible, sinon les
fichiers `key-bindings.bash` / `completion.bash` de l'install locale ou du
paquet système (chemins Arch **et** Debian).

## vim

Plugins en *packages natifs* vim 8, dans `~/.vim/pack/dotfiles/start/` :

- **fzf** — symlink vers `~/.local/share/fzf`, fournit `fzf#run` / `fzf#wrap` ;
- **fzf.vim** — [junegunn/fzf.vim](https://github.com/junegunn/fzf.vim), fournit
  `:Rg`, `:Files`, les previews.

Ils sont clonés par `install-dotfiles` et **pas archivés** dans ce repo
(`.gitignore`), pour ne pas versionner du code tiers.

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
| `Ctrl-T` | ouvre dans un nouvel onglet |
| `Ctrl-X` | ouvre dans un split horizontal |
| `Ctrl-V` | ouvre dans un split vertical |
| `Tab` | sélectionne plusieurs résultats → quickfix list (`:copen`) |
| `Ctrl-/` | affiche/masque la preview |

La commande est redéfinie dans `.vimrc` plutôt que reprise telle quelle de
fzf.vim, pour ajouter `--hidden` (cohérent avec l'alias `rg` du shell) en
excluant `.git`. fzf.vim ne déclare ses commandes que si elles n'existent pas
déjà : `.vimrc` étant chargé avant les packages, notre version gagne.

`:Files` (recherche par nom de fichier) reste disponible, fourni par fzf.vim.

## Config spécifique à une machine

Deux fichiers non trackés sont sourcés automatiquement s'ils existent :

- `~/.profile.local` — variables d'env propres à la machine ;
- `~/.bashrc.local` — alias et fonctions propres à la machine.

C'est l'endroit où mettre ce qui ne doit pas partir dans le repo (chemins
d'un client, secrets, réglages d'une seule machine).

## Points d'attention

- Le repo vit sur `/mnt/z`, un montage Windows. Si le lecteur n'est pas monté,
  les symlinks pointent dans le vide et bash démarre sans config. Le cas
  échéant : remonter le lecteur, ou repartir d'un `~/.bashrc.bak`.
- `install-dotfiles` sauvegarde en `.bak` **une seule fois** : un second
  lancement sur un `$HOME` déjà symlinké ne réécrase pas la sauvegarde.
- Les alias `ll` / `la` / `lla` utilisent `eza` s'il est installé, sinon `ls`.
  De même, l'alias `fd` n'est posé que si `fd` existe.
