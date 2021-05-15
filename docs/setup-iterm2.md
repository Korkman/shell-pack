# Setting up iTerm2

## Nerd Font
 * Download your preferred Nerd Font from www.nerdfonts.com, for example [DejaVuSansMono](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/DejaVuSansMono.zip)
 * Install the font, skip "Windows Compatible" named files

## iTerm2

 * In "Preferences", navigate to "Profiles" and create a new profile
 * On profile tab "General", set command to:
```
/usr/bin/env LC_NERDLEVEL=3 /usr/local/bin/fish -l
```
 * On profile tab "Text", set font to the installed Nerd Font with __only one__ "Mono" in the name
 * On profile tab "Keys", set left option key to Esc+
 
 Note the iTerm2 fish integration script is included in shell-pack and automatically applied when iTerm2 is used.

## The result
(screenshot soon)
 
## Further reading
 * [LC_NERDLEVEL](introducing-nerdlevel.md)
 * [Preferences](preferences.md)
