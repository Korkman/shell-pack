function rrg-help
	PAGER="cat" cheat --fzf-query | read -zl fzf_query_help
	echo "
"(set_color brwhite --bold)"RAPID RIPGREP"(set_color normal)"
(rrg)

"(set_color brwhite --bold)"USAGE"(set_color normal)"
rrg PATTERN
rrg [ OPTIONS ...  ] -- PATTERN

Searches case-insensitive PATTERN in all non-binary files recursively.
All matches are shown. Results are shown in fzf, an interactive fuzzy
search engine. While the spinner is rotating more results may be
retrieved.

When piped, the limit of 100000 results is lifted and results are listed
as filenames only for further processing.

OPTIONS are passed to rg, but may be incompatible with rrg's usage.
Some useful examples:

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

Ripgrep PATTERN syntax is mostly PCRE compatible. For full syntax help, see

   rg --help | less

"(set_color brwhite --bold)"KEYS"(set_color normal)"
   exit                             q            alt-q     f10       esc
   clear query                      esc
   show blank filter input          space
   edit current filter              +
   hide query input                 enter
   toggle preview                   v            alt-v     right-click
   start pager on matched line      enter        f3        p          alt-p
   start editor on matched line     e            f4        alt-e
   show help                        h            f1        alt-h
   jump to start/end of filter      home         end

"(set_color brwhite --bold)"MATCHED LINES CAN BE FILTERED WITH"(set_color normal)"
$fzf_query_help
"(set_color brwhite --bold)"RRG-IN-FILE"(set_color normal)"
rrg-in-file -f FILE PATTERN

Same search engine as rrg, but shows all matches in specified file.

For more help on this, see
   rrg-in-file --help

" | __sp_pager --clear-screen --prompt "rrg help | less - q to quit, h for help"
end
