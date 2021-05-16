## Preferences you can change

### shell-pack
Set the universal variable $\_\_multiplexer\_names to a space separated list of aliases you want to use for referencing tmux sessions. Recommended: your username, shortened. Avoid conflicts with existing command names.

Example: `set -U __multiplexer_names 'me me2'`

## Preferences changed for you
For mc (and mcedit), htop, tmux (and screen) a biased preset of preferences is included and offered to install on first startup (or use ```reinstall-shell-pack-prefs```). This is an overview of their effects.

mc
* is dark themed for better readability
* has `alt-d` mapped to hotlist, which has a subgroup "shell-pack" kept in sync with tagged dirs
* has confirm execute toggled on, confirm exit toggled off

mcedit
* has `ctrl-c`, `ctrl-v`, ```ctrl-x```, ```ctrl-z```, ```ctrl-y```, ```ctrl-s``` mapped to copy, paste, cut, undo, redo and save
* has ```ctrl-f``` mapped to search
* has ```ctrl-l``` & ```alt-l``` mapped to "go to line"
* has real tab characters, displayed as three spaces, set for indenting
* for a full list, read [config/mc/ini](config/mc/ini) and [config/mc/mc.keymap](config/mc/mc.keymap)

htop
* displays memory usage as dedicated numbers
* displays cpu usage as unified chart

tmux
* allows ```ctrl-a``` and ```ctrl-b``` for control sequence
* has several keys added to be more friendly for screen users
* uses ```-``` and ```|``` for splitting windows
* handles ssh agent forwarding properly (environment updates on attach)
* shows a nice blue bar on the bottom
* starts window index on 1
* for a full list, read [.tmux.conf](config/.tmux.conf)
