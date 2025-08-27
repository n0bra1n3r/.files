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

secret() {
  local var_name="$1"
  local secrets_file="$HOME/.config/secrets"

  if [[ -z "$var_name" ]]; then
    echo "Usage: secret <environment_variable_name>" >&2
    return 1
  fi

  # Check if the environment variable already exists
  if [[ -n "${!var_name:-}" ]]; then
    return 0
  fi

  # Check if secrets file exists and source it
  if [[ -f "$secrets_file" ]]; then
    source "$secrets_file"
    # Check again if the variable is now set
    if [[ -n "${!var_name:-}" ]]; then
      return 0
    fi
  fi

  # Variable still not set, prompt user for value
  read -s -p "Enter the value for $var_name: " var_value
  echo
  # Create .config directory if it doesn't exist
  mkdir -p "$(dirname "$secrets_file")"
  # Add the export line to the secrets file
  echo "export $var_name=\"$var_value\"" >> "$secrets_file"
  # Export the variable in the current session
  export "$var_name"="$var_value"
}

secret GH_TOKEN

export RG_PREFIX='rg --column --line-number --no-heading --color=always --smart-case'

rip() {
  fzf --bind 'start:reload:$RG_PREFIX ""' \
    --bind 'change:reload:$RG_PREFIX {q} || true' \
    --bind 'enter:become(vim {1} +{2})' \
    --ansi --disabled --layout=reverse
}

if ! command -v starship &> /dev/null
then
  STARSHIP_URL="https://github.com/starship/starship/releases/latest/download"

  if [[ "$OS" == "Windows"* ]]
  then
    wget -q -O /tmp/starship.zip $STARSHIP_URL/starship-x86_64-pc-windows-msvc.zip && unzip -o /tmp/starship.zip -d "$HOME/.local/bin/" && rm /tmp/starship.zip
  else
    wget -q -O - $STARSHIP_URL/starship-aarch64-apple-darwin.tar.gz | tar -xvf - -C "$HOME/.local/bin/"
  fi
fi

eval "$(starship init bash)"
