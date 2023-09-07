# Setting up gnome-terminal

## Nerd Font
* Download your preferred Nerd Font from www.nerdfonts.com, for example [DejaVuSansM](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/DejaVuSansMono.zip)
* Place all \*.ttf files from the .zip file not named "Propo" or "Mono" in ~/.local/share/fonts/

## Gnome Terminal
 * Shift + Right-click > Preferences
 * In section "General"
  * Uncheck "Enable the menu accelerator key (F10)", because f10 is to exit mc
  * Set theme to a dark theme, because light themes for terminals are wrong
 * Add a new profile (+)
  * On tab "Text", check custom font, select _any_ font, 11 point looks best (more on that later)
  * On tab "Command", check "Run a custom command", enter this:
```
/usr/bin/env LC_NERDLEVEL=3 fish -l
```
  * Also set it to always keep the working directory so the file browser context menu item "Open in terminal" works as expected
  * Optionally make it default (click on triangle)

### Fix the font in dconf
Since the picker allows selecting monospaced fonts only, our initial pick is wrong.

Edit the settings manually and set the font to "DejaVuSansM Nerd Font".

 * Dump the dconf and edit the file
```
dconf dump /org/gnome/terminal/ > ~/gnome-terminal.dconf
edit ~/gnome-terminal.dconf
```
 * Spot the font setting, change the name
```
font='DejaVuSansM Nerd Font 11'
```
* Import the dump
```
dconf load /org/gnome/terminal/ < ~/gnome-terminal.dconf
```
## The result
![Result](images/setup-gnome-terminal-complete.png)

## Further reading
 * [LC_NERDLEVEL](introducing-nerdlevel.md)
 * [Preferences](preferences.md)
 * [Return to index](index.md)
