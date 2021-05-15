## LC_NERDLEVEL
Introducing LC_NERDLEVEL, a variable which represents whether your session should run fish at all,
and if so, which fonts are installed in your terminal. The LC_ prefix was chosen 
because it is accepted by most ssh server configs. The intention is to have bash, zsh or any other
POSIX-compliant shell set as default, and only crank the nerdlevel up when connecting with a properly
set up terminal.

|LC_NERDLEVEL|Effect     |
|-----------:|-----------|
|           0|None - your default login shell starts|
|           1|Fish shell starts, rather ugly with no special font support|
|           2|Add [Powerline](https://github.com/powerline/fonts) font glyphs|
|           3|Add [Nerd Font](https://www.nerdfonts.com/) glyphs|

The nerdlevel can be changed at runtime using the `nerdlevel` command. It is especially useful to
"dumb down" a tmux session when connecting from a less sophisticated terminal.

### Why the fuss?
LC_NERDLEVEL is mostly about server-side installation, where people log in with various terminals and 
expectations, maybe even shared accounts. Keeping the default, POSIX-compliant shell and only upgrading 
to fish and fonts on-demand makes it easy to give shell-pack a try without causing conflicts.

If it is only you connecting to the account and you are confident that your terminal will always
have the necessary font installed, you might as well `chsh` to fish and `set -U LC_NERDLEVEL 3`.
