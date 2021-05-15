# shell-pack
A fish shell environment with many quality of life improvements for sysadmins and devops.

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
 * tab title control with ```tag```, ```untag```
 * tmux shortcuts, including exclusive session ```one``` for shared access
 * double-space prefix to execute a command completely off-the-record (opposed to single space prefix, which can be recalled)

## Tools
 * `qssh`, a frontend to ssh with enhanced fingerprint dialogue, multi connect and more (requires ssh)
 * `ggrep` (`alt-g`), an easy to use ripgrep file content search with preview
 * `ggit`, quicky review changes, add files to the commit
 * Linux only
   * ```lsports```: list open ports in compact manner
   * ```lsnet```: list active network connections in compact manner
   * ```ddstat```: a dstat wrapper with "sticky" arguments (requires dstat)
   * ```qmount```: mount a partition to /run/q/name (skip /dev/)
   * ```ssmart```: shortcut to smartctl -x (skip /dev/)
   * ```qchroot```: enter a Linux chroot, mounting all the necessities of modern Linux life
   * ```qqemu```: start a disk or partition in a temporary VM without modifying the disk or network connectivity

Hyped? See the docs on [how to install shell-pack](https://korkman.github.io/shell-pack/).
