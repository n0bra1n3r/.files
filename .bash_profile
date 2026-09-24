#!/usr/bin/env bash

source "$HOME/.profile"

bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case off'

bind 'TAB:menu-complete'
bind '"\e[Z":menu-complete-backward'
bind "set menu-complete-display-prefix on"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

export HISTCONTROL=ignoreboth:erasedups
export HISTFILESIZE=$HISTSIZE

PROMPT_COMMAND="history -a $HISTFILE;$PROMPT_COMMAND"

if [[ -f ~/.bashrc ]] && ! (return 0 2>/dev/null); then
  # shellcheck disable=1090
  source ~/.bashrc
fi

if ! command -v starship &> /dev/null
then
  curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y
fi

eval "$(starship init bash)"
