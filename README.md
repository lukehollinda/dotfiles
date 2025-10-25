Welcome to my personal dotfiles! Here you'll find scripts, aliases, and configuration for tools I find useful. This will forever be a work in progress, but feel free to steal anything you find useful.

Currently this is only set up for MacOS, but I plan on adding some Linux support in the future.

Many of the tools I use are specifically choosen to minimize having to use the mouse. I'm a big fan of keyboard driven workflows and I'm always open to people sharing their own tips and tricks.

## Requirements
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [oh-my-zsh](https://ohmyz.sh/) - Zsh configuration manager
    - Manually download the following plugins:
        - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/)
        - [zsh-vi-mode](https://github.com/zsh-users/zsh-syntax-highlighting/)
- [starship](https://starship.rs/) - Shell prompt

## Installation

Clone the repo wherever you'd like to keep it.

```bash
git clone https://github.com/lukehollinda/dotfiles.git
cd dotfiles
```

Run `set-up-symlinks.sh` which will create symlinks to the dotfiles in your home directory.

```bash
./set-up-symlinks.sh
```

Optionally, install backed up `brew` packages.

```bash
brew bundle --file=./brew/Brewfile
```


## Things of Note

- Neovim is my editor of choice. A couple cool plugins:
    - [gx.nvim](https://github.com/chrishrb/gx.nvim) - Allows you to open links in your browser with `gx`. Can also set up custom handlers for just about anything. (Jira, Github, etc)
    - [oil.nvim](https://github.com/stevearc/oil.nvim) - Replaces netrw with an explorer that lets you edit your filesystem like a regular buffer.
    - [vim-fugitive](https://github.com/tpope/vim-fugitive) - Almost exclusively use this `:Gblame` which shows git blame in line with your code.
    - [stay-centered.nvim](https://github.com/arnamak/stay-centered.nvim) - Avoids edge cases with remaps like `jzz` and `nzzzv`

- Tmux is my terminal multiplexer of choice. A couple cool plugins:
    - [tmux-fzf](https://github.com/sainnhe/tmux-fzf) - Adds a pleasant menu for things managing panes, windows, sessions. Useful for when I can't be bothered to remember a tmux command.
    - Some [very cool scripts](https://github.com/lukehollinda/dotfiles/blob/c28e734c027f9432dce32ada52e096f8e4d19d78/tmux/tmux.conf#L64-L66) for jumping between different Git repos / sessions. Inspired by ThePrimeagen.


- Lots of useful zsh aliases and functions, especially if you work with Kubernetes.
    - [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) - Improved vi mode for zsh. I love `set -o vi` and it's one of the first things I do on a new machine.
    -  It's a touch jank at the moment, but I have some small home made scripts which I use for navigating my terminal history from the keyboard. No amount of configuration would allow me to make tmux copy mode enough like nvim. So I just bound a key to dump my current tmux pane into nvim.

- [tridactyl](https://github.com/tridactyl/tridactyl) - Vim-like interface for Firefox. Similar to other great tools like [vimium](https://github.com/philc/vimium) and [Surfingkeys](https://github.com/brookhong/Surfingkeys). Highly configurable and brings me joy daily.

- [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) - I use this to remap ESC to caps lock. As well I have ctrl-hjkl remaped to the arrow keys for vim like movement in any application.


## Favorite tools not present in this repo:
- [Shortcat](https://shortcatapp.com/) - Vimium style navigate everywhere. Enables clicking on UI elements with the keyboard.
- [Thor](https://github.com/gbammc/Thor) - OS X app switcher. Enables opening and focusing applications with a single shortcut.
- [Tiles](https://freemacsoft.net/tiles/) - Window manager. Resizing and moving windows with the keyboard.
