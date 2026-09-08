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

## Other hints

- `wc -c` is not the preferred method to determine filesize, delegate to `__sp_get_filesize` instead

## Repository layout

- [bin/](bin/) — user-facing commands and scripts.
- [config/fish/](config/fish/) — fish configuration, functions, completions.
- [config/](config/) — configuration for htop, mc, etc.
- [devel/](devel/) — development helpers and Docker test images.
- [docs/](docs/) — user documentation (GitHub Pages).
