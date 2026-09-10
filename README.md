# my_dotfiles

Configuration shell et éditeurs de cette machine (WSL2 / Ubuntu 22.04).

L'arborescence du repo **reflète celle de `$HOME`** : `.bashrc` ici correspond à
`~/.bashrc`. Le déploiement se fait par symlinks — éditer un fichier du repo
modifie directement la config active, et inversement.

## Installation

```bash
/mnt/z/dev_workspace/my_dotfiles/.local/bin/install-dotfiles
exec bash -l          # recharge le shell
```

Le script est idempotent : il installe `vim git ripgrep unzip` via apt, pose
**fzf** (version épinglée, cf. `FZF_VERSION`) dans `~/.local/share/fzf`, clone
les plugins vim dans `~/.vim/pack/dotfiles/start/`, pose **Neovim**, ses
serveurs LSP et ses outils dans `~/.local/opt/`, crée les symlinks vers `$HOME`
en sauvegardant tout fichier existant en `.bak`, puis installe les plugins
Neovim.

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
- **Neovim n'est pas pris sur apt** non plus : jammy fournit la 0.6, alors que
  la config repose sur `vim.pack`, le gestionnaire de plugins intégré depuis la
  0.12. `install-dotfiles` pose les archives officielles de Neovim, lazygit, fd,
  lua-language-server, clangd, jdtls, shellcheck, shfmt et d'un JDK 21 dans
  `~/.local/opt/<nom>-<version>` (versions et empreintes SHA-256 épinglées en
  tête du script), exposées dans `~/.local/bin`. Même logique que fzf : le
  paquet apt reste, masqué par le `PATH` ; dans un shell déjà ouvert, `hash -r`
  oublie l'ancien chemin.
- **jdtls a son propre JDK 21** : son lanceur refuse Java 17, la version d'apt.
  `~/.local/bin/jdtls` est un petit script généré qui lui passe ce JDK via
  `JAVA_HOME` ; le `java` du `PATH` et le `JAVA_HOME` du shell restent ceux des
  projets.
- **basedpyright passe par uv** (`uv tool install`) : environnement isolé qui
  embarque son node, donc indépendant de nvm — un pyright installé par
  `npm i -g` n'est visible que sous la version de Node qui l'a installé.
- **bash-language-server et typescript-language-server passent par npm**, chacun
  dans son dossier `~/.local/opt/<nom>-<version>` plutôt qu'en `npm i -g` : ils
  survivent à un `nvm use`, mais demandent un `node` ≥ 20 dans le `PATH` pour
  démarrer (celui de nvm, chargé par `.bashrc`). Versions choisies pour le
  Node 20 de nvm : typescript-language-server 5.x (la 6.x exige Node 22), avec
  TypeScript 6.x, que ts_ls sait piloter contrairement à la 7 (réécriture native).
- **tree-sitter est compilé** (`cargo install`) : ses binaires officiels
  exigent glibc 2.39, jammy n'a que 2.35. Sa feature par défaut `qjs-rt` est
  désactivée, car son bindgen réclame `libclang`, qui ne s'installe qu'avec sudo.
- **fd est posé par le script** (build musl statique, sans dépendance à la
  glibc) : la recherche dans l'explorateur Snacks en a besoin. Ne pas prendre le
  paquet apt `fd-find` : il installe le binaire sous le nom `fdfind`, sur lequel
  l'alias `fd` ne se déclenche pas.
- **eza est optionnel**, donc non installé par le script : jammy ne le package
  pas (seulement `exa`, abandonné). Le poser via `cargo install eza`.

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

| Plugin | Rôle |
| --- | --- |
| catppuccin | Thème (variante mocha par défaut). |
| lualine.nvim | Barre d'état (remplace l'affichage du mode). |
| snacks.nvim | Pickers (fichiers, grep, buffers, diagnostics, symboles), explorateur, fenêtre lazygit. |
| nvim-lspconfig | Configs par défaut des serveurs LSP, activés par `vim.lsp.enable`. |
| nvim-treesitter | Installe les parsers (`:TSInstall`), qui colorent notamment le code dans la doc LSP. |
| tiny-inline-diagnostic.nvim | Diagnostics lisibles en ligne, sur plusieurs lignes. |
| nvim-autopairs | Ferme guillemets, parenthèses et accolades. |
| blink.cmp (+ blink.lib) | Autocomplétion : LSP, chemins, snippets, mots du buffer. |
| friendly-snippets | Snippets par langage (Java, C/C++, Python, Rust, JS/TS…), proposés par blink.cmp. |
| leap.nvim | Sauts à l'écran en deux caractères. |
| render-markdown.nvim | Met en forme le Markdown dans Neovim (titres, listes, tableaux, code) ; aperçu dans un onglet avec `Espace mp`. |

### Raccourcis

Leader : `Espace`. Les recherches dans le contenu passent par ripgrep, avec les
réglages de l'alias `rg` et du `:Rg` de vim : fichiers cachés inclus,
`.gitignore` respecté, `.git` exclu.

| Touche | Effet |
| --- | --- |
| `Espace ff` / `fg` / `fb` | fichiers par nom / recherche ripgrep dans le contenu / buffers ouverts |
| `Ctrl-T` dans un picker | ouvre le fichier choisi dans un nouvel onglet |
| `gt` / `gT` | onglet suivant / précédent (`:tabclose` ferme l'onglet courant) |
| `Espace mp` (Markdown) | aperçu mis en forme dans un nouvel onglet, synchronisé avec le fichier ; relancé depuis le fichier ou l'aperçu, le ferme |
| `:grep motif` | recherche ripgrep, résultats dans la quickfix list (`:copen`, `:cnext`) |
| `Espace fe` | explorateur, fichiers cachés visibles et `.git` exclu (`a` créer — finir par `/` pour un dossier, `r` renommer, `d` supprimer, `H` masquer/afficher les fichiers cachés, `I` ceux ignorés par git) |
| `Espace fd` | diagnostics |
| `Espace fs` / `fS` | symboles LSP du buffer / du projet |
| `Espace fm` | formater le buffer (LSP) |
| `gd` / `gr` | définition / références |
| `K` | doc LSP de l'élément sous le curseur (défaut Neovim) |
| `grn` / `gra` | renommer / actions de code (défauts Neovim) |
| `s` + 2 lettres | Leap : saut dans la fenêtre (taper ensuite la lettre affichée s'il y a plusieurs cibles) ; `S` vise les autres fenêtres |
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
  depuis le dossier de build ; Make : `bear -- make`). Sans lui, il utilise des
  options par défaut : suffisant pour un fichier isolé, pas pour les chemins
  d'include d'un projet.
- **jdtls** prend pour racine le dossier du `pom.xml` / `build.gradle` (à
  défaut le `.git`) et importe le projet à la première ouverture : quelques
  secondes avant que doc, renommage, formatage et erreurs de type soient
  disponibles. Un `.java` hors projet n'a droit qu'aux erreurs de syntaxe.
  Cache dans `~/.cache/nvim/jdtls/`.
- **basedpyright** tourne en `typeCheckingMode = "standard"`, le niveau de
  pyright, plutôt qu'en « recommended », très bavard. Il ne formate pas :
  `Espace fm` est sans effet sur du Python. Pour qu'il voie les dépendances d'un
  venv : l'activer avant de lancer nvim, ou
  `:LspPyrightSetPythonPath .venv/bin/python`.
- **ts_ls** utilise le TypeScript du projet (`node_modules/typescript`) s'il
  existe, sinon le sien. Pour React, les types JSX (balises, props) viennent de
  `@types/react` dans le `node_modules` du projet.
- **bashls** délègue les diagnostics à shellcheck et le formatage à shfmt.
  `.sh`, `.bash` et `.bashrc` sont reconnus en filetype `sh`, couvert par le
  serveur.

Les autres serveurs de la vidéo ne sont pas installés. Un serveur absent ne
démarre pas, mais pas toujours en silence :

- `emmet_ls`, `jinja_lsp`, `nushell`, `svelte` : rien à l'écran, une ligne
  `invalid "…" config` dans `~/.local/state/nvim/lsp.log` ;
- `html` : message d'erreur *Spawning language server … failed* à chaque
  ouverture d'un `.html`. Sa commande est une fonction dans nvim-lspconfig, que
  Neovim ne peut pas vérifier avant de la lancer.

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

- Le repo vit sur `/mnt/z`, un montage Windows. Si le lecteur n'est pas monté,
  les symlinks pointent dans le vide et bash comme Neovim démarrent sans
  config : remonter le lecteur, ou repartir d'un `~/.bashrc.bak`.
- `install-dotfiles` sauvegarde en `.bak` **une seule fois** : un second
  lancement sur un `$HOME` déjà symlinké ne réécrase pas la sauvegarde.
- Au premier lancement de Neovim, blink.cmp compile sa lib Rust
  (`cargo build --release`, une vingtaine de secondes ici) et l'éditeur paraît
  figé pendant ce temps. `install-dotfiles` s'en charge en amont.
- Dans `init.lua` lui-même, lua_ls signale *Undefined global `vim`* et
  *`Snacks`* : il ne connaît pas l'API de Neovim. Sans conséquence, déjà le cas
  dans la vidéo.
- `gr` (références) est aussi le préfixe des raccourcis LSP par défaut de
  Neovim (`grn`, `gra`, `grr`…) : Neovim attend `timeoutlen` (1 s) avant de le
  déclencher. Repris tel quel de la config d'origine.
- Les icônes (lualine, diagnostics, pickers, titres Markdown) sont des glyphes Nerd Font : sans
  police Nerd Font dans le terminal Windows, elles s'affichent en carrés.
- Recharger la config avec `:source` affiche un avertissement « already setup »
  de snacks.nvim, sans conséquence. Plusieurs plugins demandent de toute façon
  un redémarrage (`:restart`).
