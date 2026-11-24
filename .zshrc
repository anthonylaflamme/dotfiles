# Add colors to file listings.
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Show the current folder and Git branch in the prompt.
autoload -Uz vcs_info add-zsh-hook
add-zsh-hook precmd vcs_info
zstyle ':vcs_info:git:*' formats 'on %F{157}%b%f'
setopt PROMPT_SUBST
PROMPT='%n in %F{183}${PWD/#$HOME/~}%f ${vcs_info_msg_0_} > '

# Keep one copy of each command search path.
typeset -U path PATH
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
path=("$HOME/.local/bin" "$PNPM_HOME" "$BUN_INSTALL/bin" "${path[@]}")
export PATH

# Initialize Zsh completion before loading tool completions.
if ! (( $+functions[compdef] )); then
    autoload -Uz compinit
    compinit
fi

if [[ -s "$BUN_INSTALL/_bun" ]]; then
    source "$BUN_INSTALL/_bun"
fi

if (( $+commands[npm] )); then
    _npm_completion() {
        local suggestions
        suggestions=$(COMP_CWORD=$((CURRENT - 1)) \
            COMP_LINE="$BUFFER" COMP_POINT=0 \
            npm completion -- "${words[@]}" 2>/dev/null) || return
        [[ -n "$suggestions" ]] && compadd -- "${(@f)suggestions}"
    }
    compdef _npm_completion npm
fi

if (( $+commands[yarn] && $+commands[node] )); then
    _yarn_completion() {
        [[ -f package.json ]] || return
        local suggestions
        suggestions=$(node -e "try{console.log(Object.keys(require('./package.json').scripts||{}).join('\n'))}catch(e){}" 2>/dev/null) || return
        [[ -n "$suggestions" ]] && compadd -- "${(@f)suggestions}"
    }
    compdef _yarn_completion yarn
fi
