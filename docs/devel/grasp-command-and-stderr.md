# grasp: STDERR of COMMAND

When passing a command to grasp, like

`ppage sh -c 'echo 123; echo 456 >&2; echo 789'`

fzf runs the command through `FZF_DEFAULT_COMMAND`. fzf discards the command's STDERR by
default, so grasp routes it itself. The `--stderr=MODE` option selects how.

## Modes

| MODE | Shown in fzf | Ordering | Notes |
|------|--------------|----------|-------|
| `prefix` (default) | yes, marked `E` in red | not guaranteed | STDERR is piped asynchronously |
| `plain` | yes, unmarked | kept | STDERR is indistinguishable from STDOUT |
| `postpone` | no | n/a | printed to STDERR after fzf closes, at most 100000 lines |
| `hide` | no | n/a | STDERR is discarded (passed to fzf) |

## Examples

Command: `ppage sh -c 'echo 123; echo 456 >&2; echo 789'`

`prefix`, shown in fzf:

```
123
789
E 456
```

`plain`, shown in fzf:

```
123
456
789
```

`postpone`, shown in fzf, then printed to STDERR after fzf closes:

```
123
789
456
```

`hide`, shown in fzf:

```
123
789
```

## postpone

STDERR is kept in a temporary file as plain text. Only the first 100000 lines
are kept. Lines beyond that are read and dropped, so the command is not interrupted.
After fzf closes, grasp prints the file to STDERR and deletes it.

The file path is exported as `GRASP_STDERR_FILE`, so `reload` in fzf keeps using the same file.

## Precedence

`--stderr` takes one value. An unknown value exits with status 2 before fzf starts.
