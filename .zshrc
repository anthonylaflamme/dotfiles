PATH=$PATH:.
# Add colors to Terminal
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats "on %F{157}"$'\UE0A0'" %b%f"

# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%n in %F{183}${PWD/#$HOME/~}%f ${vcs_info_msg_0_} > '

