# ~/.bashrc — shells bash interactifs.
#
# Voir .profile pour la répartition env / interactif. Ici : options de shell,
# alias, fonctions et prompt, c'est-à-dire tout ce qu'un sous-shell n'hérite
# pas et qu'il faut donc redéfinir à chaque ouverture.

# Rien à faire si le shell n'est pas interactif.
case $- in
    *i*) ;;
      *) return;;
esac

# Note : sous Debian/Ubuntu, /etc/bash.bashrc est déjà chargé automatiquement
# avant ce fichier — inutile de le sourcer ici (ça doublerait bash-completion).

# ── Options de shell ────────────────────────────────────────────────────
shopt -s autocd 2>/dev/null     # `cd` implicite en tapant le nom d'un dossier
shopt -s histappend             # ajoute à l'historique au lieu de l'écraser
shopt -s checkwinsize           # met à jour LINES/COLUMNS après chaque commande
#shopt -s globstar              # ** récursif (désactivé : alourdit les globs)

# Note : HISTSIZE / HISTFILESIZE / HISTCONTROL sont dans .profile (env).

# ── Couleurs ────────────────────────────────────────────────────────────
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls="ls --color=auto"
    alias grep="grep --color=auto"
    alias fgrep="fgrep --color=auto"
    alias egrep="egrep --color=auto"
    alias diff="diff --color=auto"
fi

# ── Alias ───────────────────────────────────────────────────────────────
# eza remplace ls quand il est installé, sinon on garde le ls du système.
if command -v eza >/dev/null; then
    alias ll="eza -lh"
    alias la="eza -A"
    alias lla="eza -lAh"
else
    alias ll="ls -lh"
    alias la="ls -A"
    alias lla="ls -lAh"
fi
alias l="ls -CF"

alias vi="nvim"                 # "vim" pour revenir à vim
alias g="git"
alias rg="rg --hidden"
command -v fd >/dev/null && alias fd="fd -HI"
alias ssh="ssh -X"
alias cdd='cd "${HOME_DIR}"'

# Notification à la fin d'une commande longue :  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias supplémentaires hors dotfiles
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# ── Complétion ──────────────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

# ── fzf ─────────────────────────────────────────────────────────────────
#   Ctrl-R  historique fuzzy      Ctrl-T  insérer un fichier      Alt-C  cd
#   **<TAB> complétion fuzzy des chemins
#
# fzf >= 0.48 génère lui-même son intégration shell (`fzf --bash`) : c'est le
# chemin normal ici, ~/.local/bin/fzf étant installé par install-dotfiles.
# Sinon on retombe sur les fichiers livrés par l'install locale ou par le
# paquet système (Arch : /usr/share/fzf, Debian : /usr/share/doc/fzf/examples).
if _fzf_init="$(fzf --bash 2>/dev/null)"; then
    eval "${_fzf_init}"
else
    for _fzf_dir in "${XDG_DATA_HOME:-$HOME/.local/share}/fzf/shell" \
                    /usr/share/fzf \
                    /usr/share/doc/fzf/examples; do
        if [[ -f "${_fzf_dir}/key-bindings.bash" ]]; then
            . "${_fzf_dir}/key-bindings.bash"
            [[ -f "${_fzf_dir}/completion.bash" ]] && . "${_fzf_dir}/completion.bash"
            break
        fi
    done
fi
unset _fzf_init _fzf_dir

# ── Prompt git ──────────────────────────────────────────────────────────
# __git_ps1, utilisé par PS1 : Debian le livre dans git-core, Arch dans
# /usr/share/git. Sans lui, PS1 afficherait une erreur à chaque prompt.
for _git_sh in /usr/lib/git-core/git-sh-prompt \
               /usr/share/git/completion/git-prompt.sh \
               /etc/bash_completion.d/git-prompt; do
    [[ -f "${_git_sh}" ]] && { . "${_git_sh}"; break; }
done
unset _git_sh

# ── PS1 : user@host cwd (branche git) $ ─────────────────────────────────
# Utilisateur en rouge, root en bleu.
COLOR_RED="\[\e[91m\]"
COLOR_BLU="\[\e[94m\]"
COLOR_YEL="\[\e[93m\]"
COLOR_WHI="\[\e[97m\]"
COLOR_RES="\[\e[0m\]"

if (( EUID == 0 )); then
    _user_color="${COLOR_BLU}"
else
    _user_color="${COLOR_RED}"
fi
PS1="${_user_color}\u${COLOR_WHI}@\h ${COLOR_YEL}\w${COLOR_WHI}\$(__git_ps1) \\$ ${COLOR_RES}"
unset _user_color

# ── nvm ─────────────────────────────────────────────────────────────────
# nvm définit une fonction shell : elle n'est pas héritée par les sous-shells,
# d'où sa place ici et non dans .profile.
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[[ -s "${NVM_DIR}/nvm.sh" ]] && . "${NVM_DIR}/nvm.sh"
[[ -s "${NVM_DIR}/bash_completion" ]] && . "${NVM_DIR}/bash_completion"

# ── Config spécifique à la machine (non trackée) ────────────────────────
[[ -f "${HOME}/.bashrc.local" ]] && . "${HOME}/.bashrc.local"
