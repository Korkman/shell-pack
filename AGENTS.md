# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project language

This project is written **predominantly in Fish shell** (fish 3.x and up). Occasional
**POSIX shell** (`sh`) is used only when absolutely necessary — for example in
bootstrap scripts that must run before fish is available (such as
[get.sh](get.sh)), or when interoperating with tools that require POSIX.

When adding or editing code:

- Default to **Fish shell** for all new scripts, functions, and completions.
- Use POSIX `sh` **only** when there is a concrete reason fish cannot be used
  (e.g. pre-install bootstrap, `/bin/sh` required by an external caller).
- Do **not** use bash-only constructs (arrays, `[[ ]]`, `$'...'`, process
  substitution `<(...)`, `${var,,}`, etc.) in POSIX files. Stick to portable
  `sh`.

## Fish shell idioms to follow

- Indent with **tabs** (matches existing files).
- Use `argparse` for option parsing in functions.
- Use `set -l` for local variables, `set -g` for globals; never rely on
  implicit scoping.
- Use command substitution with `(cmd)`, not backticks.
- Use `and` / `or` / `;` between commands, not `&&` / `||`.
- Use `test` (not `[` / `[[`) for conditionals.
- Prefer `string` builtin over `sed`/`awk` for simple string work.
- Prefer `command -vq foo` over `which foo` to check for a binary.

## Fish `math` — important

Fish's `math` builtin is for **arithmetic only**. Do **not** use it to compare
values; comparison expressions like `math "$a < $b"` must not be relied upon
for control flow.

To compare numeric values in fish:

- For integers, use `test` with `-lt` / `-le` / `-eq` / `-ge` / `-gt`:

  ```fish
  if test $count -lt 10
      ...
  end
  ```

- For floats, scale to integers first using `math -s0` (truncate to integer),
  then compare with `test`:

  ```fish
  set -l a_ms (math -s0 "$a * 1000")
  set -l b_ms (math -s0 "$b * 1000")
  if test $a_ms -lt $b_ms
      ...
  end
  ```

- Alternatively, delegate the comparison to `awk` or `bc -l` and test the
  resulting string / exit status.

## Portability

Edits should be compatible with fish 3.5.1 up to latest and the following environments:
- GNU coreutils (Debian)
- BSD utils (FreeBSD)
- busybox

## Other hints

- `wc -c` is not the preferred method to determine filesize, delegate to `__sp_get_filesize` instead
- `mktemp` has a richer, more portable equivalent __sp_mkuniq

## Running test-drive and td

`td` (and its `td-test-*` modules, including `td test-all`) is meant to run
inside containers started with
[devel/docker/test-drive](devel/docker/test-drive). Do not run `td` tests on the host.
A good low footprint container can be run with `./test-drive alpine:latest persist`.
It will persist changes such as `apk add` commands between runs. Answer "y" to all
dependency questions on first run. Such interactive sessions can be controlled by agents with `tmux`. Do not
confuse with `test-drive-tmux` which is a wrapper to select images with specific
`tmux` versions to run inside `test-drive`. Use `td edit-live` inside to link
the host source repo to `/repo` inside the container and switch over to it for
the shell-pack runtime. To clear all artifacts, run
`./test-drive alpine:latest rm persist` to discard the persistence. 

Running `td test-all` non-interactively:

- `test-drive` needs a tmux session.
- Start the container in a detached tmux session, check its state with
  `tmux capture-pane -p -t <session>`, and send commands with `tmux send-keys`.
  Poll every 10 seconds rather than waiting long; the suite takes a few minutes.
- Run `td install-test-deps` inside the container before `td test-all`. It detects
  apk, zypper, dnf, pacman or apt-get and installs every binary the test modules
  need, including `git` for `td-test-grasp-completions`. It finishes by listing
  any binaries still missing. Minimal images such as Alpine lack several of them.
  `compress` (.Z) is optional and not installed by default on Alpine, so cfc skips
  those checks.
- `td test-all` exits with the number of failed modules, so check `$status`
  right after it.

## Repository layout

- [bin/](bin/) — user-facing commands and scripts.
- [config/fish/](config/fish/) — fish configuration, functions, completions.
- [config/](config/) — configuration for htop, mc, etc.
- [devel/](devel/) — development helpers and Docker test images.
- [docs/](docs/) — user documentation (GitHub Pages).
