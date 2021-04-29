# shell-pack
A shell preset with many quality of life improvements for sysadmins.

## Features
 * vibrant colors, nice icons
 * execution time, exit status and pipe status visibility
 * background job execution time, exit status, PID visibility
 * a cheat sheet for itself, ```cheat```, and a test for your terminal, ```cheat --glyphs```
 * advanced directory navigation
  * alt + arrow keys navigates history back, forward, dir up and dive with menu
  * bookmarks with ```tagdir```, ```untagdir```, ```d```
 * improved history navigation, deletion, private mode ```private```
 * recursive search for filenames with ```alt-f```, file content with ggrep
 * tab title control with ```tag```, ```untag```
 * tmux shortcuts, including exclusive session ```one``` for shared access
 * double-space prefix to execute a command completely off-the-record (opposed to single space prefix, which can be recalled)

## Tools
 * ```qssh```: a frontend to ssh with enhanced fingerprint dialogue, multi connect and more (requires ssh)
 * ```lsports```: list open ports in compact manner
 * ```lsnet```: list active network connections in compact manner
 * (Linux only) ```ddstat```: a dstat wrapper with "sticky" arguments (requires dstat)
 * (Linux only) ```qmount```: mount a partition to /run/q/name
 * (Linux only) ```qchroot```: enter a Linux chroot, mounting all the necessities of modern Linux life
 * (Linux only) ```qqemu```: start a disk or partition in a temporary VM without modifying the disk or network connectivity

## Preferences
For mc, htop, tmux (and screen) a biased preset of preferences is included and offered to install on first startup (or use ```reinstall-shell-pack-prefs```).

mc
* is dark themed for better readability
* has ```ctrl-c```, ```ctrl-v```, ```ctrl-x```, ```ctrl-z```, ```ctrl-y```, ```ctrl-s``` mapped to copy, paste, cut, undo, redo and save
* has ```ctrl-f```, ```ctrl-g```, ```ctrl-h``` mapped to search, search again and replace
* has ```ctrl-l``` & ```alt-l``` mapped to "go to line"
* has confirm execute toggled on
* has tabs, displayed as three spaces, set for indenting
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
* for a full list, read [.tmux.conf](config/.tmux.conf)

## Installation
Installation targets Linux and macOS, and should work for other \*nix as well.

The following dependencies have to be installed by the user:
 * [fish](https://fishshell.com/) >= 3.1 (currently no auto-installer included)
 * tmux / screen (recommended, some features require tmux)

Installing shell-pack via ```curl|sh```:
```
# NOTE: this script will not execute partially when disconnected
curl -s -L https://github.com/Korkman/shell-pack/raw/latest/get.sh | sh
```

Installing shell-pack manually via download and extract:
 * Download latest tar.gz
 * Extract to $HOME/.local/share/shell-pack/src
 * Check README.md ended up here: $HOME/.local/share/shell-pack/src/README.md
 * Follow the steps in $HOME/.local/share/shell-pack/src/get.sh

### Other dependencies

Installed automatically:
 * skim (installs to $HOME/.local/share/shell-pack/bin/sk)
 * ripgrep (installs to $HOME/.local/share/shell-pack/bin/rg)

These are expected to be present everywhere:
 * POSIX-compliant shell (/bin/sh)

## Nerdlevel
Introducing LC_NERDLEVEL, a variable that represents whether your session should run fish at all, and if so, whether powerline or nerdfonts are installed in your terminal. The LC_ prefix was chosen because it is accepted by most ssh server configs. The intention is to have bash, zsh or any other POSIX-compliant shell set as default, and only crank the nerdlevel up when connecting with a properly set up terminal.

|LC_NERDLEVEL|Effect     |
|-----------:|-----------|
|           0|None - your default login shell starts|
|           1|Fish shell starts, rather ugly with no special font support|
|           2|Add Powerline Font Glyphs|
|           3|Add Nerdfont Glyphs|

The nerdlevel can be changed at runtime using the "nerdlevel" command. It is especially useful to "dumb down" a session when connecting from a less sophisticated terminal.

### Setting up a Microsoft Terminal profile (and WSL)
(coming soon)

### Setting up an iTerm2 profile

#### On tab "General"
With a proper [Nerdfont](https://www.nerdfonts.com) installed, set command to:
```
/usr/bin/env LC_NERDLEVEL=3 /usr/bin/login -fp (your username)
```
Or, lacking a font, check "Use built-in Powerline glyphs" on tab "Text" and set command to:
```
/usr/bin/env LC_NERDLEVEL=2 /usr/bin/login -fp (your username)
```

#### On tab "Keys"
Enable reporting modifiers using CSI and set left option key to send Esc+ (now alt+x works in qssh).

### Setting up Terminator
(coming soon)

### Setting up PuTTY
(coming soon)

## Well-thought CLI interaction
(coming soon)
This is how it looks, why, and what features it has (run command "cheat")

## Updating
Retrieving the newest version is as simple as running ```upgrade-shell-pack```. If any dependencies need to be upgraded as well, shell-pack will say so on startup once a day.

## Development

Install as usual. Clone git repo into a dedicated directory. Symlink the following locations to destinations in your development directory:
 * ~/.local/share/shell-pack/bin
 * ~/.local/share/shell-pack/config
