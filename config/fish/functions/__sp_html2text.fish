function __sp_html2text --description "Render HTML to plain text using an available CLI renderer"
	argparse 'h/help' \
		'w/w3m' 'l/lynx' 'e/elinks' 'L/links' 'H/html2text' 'p/pandoc' 's/strip' \
		-- $argv
	or return

	if set -q _flag_help
		echo "__sp_html2text - render HTML to plain text

Uses the first available renderer from: w3m, lynx, elinks, links, html2text, pandoc.

Usage:
  __sp_html2text [options] <file>    render HTML file
  __sp_html2text [options] <url>     render URL (w3m/lynx/elinks/links only)
  cat file.html | __sp_html2text     render from stdin

Options:
  -h/--help                    show this help
  -w/--w3m                     use w3m
  -l/--lynx                    use lynx
  -e/--elinks                  use elinks
  -L/--links                   use links
  -H/--html2text               use html2text
  -p/--pandoc                  use pandoc
  -s/--strip                   strip HTML tags with sed (fallback, no rendering)
"
		return 0
	end

	# Determine forced renderer (flag shorthand wins over --renderer)
	set -l force_renderer ""
	if set -q _flag_w3m
		set force_renderer w3m
	else if set -q _flag_lynx
		set force_renderer lynx
	else if set -q _flag_elinks
		set force_renderer elinks
	else if set -q _flag_links
		set force_renderer links
	else if set -q _flag_html2text
		set force_renderer html2text
	else if set -q _flag_pandoc
		set force_renderer pandoc
	else if set -q _flag_strip
		set force_renderer strip
	end

	if test -n "$force_renderer"
		if test "$force_renderer" != strip; and not command -q $force_renderer
			__sp_error "__sp_html2text: requested renderer '$force_renderer' not found"
			return 1
		end
	end

	set -l input $argv[1]
	
	# Build ordered list of renderers to try
	set -l renderers
	if test -n "$force_renderer"
		set renderers $force_renderer
	else
		set renderers w3m lynx elinks links html2text pandoc strip
	end

	set -l renderer ""
	for r in $renderers
		if command -q $r
			set renderer $r
			break
		end
	end

	if test -z "$renderer"
		set renderer strip
	end
	
	echo (set_color --bold brwhite)'Rendered with:'(set_color normal)' '$renderer
	
	switch $renderer
	case w3m
		if test (count $argv) -eq 0
			set -l tmpfile (mktemp /tmp/html2text.XXXXXX.html)
			cat > $tmpfile
			w3m -dump -T text/html $tmpfile
			rm -f $tmpfile
		else
			w3m -dump -T text/html $input
		end
	case lynx
		if test (count $argv) -eq 0
			lynx -dump -nolist -stdin
		else
			lynx -dump -nolist -force_html $input
		end
	case elinks
		if test (count $argv) -eq 0
			set -l tmpfile (mktemp /tmp/__sp_html2text.XXXXXX.html)
			cat > $tmpfile
			elinks -no-numbering -no-references -dump $tmpfile
			rm -f $tmpfile
		else
			elinks -no-numbering -no-references -dump $input
		end
	case links
		if test (count $argv) -eq 0
			set -l tmpfile (mktemp /tmp/__sp_html2text.XXXXXX.html)
			cat > $tmpfile
			links -dump $tmpfile
			rm -f $tmpfile
		else
			links -dump $input
		end
	case html2text
		if test (count $argv) -eq 0
			html2text -style pretty
		else
			html2text -style pretty $input
		end
	case pandoc
		if test (count $argv) -eq 0
			__sp_clean_utf8 | pandoc -f html -t plain
		else
			__sp_clean_utf8 $input | pandoc -f html -t plain
		end
	case strip
		# naive fallback
		# - does not catch script and style sections which contain "<"
		set -l __sp_unescape_sed \
			-e 's/&lt;/</g' \
			-e 's/&gt;/>/g' \
			-e 's/&#x2022;/•/g' \
			-e 's/&#x2265;/≥/g' \
			-e 's/&#x2014;/—/g' \
			-e 's/&#8211;/–/g' \
			-e 's/&#x23AA;/⎪/g' \
			-e 's/&#x00A0;/ /g' \
			-e 's/&nbsp;/ /g' \
			-e 's/&quot;/"/g' \
			-e 's/&#x201C;/"/g' \
			-e 's/&#x201D;/"/g' \
			-e 's/&#8220;/"/g' \
			-e 's/&#8221;/"/g' \
			-e 's/&auml;/ä/g' \
			-e 's/&ouml;/ö/g' \
			-e 's/&uuml;/ü/g' \
			-e 's/&Auml;/Ä/g' \
			-e 's/&Ouml;/Ö/g' \
			-e 's/&Uuml;/Ü/g' \
			-e 's/&szlig;/ß/g' \
			-e 's/&amp;/\&/g' \
			-e 's/<br ?\/?>/\n/gi' \
			-e 's/<p[^>]*>/\n/gi' \
			-e '/^[[:space:]]*$/d' \
		;
		if test (count $argv) -eq 0
			__sp_clean_utf8
		else
			__sp_clean_utf8 $input
		end \
		  | sed \
			-e 's/<script[^>]*>[^<]*<\/script>//gI' \
			-e 's/<style[^>]*>[^<]*<\/style>//gI' \
			-e 's/<!--[^-]*\(-[^-][^-]*\)*-->//g' \
			-e '/<!--/,/-->/d' \
		  | tr '\n' '\001' \
		  | sed -e 's/<[^>]*>//g' \
		  | tr '\001' '\n' | sed $__sp_unescape_sed
	end
end
