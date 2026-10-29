function __sp_td_subcommands -d \
	"List td-* subcommands, used for both completion and the td usage text"
	for fn in (functions -a)
		if string match -q 'td-*' -- $fn
			string replace -r '^td-' '' -- $fn
		end
	end
end
