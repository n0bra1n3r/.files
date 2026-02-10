git clone --bare https://github.com/n0bra1n3r/.files $HOME/.files
git --git-dir=$HOME/.files/ --work-tree=$HOME checkout --force --recurse-submodules