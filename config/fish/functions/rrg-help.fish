function rrg-help
	echo "
=== rrg usage ===

rrg PATTERN
rrg [--option1, --option2, ...] -- PATTERN

Searches case-insensitive PATTERN in all non-binary files recursively.
All matches are shown. Results are shown in fzf, an interactive fuzzy
search engine. While the spinner is rotating more results may be
retrieved.

For ripgrep PATTERN syntax (mostly PCRE) and options, see

   rg --help | less

NOTE: Not all options are compatible with rrg usage. Some useful examples:

  -z, --search-zip       Search compressed files (not archives!)
  -g, --glob '*.htm'     Limit file names processed
      --glob '!*.js'     
  -m, --max-count 1      Limit results per file
      --max-depth 1      Limit directory traversal
      --max-filesize 1M  Limit file size (larger files will be skipped)
      --multiline        Allow multiline matches
      --multiline-dotall Requires --multiline, makes dot include newlines
  -L, --follow           Follow symlinks
  -s, --case-sensitive   As it says
      --text             Treat binary files as text, may crash terminal
                         (but useful to search in .tar archives)

These default options are applied, some of which can be overridden:
   --ignore-case --hidden --no-ignore
   --auto-hybrid-regex --one-file-system
   --color always --max-columns 500 --with-filename --line-number

fzf fuzzy search in RESULTS LIST:
   characters matches all characters as solid as possible (fuzzy)
   !negation removes all matching lines
   'word matches only the word (non-fuzzy)
   ^start matches start at the beginning of a line
   $end matches at the end
   | combines search strings with boolean OR
   ctrl-r toggles regular expression search indicated by "/RE"

rrg keybinds:
   exit                             alt-q        esc
   toggle pane                      alt-p
   show content in pane (default)   alt-o
   show result line in pane         alt-i
   start vim on matched line        alt-v           
   start less on matched line       alt-l
   start mcedit on matched line     f4
   start mcview on file             f3
   read all matches in file         enter

When piped, the limit of 100000 results is lifted and results are listed
as filenames only for further processing.

=== rrg-in-file usage ===

rrg-in-file -f FILE PATTERN

Same search engine as rrg, but shows all matches in specified file.

For more help, see
   rrg-in-file --help

" | less --clear-screen '-Ps rrg help | less - q to quit, h for help $'
end
