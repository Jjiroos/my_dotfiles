# my_dotfiles

Mes fichiers de configuration shell et éditeurs, archivés et distribuables sur
n'importe quelle distribution Linux.

L'arborescence du repo **reflète celle de `$HOME`** : `.bashrc` ici correspond à
`~/.bashrc`. Le déploiement se fait par symlinks — éditer un fichier du repo
modifie directement la config active, et inversement.

## Installation

```bash
./.local/bin/install-dotfiles
exec bash -l          # recharge le shell
```

Le script est idempotent : il installe les outils de base via le gestionnaire
de paquets, pose fzf, Neovim, ses serveurs LSP et ses outils dans
`~/.local/opt/`, clone les plugins vim, crée les symlinks vers `$HOME` en
sauvegardant tout fichier existant en `.bak`, puis installe les plugins Neovim.

## Contenu

| Fichier | Rôle |
| --- | --- |
| `.profile` | Env exporté : XDG, `PATH`, historique, options fzf. Chargé au login. |
| `.bash_profile` | Symlink vers `.profile` — bash le lit en priorité s'il existe. |
| `.bashrc` | Shells interactifs : `shopt`, alias, fzf, prompt git, nvm. |
| `.vimrc` | Config vim + commande `:Rg`. |
| `.config/nvim/init.lua` | Config Neovim : plugins, LSP, raccourcis. |
| `.config/nvim/nvim-pack-lock.json` | Révisions exactes des plugins Neovim, tenu à jour par `vim.pack`. |
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
en tête du `PATH` — c'est ce qui fait gagner les binaires posés par le script
contre ceux du gestionnaire de paquets.

## Outils

Réécritures modernes (Rust/Go) des utilitaires POSIX classiques, avec des
valeurs par défaut sensées (récursif, coloré, respecte `.gitignore`).

| Outil | Remplace | Doc |
| --- | --- | --- |
| **ripgrep** (`rg`) | `grep -r` | [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **fzf** | `Ctrl-R` natif, `find \| grep` | [junegunn/fzf](https://github.com/junegunn/fzf) |
| **eza** | `ls` | [eza-community/eza](https://github.com/eza-community/eza) |
| **fd** | `find` | [sharkdp/fd](https://github.com/sharkdp/fd) |

Alias posés seulement si le binaire existe (`ll`/`la`/`lla` retombent sur `ls`) :
les dotfiles restent utilisables sur une machine nue. Alias `rg --hidden` et
`fd -HI` pour inclure les fichiers cachés.

### Notes d'installation

Plusieurs outils sont posés par `install-dotfiles` plutôt que par le
gestionnaire de paquets, dont les versions sont souvent trop anciennes :

- **fzf** : le binaire officiel est posé dans `~/.local/share/fzf` (intégration
  shell `fzf --bash`, options récentes requises par `fzf.vim`). `.bashrc` gère
  les deux cas : `fzf --bash` si disponible, sinon les fichiers
  `key-bindings.bash` / `completion.bash`.
- **Neovim** et ses outils (lazygit, fd, serveurs LSP, JDK 21…) : archives
  officielles dans `~/.local/opt/<nom>-<version>` (versions et empreintes
  SHA-256 épinglées en tête du script), exposées dans `~/.local/bin`.
- **jdtls** embarque son propre JDK 21 (son lanceur refuse Java 17) via un
  script `~/.local/bin/jdtls` ; le `java` et le `JAVA_HOME` du shell restent
  ceux des projets.
- **basedpyright** via `uv tool install` (environnement isolé, indépendant de
  nvm).
- **bash-language-server** et **typescript-language-server** via npm dans
  `~/.local/opt/` (survivent à un `nvm use`), demandent un `node` ≥ 20 dans le
  `PATH`. Versions choisies pour Node 20 : ts-language-server 5.x + TypeScript 6.x.
- **fd** : build musl statique (la recherche de l'explorateur Snacks en a
  besoin) ; ne pas prendre le paquet `fd-find`, qui installe le binaire sous le
  nom `fdfind`.
- **eza** est optionnel et non installé par le script (`cargo install eza`).

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

## Neovim

Config en un seul fichier, reprise de la vidéo
[« La config Neovim PARFAITE en partant de ZÉRO »](https://www.youtube.com/watch?v=-zSpBsiTy20)
(Loïc Rust — [config d'origine](https://github.com/darikoko/neovim-config)).
Requiert Neovim ≥ 0.12. Ajouts à la config d'origine : friendly-snippets, les
serveurs basedpyright (Python), jdtls (Java) et bashls (bash), et
render-markdown avec son aperçu dans un onglet.

L'alias `vi` de `.bashrc` lance `nvim` ; le repasser à `"vim"` pour revenir à
vim. `vim` lui-même et `EDITOR` (`.profile`) restent sur vim.

Les plugins sont gérés par `vim.pack` et clonés dans
`~/.local/share/nvim/site/pack/core/opt/` : comme pour vim, le code tiers n'est
**pas archivé**, mais ses révisions sont figées dans `nvim-pack-lock.json`,
versionné. Une machine neuve installe exactement les mêmes commits.

| Plugin | Rôle | Doc |
| --- | --- | --- |
| catppuccin | Thème (variante mocha par défaut). | [catppuccin/nvim](https://github.com/catppuccin/nvim) |
| lualine.nvim | Barre d'état. | [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) |
| snacks.nvim | Pickers, explorateur, fenêtre lazygit. | [folke/snacks.nvim](https://github.com/folke/snacks.nvim) |
| nvim-lspconfig | Configs par défaut des serveurs LSP. | [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) |
| nvim-treesitter | Installe les parsers (`:TSInstall`). | [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) |
| tiny-inline-diagnostic.nvim | Diagnostics lisibles en ligne. | [rachartier/tiny-inline-diagnostic.nvim](https://github.com/rachartier/tiny-inline-diagnostic.nvim) |
| nvim-autopairs | Ferme guillemets, parenthèses et accolades. | [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) |
| blink.cmp | Autocomplétion (LSP, chemins, snippets, buffer). | [saghen/blink.cmp](https://github.com/saghen/blink.cmp) |
| friendly-snippets | Snippets par langage, proposés par blink.cmp. | [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) |
| leap.nvim | Sauts à l'écran en deux caractères. | [ggandor/leap.nvim](https://github.com/ggandor/leap.nvim) |
| render-markdown.nvim | Met en forme le Markdown ; aperçu avec `Espace mp`. | [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) |

### Raccourcis

Leader : `Espace`. Les recherches dans le contenu passent par ripgrep, avec les
réglages de l'alias `rg` et du `:Rg` de vim : fichiers cachés inclus,
`.gitignore` respecté, `.git` exclu.

| Touche | Effet |
| --- | --- |
| `Espace ff` / `fg` / `fb` | fichiers par nom / recherche ripgrep dans le contenu / buffers ouverts |
| `Ctrl-T` dans un picker | ouvre le fichier choisi dans un nouvel onglet |
| `gt` / `gT` | onglet suivant / précédent (`:tabclose` ferme l'onglet courant) |
| `Espace mp` (Markdown) | aperçu mis en forme dans un nouvel onglet, synchronisé avec le fichier ; relancé, le ferme |
| `:grep motif` | recherche ripgrep, résultats dans la quickfix list (`:copen`, `:cnext`) |
| `Espace fe` | explorateur, fichiers cachés visibles et `.git` exclu (`a` créer — finir par `/` pour un dossier, `r` renommer, `d` supprimer, `H` masquer/afficher les cachés, `I` ceux ignorés par git) |
| `Espace fd` | diagnostics |
| `Espace fs` / `fS` | symboles LSP du buffer / du projet |
| `Espace fm` | formater le buffer (LSP) |
| `gd` / `gr` | définition / références |
| `K` | doc LSP de l'élément sous le curseur (défaut Neovim) |
| `grn` / `gra` | renommer / actions de code (défauts Neovim) |
| `s` + 2 lettres | Leap : saut dans la fenêtre ; `S` vise les autres fenêtres |
| `Tab` / `Shift-Tab` / `Entrée` / `Échap` | complétion : suivant / précédent / accepter / fermer |
| `Espace lg` | lazygit |

### Serveurs LSP et parsers

L'autocomplétion vient des serveurs LSP : blink.cmp affiche leurs suggestions,
complétées par les snippets de friendly-snippets. `init.lua` active les serveurs
de la vidéo plus `basedpyright`, `jdtls` et `bashls`, mais Neovim n'en installe
aucun. `install-dotfiles` pose ceux-ci :

| Langage | Serveur | Installé via |
| --- | --- | --- |
| Rust | `rust_analyzer` | composant rustup |
| C, C++ | `clangd` | release LLVM, `~/.local/opt` |
| Python | `basedpyright` | `uv tool install` |
| Java | `jdtls` | milestone Eclipse + JDK 21 Temurin, `~/.local/opt` |
| JavaScript, TypeScript, React (`.js` `.jsx` `.ts` `.tsx`) | `ts_ls` | npm, `~/.local/opt` |
| Bash, sh | `bashls` (+ shellcheck, shfmt) | npm + releases, `~/.local/opt` |
| Lua | `lua_ls` | release LuaLS, `~/.local/opt` |

- **clangd** lit les options de compilation dans un `compile_commands.json` à
  la racine du projet (CMake : `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` puis symlink
  depuis le dossier de build ; Make : `bear -- make`). Sans lui, options par
  défaut : suffisant pour un fichier isolé, pas pour les include d'un projet.
- **jdtls** prend pour racine le dossier du `pom.xml` / `build.gradle` (à
  défaut le `.git`) et importe le projet à la première ouverture. Un `.java`
  hors projet n'a droit qu'aux erreurs de syntaxe. Cache dans
  `~/.cache/nvim/jdtls/`.
- **basedpyright** tourne en `typeCheckingMode = "standard"`. Il ne formate pas.
  Pour qu'il voie les dépendances d'un venv : l'activer avant nvim, ou
  `:LspPyrightSetPythonPath .venv/bin/python`.
- **ts_ls** utilise le TypeScript du projet (`node_modules/typescript`) s'il
  existe. Pour React, les types JSX viennent de `@types/react` du projet.
- **bashls** délègue les diagnostics à shellcheck et le formatage à shfmt.
  `.sh`, `.bash` et `.bashrc` sont reconnus en filetype `sh`.

Les autres serveurs de la vidéo ne sont pas installés. Un serveur absent ne
démarre pas, mais pas toujours en silence :

- `emmet_ls`, `jinja_lsp`, `nushell`, `svelte` : rien à l'écran, une ligne
  `invalid "…" config` dans `~/.local/state/nvim/lsp.log` ;
- `html` : message d'erreur *Spawning language server … failed* à chaque
  ouverture d'un `.html`.

Pour en ajouter un : l'installer, puis reprendre son nom dans la
[liste de nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md),
qui diffère souvent du binaire (`rust_analyzer` pour `rust-analyzer`). Pour
s'en passer : le retirer de `vim.lsp.enable`.

Les parsers treesitter se posent à la demande (`:TSInstall go`) et ne sont pas
versionnés ; le script installe ceux de Rust, C, C++, Java, Python, bash,
JavaScript, TypeScript et TSX (liste `TS_PARSERS`). Après une mise à jour de
nvim-treesitter, lancer `:TSUpdate`.

### Mettre à jour les plugins

`:lua vim.pack.update()` ouvre la liste des changements, `:write` les applique.
Commiter ensuite `nvim-pack-lock.json`. Pour revenir en arrière :
`git checkout -- .config/nvim/nvim-pack-lock.json`, puis
`:lua vim.pack.update(nil, { target = 'lockfile' })`.

## Config spécifique à une machine

`~/.profile.local` (variables d'env) et `~/.bashrc.local` (alias, fonctions)
sont sourcés automatiquement s'ils existent et ne sont pas trackés. C'est
l'endroit pour ce qui ne doit pas partir dans le repo : chemins d'un client,
secrets, réglages d'une seule machine.

## Points d'attention

- `install-dotfiles` sauvegarde en `.bak` **une seule fois** : un second
  lancement sur un `$HOME` déjà symlinké ne réécrase pas la sauvegarde.
- Au premier lancement de Neovim, blink.cmp compile sa lib Rust
  (`cargo build --release`) et l'éditeur paraît figé pendant ce temps.
  `install-dotfiles` s'en charge en amont.
- Dans `init.lua`, lua_ls signale *Undefined global `vim`* et *`Snacks`* : il ne
  connaît pas l'API de Neovim. Sans conséquence.
- `gr` (références) est aussi le préfixe des raccourcis LSP par défaut de Neovim
  (`grn`, `gra`, `grr`…) : Neovim attend `timeoutlen` (1 s) avant de le
  déclencher.
- Les icônes (lualine, diagnostics, pickers, titres Markdown) sont des glyphes
  Nerd Font : sans police Nerd Font dans le terminal, elles s'affichent en
  carrés.
- Recharger la config avec `:source` affiche un avertissement « already setup »
  de snacks.nvim, sans conséquence. Plusieurs plugins demandent de toute façon
  un redémarrage (`:restart`).