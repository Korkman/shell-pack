# Setup any terminal

## Nerd Font
* Download your preferred Nerd Font from www.nerdfonts.com, for example [DejaVuSansMono](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/DejaVuSansMono.zip)
* Install the font on your system, skipping either all files named "Windows Compatbile" or vice-versa

## Alternative: Powerline font
If you failed to convince your terminal to use a Nerd Font, a Powerline font will at least show the most desired glyphs correctly.
* Download a [Powerline font](https://github.com/powerline/fonts)
* Install the font on your system

## Your terminal emulator

### Goal 1: set LC_NERDLEVEL
Your terminal should have the option to set "Environment variables". Add the variable LC_NERDLEVEL and set it accordingly (see ["Introducing LC_NERDLEVEL"](introducing-nerdlevel.md)). Start by setting it to 1, then log in to see fish (and shell-pack) start automatically.

### Goal 2: the font
 * The idea is to use the **non-monospace** variant of the downloaded font to render your terminal.
 * Many terminal UIs disallow using non-monospace fonts, thus it may be necessary to "hack" the correct font name into the config.
 * Many terminals cannot render the full icon set of Nerd Fonts. Test your terminal with 
```
cheat --glyphs
```
 * Increase LC_NERDLEVEL accordingly, worst-case stay at 1.

### Goal 3: modifier keys
Modifier key combinations (alt, ctrl, shift) might fail to be recognized or fire a command locally in your terminal.
* Reduce hotkeys in your terminal settings to the absolute minimum
* Test navigating in shell-pack with shift+arrowkeys
* Test keys advertised in `cheat` and mentioned widgets
* Try changing terminal settings if something doesn't work

## Further reading
 * [LC_NERDLEVEL](introducing-nerdlevel.md)
 * [Preferences](preferences.md)
 * [Return to index](index.md)

