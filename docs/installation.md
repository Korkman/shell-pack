## Installation
Installation targets Linux, WSL and macOS, and should work for other \*nix as well.

The following dependencies have to be met beforehand:
 * [fish shell](https://fishshell.com/) version 3.1 or higher. Automated installer for several distros, YMMV:
    ```bash
    curl -sL https://raw.githubusercontent.com/Korkman/shell-pack/main/devel/docker/added/fish-installer.sh | sh
    ```

These optional dependencies are highly recommended
 * **do not** set fish as your default shell - a POSIX compliant shell is recommended (bash, zsh, …)
 * `tmux` or `screen`
 * `netcat` - either variant traditional or openbsd is fine
 * `mc` - midnight commander is tuned and integrated in several places

### Step 1: Installing shell-pack via `curl|sh`

Run
```bash
curl -sL https://raw.githubusercontent.com/Korkman/shell-pack/latest/get.sh | sh
```

The script will download and extract into ~/.local/share/shell-pack and link everything together. It will also add a single line to your .profile to integrate into your default POSIX compliant shell, e.g. bash.

<details>
  <summary>Example output</summary>
 
  ```
  Downloading korkman-shell-pack-latest.tar.gz ...
  Extracting korkman-shell-pack-latest.tar.gz ...
  Linking /home/your-name-here/.local/share/shell-pack/config → src/config
  Linking /home/your-name-here/.local/share/shell-pack/bin/ddstat → ../src/bin/ddstat
  (…)
  Adding shell-pack to /home/your-name-here/.config/fish/config.fish
  Added nerdlevel to /home/your-name-here/.profile
  All systems go. Happy fishing!
  ```
</details>

### Step 2: First launch

Run
```bash
fish
```

On first launch, shell-pack will pull in further dependencies, currently fuzzy finder and ripgrep. They will be installed into the shell-pack installation directory.

Also, it will ask to overwrite preferences for several programs. You don't have to install the preferences, but shell-pack gives you a very good starting point for advanced tmux and mc usage.

<details>
<summary>Example output</summary>
 
```
Welcome to FISH 3.2.1 + shell-pack 2.6
This seems to be your first time using shell-pack.
Installing dependencies ...
Project website: https://github.com/junegunn/fzf
OK to download and execute release file? (Y/n)
Downloading https://github.com/junegunn/fzf/releases/download/0.27.0/fzf-0.27.0-linux_amd64.tar.gz ...
Installing to /home/your-name-here/.local/share/shell-pack/bin/fzf ...
Installed version: 
0.27.0
Cleaning up ...
Complete
Project website: https://github.com/BurntSushi/ripgrep
OK to download and execute release file? (Y/n)
Downloading https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-unknown-linux-musl.tar.gz ...
Installing to /home/your-name-here/.local/share/shell-pack/bin/rg ...
Installed version: 
ripgrep 12.1.1 (rev 7cb211378a) -SIMD -AVX (compiled) +SIMD +AVX (runtime)
Cleaning up ...
Complete
Overwrite preferences for
 - tmux
 - screen
 - htop
 - mc
? (Y/n) 
```
</details>


Shell-pack is installed now.

### Step 3: Setup your terminal

Right now shell-pack is rather ugly, as it assumes you have neither a powerline font nor a nerd font installed.

![nerdlevel 1](images/nerdlevel-1.png)

Follow the setup guide for your terminal to install a Nerd Font (properly!):

[Gnome Terminal](setup-gnome-terminal.md) | [iTerm2](setup-iterm2.md) | [Other](setup-any-terminal.md)

![nerdlevel 3](images/nerdlevel-3.png)

Congratulations! Your prompt should look gorgeus now.

## Updates
Retrieving the latest version is as simple as running ```upgrade-shell-pack```. If any dependencies need to be upgraded as well, shell-pack will say so.

Shell-pack will check for a new version once a day on login and suggest an upgrade. This can be disabled by setting the variable $UPGRADE_SHELLPACK to "no" (`set -U UPGRADE_SHELLPACK no`) and enabled again through erasing the variable (`set -eU UPGRADE_SHELLPACK`).

## Other installation methods

### Installing a specific tag, like "v2.6"
```bash
export TAG="v2.6"; curl -sL "https://raw.githubusercontent.com/Korkman/shell-pack/$TAG/get.sh" | sh -s "$TAG"
```

### Installing shell-pack manually
 * Download [latest tar.gz](https://github.com/Korkman/shell-pack/archive/refs/tags/latest.tar.gz)
 * Extract to `$HOME/.local/share/shell-pack/src`
 * Verify README.md ended up in the correct place: `$HOME/.local/share/shell-pack/src/README.md`
 * Follow the steps in `$HOME/.local/share/shell-pack/src/get.sh`

### Installing for development

Install as usual. Clone git repo into a dedicated directory. Symlink the following locations to destinations in your development directory:
 * `~/.local/share/shell-pack/bin`
 * `~/.local/share/shell-pack/config`

This will have your changes take immediate effect on the local installation and you will be able to create commits. Be aware that upgrade-shell-pack will overwrite your git directory - it should not be run on developer installations. Also, do not accidentially add the binaries rg, fzf or sk to the repo.
