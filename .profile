PATH="$PATH:$HOME/.local/bin"

export PATH

alias dot='git --git-dir="$HOME/.files/" --work-tree="$HOME"'
alias dota='dot add -u'
alias dotc='dot cm'
alias dotp='dot pu --recurse-submodules=on-demand'
alias dots='dot st --untracked-files=no'
alias dotu='dot pull'

alias g='git'
alias ga='g add'
alias gi='g ig'
alias gc='g cm'
alias gp='g pu'
alias gs='g st'
alias gu='g pl'
alias gw='g sw'

if echo "$PWD" | grep -iq "/system32"
then
  cd "$HOME"
fi
