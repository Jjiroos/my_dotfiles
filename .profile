# ~/.profile — variables d'environnement, chargé au login.
#
# Répartition des rôles (même convention que le repo dotfiles) :
#   .profile → env EXPORTÉ : XDG, PATH, historique, options d'outils.
#              Hérité par tous les sous-shells, donc défini une seule fois.
#   .bashrc  → ce qui doit être REDÉFINI dans chaque shell interactif :
#              options shopt, alias, fonctions (fzf, nvm, __git_ps1), PS1.
#
# ~/.bash_profile est un symlink vers ce fichier.

# ── Répertoires XDG ─────────────────────────────────────────────────────
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"

# ── Outils par défaut ───────────────────────────────────────────────────
export EDITOR="vim"
export TERMINAL="kitty"
export BROWSER="firefox"

# Racine des projets (voir l'alias `cdd` dans .bashrc)
export HOME_DIR="/mnt/z/dev_workspace"

# ── Historique (bash + less) ────────────────────────────────────────────
# HISTSIZE/HISTFILESIZE vides = historique bash illimité : Ctrl-R (fzf)
# cherche alors dans la totalité des commandes déjà tapées.
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoreboth
export LESSHISTFILE=-

# Couleurs des warnings/erreurs GCC
export GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"

# ── PATH ────────────────────────────────────────────────────────────────
# Ajoute un répertoire en tête de PATH s'il existe et n'y est pas déjà :
# .profile peut être relu (re-login, `su -`) sans empiler les doublons.
_path_prepend() {
    [ -d "$1" ] || return 0
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) PATH="$1:${PATH}" ;;
    esac
}

export PNPM_HOME="${XDG_DATA_HOME}/pnpm"
_path_prepend "${HOME}/.opencode/bin"
_path_prepend "${PNPM_HOME}"
_path_prepend "${HOME}/.cargo/bin"
# En dernier, donc en TÊTE de PATH : ~/.local/bin contient le fzf récent
# (symlink vers ~/.local/share/fzf/bin/fzf) qui doit primer sur le
# /usr/bin/fzf du paquet apt, bien plus ancien.
_path_prepend "${HOME}/.local/bin"

export PATH
unset -f _path_prepend

# npm : garder la config dans ~/.config plutôt qu'à la racine du HOME
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# ── fzf ─────────────────────────────────────────────────────────────────
# ripgrep sert de moteur de listage : il respecte .gitignore, voit les
# fichiers cachés et saute .git. Utilisé par Ctrl-T et par la complétion **<TAB>.
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
# Ctrl-R : la commande complète est visible en preview (Ctrl-/ pour basculer),
# utile pour les one-liners plus larges que le terminal.
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind ctrl-/:toggle-preview"

# ── Overrides spécifiques à la machine (non trackés) ────────────────────
[ -f "${HOME}/.profile.local" ] && . "${HOME}/.profile.local"

# ── Shells bash interactifs : charger .bashrc ───────────────────────────
[ -n "${BASH_VERSION}" ] && [ -f "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
