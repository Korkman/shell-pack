## Preferences
A set of biased config files for midnight commander, htop, tmux, screen and fresh is included and offered to install on first startup (```shell-pack-prefs install```). Here are some examples:

### mc
* is dark themed for better readability
* has `alt-d` mapped to hotlist, which has a subgroup "shell-pack" kept in sync with tagged dirs
* has "confirm execute" and "lynx movement" enabled, "confirm exit" disabled
* has a new user menu (F2) with items useful in the 21st century

### mcedit
* has `ctrl-c`, `ctrl-v`, ```ctrl-x```, ```ctrl-z```, ```ctrl-y```, ```ctrl-s``` mapped to copy, paste, cut, undo, redo and save
* has ```ctrl-f``` mapped to search
* has ```ctrl-l``` & ```alt-l``` mapped to "go to line"
* has real tab characters, displayed as three spaces, set for indenting
* for a full list, read [config/mc/ini](/config/mc/ini) and [config/mc/mc.keymap](/config/mc/mc.keymap)

### htop
* displays memory usage as dedicated numbers
* displays cpu usage as unified chart
* has a few tabs defined for specific tasks

### tmux
* allows ```ctrl-a``` and ```ctrl-b``` for control sequence
* has several keys added to be more friendly for screen users
* uses ```-``` and ```|``` for splitting windows
* handles ssh agent forwarding properly (environment updates on attach)
* shows a nice blue bar on the bottom
* starts window index on 1
* see [.tmux.conf](/config/.tmux.conf) and [.tmux.conf.sh](/config/.tmux.conf.sh)

Set the universal variable `$__multiplexer_names` to a space separated list of aliases you want to use for referencing tmux sessions. Recommended: your username, shortened. Avoid conflicts with existing command names.

Example: `set -U __multiplexer_names 'me me2'`

A special alias `one` keeps a session which locks out other clients when attaching.

### fresh
* the new kid on the block, now the default $EDITOR & $VISUAL
* has a few keybinds changed
* see [config.json](/config/fresh/config.json)
