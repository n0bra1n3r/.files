PATH="$PATH:$HOME/.nimble/bin:$HOME/.local/bin"

export PATH

if [[ "$OS" == "Windows"* ]]; then
  vs_init="$HOME/.vs_init"
  if [ ! -f "$vs_init" ]; then
    vs_id=$(winget list --name "Visual Studio" --source winget | grep -oE "Microsoft\.VisualStudio\.[0-9]{4}\.[a-zA-Z]+")
    if [ -z "$vs_id" ]; then
      vs_id="Microsoft.VisualStudio.2022.Community"
    fi
    if winget list --id "$vs_id" &>/dev/null; then
      edition=$(echo "$vs_id" | awk -F. '{print $NF}')
      "/c/Program Files (x86)/Microsoft Visual Studio/Installer/vs_installer.exe" modify \
        --installPath "C:\\Program Files\\Microsoft Visual Studio\\2022\\$edition" \
        --passive --norestart \
        --add "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" \
        --add "Microsoft.VisualStudio.Component.Windows11SDK.22000"
    else
      winget install "$vs_id" \
      --silent --override "--passive --norestart --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22000"
    fi
    touch "$vs_init"
  fi
  eval "$(vcvarsall.sh x64)"
fi

secret() {
  local var_name="$1"
  local secrets_file="$HOME/.config/secrets"
  if [[ -z "$var_name" ]]; then
    echo "Usage: secret <environment_variable_name>" >&2
    return 1
  fi
  local current_value
  eval "current_value=\$$var_name"
  if [[ -n "$current_value" ]]; then
    return 0
  fi
  if [[ -f "$secrets_file" ]]; then
    source "$secrets_file"
    eval "current_value=\$$var_name"
    if [[ -n "$current_value" ]]; then
      return 0
    fi
  fi
  local var_value
  if [[ -n "$ZSH_VERSION" ]]; then
    echo -n "Enter the value for $var_name: "
    read -s var_value
    echo
  else
    read -s -p "Enter the value for $var_name: " var_value
    echo
  fi
  mkdir -p "$(dirname "$secrets_file")"
  echo "export $var_name=\"$var_value\"" >> "$secrets_file"
  eval "export $var_name=\"$var_value\""
}

git() {
  command git \
    -c include.path="$HOME/.config/git/config" \
    -c url."https://$GH_USER:$GH_TOKEN@github.com".insteadOf="https://github.com" \
    "$@"
}

if [[ $- == *i* ]]; then
  secret GH_USER
  secret GH_TOKEN
fi

case "$PWD" in
  *[Ss]ystem32*)
    cd "$HOME"
    ;;
esac

alias dot='git --git-dir="$HOME/.files/" --work-tree="$HOME"'
alias dota='dot add -u'
alias dotc='dot cm'
alias dotp='dot pu --recurse-submodules=on-demand'
alias dots='dot st --untracked-files=no'
alias dotu='dot pl'

alias g='git'
alias ga='g add'
alias gi='g ig'
alias gc='g cm'
alias gl='g lo'
alias gm='g ca'
alias gp='g pu'
alias gr='g rb'
alias gs='g st'
alias gu='g pl'
alias gw='g sw'

gsync() {
  g fe "$@":"$@" && g rb "$@"
}

alias z='zeditor'
