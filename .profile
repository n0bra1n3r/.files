PATH="$PATH:$HOME/.local/bin"

export PATH

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

if echo "$PWD" | grep -iq "/system32"
then
  cd "$HOME"
fi
