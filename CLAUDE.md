# Working in this repo

## The configs are live

`set-up-symlinks.sh` symlinks this repo into `~/.config`, so there is no deploy
step and no staging buffer:

| Repo path | Symlinked to |
| --- | --- |
| `nvim/` | `~/.config/nvim` |
| `nvim-pager/` | `~/.config/nvim-pager` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `rex/` | `~/.config/rex` |
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

## Verifying Rex changes

In a worktree, `rex/` and `bin/scripts/` are not the copies the live server
loads, and a plain `rex` command reaches the live server and the user's
sessions. Use `bin/scripts/rex-test.bash` wherever you would type `rex`. It
starts a private server, one per checkout, that loads `rex/init.lua` and
`bin/scripts/` from the checkout it is called in, and runs its arguments
against that server:

```sh
bin/scripts/rex-test.bash new probe
bin/scripts/rex-test.bash keymap --json
bin/scripts/rex-test.bash do -s probe -b <block> confirm_close_pane
bin/scripts/rex-test.bash capture -s probe --trim
bin/scripts/rex-test.bash config reload   # after editing rex/*.lua
bin/scripts/rex-test.bash server stop     # when finished
```

Never run `rex server stop` or `rex kill` without the wrapper: they end the
user's sessions.

No app is connected to the private server, so client actions
(`client.tab.new`, `session.select`) fail with `no app client is connected`,
and nothing shows what a key press draws. Those need the user, after the merge.
The private server still shares `~/.local/state/rex` with the live one.

## Closing an agent's tab and worktree

To close another agent's tab, remove its worktree and delete its branch, run
the script behind `ctrl+a X` with the agent's session and any pane in its tab:

```sh
bin/scripts/rex-close.bash SESSION BLOCK
```

It exits 1 with the reason on stderr, and closes nothing, when the worktree has
uncommitted changes, commits that are on neither its upstream (or
`origin/HEAD`) nor the local default branch, or an nvim with unsaved buffers.
There is no force flag. The branch is deleted with `git branch -d` only when it
is merged into the local default branch. Without a terminal on stdin it never
closes a whole session.

## Benchmarking on this machine

Timings are noisy; a single A/B run routinely reverses on repeat. Interleave the
variants across several rounds and compare the pattern, not one pair. Keep the
timing harness out of the measurement: spawning `python3` to read a clock costs
more than most things worth measuring here. Time a loop of N iterations and
divide.
