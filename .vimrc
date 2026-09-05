" ~/.vimrc — configuration vim
"
" Déployé en symlink par ~/.local/bin/install-dotfiles.
" Les plugins sont des « packages natifs » vim 8, dans ~/.vim/pack/dotfiles/start/ :
"   fzf     → symlink vers ~/.local/share/fzf (plugin de base : fzf#run, fzf#wrap)
"   fzf.vim → clone de junegunn/fzf.vim (commandes :Rg, :Files, previews)
" Ces deux plugins sont installés/mis à jour par install-dotfiles, pas trackés ici.

set nocompatible
filetype plugin indent on
syntax on

" ── Réglages de base ────────────────────────────────────────────────────
set encoding=utf-8
set number                  " numéros de ligne
set hidden                  " changer de buffer sans devoir sauver
set incsearch               " recherche incrémentale
set hlsearch                " surligne les occurrences
set ignorecase smartcase    " insensible à la casse, sauf si on tape une majuscule
set laststatus=2            " barre de statut toujours visible
set backspace=indent,eol,start
set mouse=a

" ── fzf ─────────────────────────────────────────────────────────────────
" Filet de sécurité : si le symlink du package est absent (dotfiles déployés
" sans avoir lancé install-dotfiles), on ajoute le plugin au runtimepath.
if !isdirectory(expand('~/.vim/pack/dotfiles/start/fzf'))
  set runtimepath+=~/.local/share/fzf
endif

" Ce que déclenche chaque touche sur le résultat sélectionné.
" Entrée n'apparaît pas ici : c'est le comportement par défaut de fzf.vim,
" `:edit` DANS LA FENÊTRE COURANTE — exactement ce qu'on veut.
let g:fzf_action = {
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'split',
      \ 'ctrl-v': 'vsplit' }

" Fenêtre fzf en popup centrée plutôt qu'un split en bas.
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.85 } }

" ── :Rg — recherche plein texte avec ripgrep ────────────────────────────
"   :Rg motif    cherche « motif » dans le CONTENU des fichiers
"   :Rg          liste tous les matchs, on affine ensuite au clavier dans fzf
"   :Rg! motif   idem, en plein écran
"
" Entrée ouvre le fichier DANS LA FENÊTRE COURANTE, sur la ligne du match.
" Ctrl-T / Ctrl-X / Ctrl-V → onglet / split horizontal / split vertical.
" Tab sélectionne plusieurs résultats : ils partent alors en quickfix (:copen).
" Ctrl-/ bascule la fenêtre de preview.
"
" On redéfinit la commande fournie par fzf.vim pour ajouter --hidden, cohérent
" avec l'alias `rg` du shell, tout en excluant .git. Le glob s'écrit "!.git"
" (non ancré) et non "!.git/*" : la forme ancrée ne matche que si rg travaille
" en chemins relatifs. fzf.vim ne déclare ses commandes que si elles n'existent
" pas déjà ; ce fichier étant chargé avant les packages, la nôtre a la priorité.
command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg --column --line-number --no-heading --color=always --smart-case '
      \   . '--hidden --glob "!.git" -- ' . fzf#shellescape(<q-args>),
      \   fzf#vim#with_preview(), <bang>0)
