secret() {
  local var_name="$1"
  local secrets_file="$HOME/.config/secrets"

  if [[ -z "$var_name" ]]; then
    echo "Usage: secret <environment_variable_name>" >&2
    return 1
  fi

  # Check if the environment variable already exists
  local current_value
  eval "current_value=\$$var_name"
  if [[ -n "$current_value" ]]; then
    return 0
  fi

  # Check if secrets file exists and source it
  if [[ -f "$secrets_file" ]]; then
    source "$secrets_file"
    # Check again if the variable is now set
    eval "current_value=\$$var_name"
    if [[ -n "$current_value" ]]; then
      return 0
    fi
  fi

  # Variable still not set, prompt user for value
  # Handle shell differences for read command
  local var_value
  if [[ -n "$ZSH_VERSION" ]]; then
    # zsh syntax
    echo -n "Enter the value for $var_name: "
    read -s var_value
    echo
  else
    # bash syntax
    read -s -p "Enter the value for $var_name: " var_value
    echo
  fi

  # Create .config directory if it doesn't exist
  mkdir -p "$(dirname "$secrets_file")"
  # Add the export line to the secrets file
  echo "export $var_name=\"$var_value\"" >> "$secrets_file"
  # Export the variable in the current session
  eval "export $var_name=\"$var_value\""
}

secret GH_USER
secret GH_TOKEN

case "$PWD" in
  *[Ss]ystem32*)
    cd "$HOME"
    ;;
esac

if [[ -f "/usr/share/cachyos-zsh-config/cachyos-config.zsh" ]]; then
    source /usr/share/cachyos-zsh-config/cachyos-config.zsh
fi
