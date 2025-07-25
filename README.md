Welcome to my personal dotfiles! Here you'll find scripts, aliases, and configuration for tools I find useful. This will forever be a work in progress, but feel free to steal anything you find useful.


Currently this is only set up for MacOS, but I plan on adding some Linux support in the future.


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

