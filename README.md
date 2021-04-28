# shell-pack
All your shell are belong to us

TODO: insert awesome screenshot here

## Introduction
shell-pack is a Fish shell toolkit and theme with emphasis on easy installation, seamless integration and well-thought CLI interaction. It also comes with a small set of tools to make the life of a sysadmin easier.

## Easy installation (under construction)
Installation targets Linux and macOS, and should work for other \*nix as well.

The following dependencies have to be installed by the user:
 * [fish](https://fishshell.com/) >= 3.1 (currently no auto-installer included)
 * tmux / screen (recommended, some features require tmux)

These dependencies are installed automatically:
 * skim (installs to $HOME/.local/share/shell-pack/bin/sk)
 * ripgrep (installs to $HOME/.local/share/shell-pack/bin/rg)

These are expected to be present everywhere:
 * POSIX-compliant shell (/bin/sh, expected to be present everywhere)

Installing shell-pack via ```curl|sh```:
```
# NOTE: this script will not execute partially when disconnected
curl -L https://github.com/Korkman/shell-pack/raw/latest/get.sh | sh
```

Installing shell-pack manually via download and extract:
 * Download latest tar.gz
 * Extract to $HOME/.local/share/shell-pack/src
 * Check README.md ended up here: $HOME/.local/share/shell-pack/src/README.md
 * Follow the steps in $HOME/.local/share/shell-pack/src/get.sh

## Seamless integration
Introducing LC_NERDLEVEL, a variable that represents whether your terminal should run fish at all, and if so, whether powerline or nerdfonts are installed. LC_* prefixed as it is, this variable will likely be passed on to ssh hosts.

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
