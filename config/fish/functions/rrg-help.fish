function rrg-help
	echo "
=== rrg usage ===

rrg PATTERN

Searches case-insensitive PATTERN in all non-binary files recursively.
All matches are shown. Results are shown in skim, an interactive fuzzy
search engine. While the  spinner is rotating more results may be
retrieved.

For ripgrep PATTERN syntax (mostly PCRE), see

   rg --help | less

Skim fuzzy search in RESULTS LIST:
   characters matches all characters as solid as possible (fuzzy)
   !negation removes all matching lines
   'word matches only the word (non-fuzzy)
   ^start matches start at the beginning of a line
   $end matches at the end
   | combines search strings with boolean OR
   ctrl-r toggles regular expression search indicated by "/RE"

rrg keybindings:
   exit                          ctrl-q        esc-esc
   toggle matches preview        ctrl-p
   start vim on matched line     ctrl-v           
   start less on matched line    ctrl-l
   start mcedit on matched line  f4
   start mcview on file          f3
   read all matches in file      enter
   toggle regex search           ctrl-r

When piped, the limit of 100000 results is lifted and results are listed
as filenames only for further processing.

=== rrg-in-file usage ===

rrg-in-file -f FILE PATTERN

Same search engine as rrg, but shows all matches in specified file.

For more help, see
   rrg-in-file --help

" | less --clear-screen
end
