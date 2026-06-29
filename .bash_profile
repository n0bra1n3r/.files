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
  STARSHIP_URL="https://github.com/starship/starship/releases/latest/download"

  if [[ "$OS" == "Windows"* ]]
  then
    wget -q -O /tmp/starship.zip $STARSHIP_URL/starship-x86_64-pc-windows-msvc.zip && unzip -o /tmp/starship.zip -d "$HOME/.local/bin/" && rm /tmp/starship.zip
  elif [[ "$OSTYPE" == "darwin"* ]]
  then
    wget -q -O - $STARSHIP_URL/starship-aarch64-apple-darwin.tar.gz | tar -xvf - -C "$HOME/.local/bin/"
  else
    wget -q -O - $STARSHIP_URL/starship-x86_64-unknown-linux-gnu.tar.gz | tar -xvzf - -C "$HOME/.local/bin/"
  fi
fi

eval "$(starship init bash)"
