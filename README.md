# shell-pack
A fish shell environment with many quality of life improvements for sysadmins and devops.

![nerdlevel 3](docs/images/nerdlevel-3.png)

## Features
 * vibrant colors, nice icons
 * execution time, exit status and pipe status visibility
 * background job execution time, exit status, PID visibility
 * a cheat sheet for itself, ```cheat```, and a test for your terminal, ```cheat --glyphs```
 * advanced directory navigation
   * `shift-arrows` or `alt-arrows` navigate history back, forward, dir up and dive with menu
   * `alt-d` or alias `d` jumps to bookmarks set with `tagdir`, `untagdir`
   * `alt-c` shows recursive change directory menu
 * improved `ctrl-r` history navigation and deletion
 * private mode alias `private`
 * recursive search for filenames with `alt-f`
 * tab / window title control with ```tag```, ```untag```, informative generated titles
 * tmux shortcuts, including exclusive session ```one``` for shared access

## Tools
 * `qssh`, a frontend to ssh with enhanced fingerprint dialogue, multi connect and more (requires ssh)
 * `rrg` (`alt-g`), an easy to use ripgrep file content search with preview
 * `ggit`, quickly review changes, add files to the commit
 * `venv`, activate / deactivate Python virtual env corresponding to current directory
 * Linux only
   * ```lsports```: list open ports in compact manner
   * ```lsnet```: list active network connections in compact manner
   * ```ddstat```: a dstat wrapper with "sticky" arguments (requires dstat)
   * ```qmount```: mount a partition to /run/q/name (blockdevice autocomplete)
   * ```ssmart```: shortcut to smartctl -x (skip /dev/)
   * ```qchroot```: enter a Linux chroot, mounting all the necessities of modern Linux life
   * ```qqemu```: start a disk or partition in a temporary VM without modifying the disk or network connectivity

Hyped? See [the docs](docs/index.md) on [how to install shell-pack](docs/installation.md).
