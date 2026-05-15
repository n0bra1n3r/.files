```sh
git clone --bare https://github.com/n0bra1n3r/.files $HOME/.files
```

Windows:

```sh
git --git-dir="$HOME/.files/" --work-tree="$HOME" submodule update --init "$HOME/AppData/Roaming/Zed"
```
Linux:

```sh
git --git-dir="$HOME/.files/" --work-tree="$HOME" submodule update --init "$HOME/.config/zed"
```
