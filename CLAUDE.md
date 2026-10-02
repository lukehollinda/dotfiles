# Working in this repo

## The configs are live

`set-up-symlinks.sh` symlinks this repo into `~/.config`, so there is no deploy
step and no staging buffer:

| Repo path | Symlinked to |
| --- | --- |
| `nvim/` | `~/.config/nvim` |
| `nvim-pager/` | `~/.config/nvim-pager` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `git/gitconfig` | `~/.gitconfig` |

Editing a file here changes the running tool immediately. The user works in Neovim
continuously, so a broken `nvim/` file costs him his editor. Make Neovim changes
one at a time and verify each before starting the next.

## Special Files that are always modified

- `.gitignore` matches `**/work*`, so edits in files like `zsh/work.zsh` never commit.

## nvim-pager shares code with nvim

`bin/nvim-pager` runs `NVIM_APPNAME=nvim-pager nvim`, which reads
`~/.config/nvim-pager`. Most of `nvim-pager/lua/` is symlinks back into
`nvim/lua/`: `options.lua`, `commands.lua` and
`misc-bindings.lua` are the same files as the editor's.

Editing those changes both the editor and the pager. Only `nvim-pager/lua/pager.lua`
and `nvim-pager/lua/plugins/` are pager-specific.

Pager startup time is a priority. Measure before and after any change that adds
work to that path.

## lazy.nvim: changing a plugin URL

Changing the URL in a plugin spec does not take effect on restart. lazy only
reports `Origin has changed` and keeps the old checkout; the re-clone happens
during an update (`lua/lazy/manage/task/git.lua`, the `M.origin` task). The user
must run `:Lazy update <plugin>` themselves. Until they do, the config and the
installed plugin disagree, which can leave LSP or other features silently dead.

## Verifying Neovim changes

Headless nvim cannot verify anything involving window width, terminal buffers,
highlights, or what is actually drawn. Use a throwaway tmux session as a real
pty and have the test write results to a file:

```sh
tmux new-session -d -s probe -x 120 -y 30 "nvim ... -c 'luafile /tmp/check.lua' -c 'q!'"
sleep 4; tmux kill-session -t probe
```

To check what Neovim actually rendered, including colour, capture the pane with
escape sequences intact:

```sh
tmux capture-pane -t probe -e -p
```

Never kill nvim processes by a broad pattern. The user has many editor instances
open; match on the specific scratch path or session name instead.

### Test keymaps through feedkeys

Calling a mapped function directly bypasses mapping resolution and will pass
even when the mapping is shadowed:

```lua
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(']]', true, false, true), 'x', false)
```

This matters because Neovim sets buffer-local mappings on terminal buffers
(`runtime/lua/vim/_core/defaults.lua`) that override global ones.

## Benchmarking on this machine

Timings are noisy; a single A/B run routinely reverses on repeat. Interleave the
variants across several rounds and compare the pattern, not one pair. Keep the
timing harness out of the measurement: spawning `python3` to read a clock costs
more than most things worth measuring here. Time a loop of N iterations and
divide.
