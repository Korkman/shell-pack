function __sp_cheat_fzf_query
	echo "
fzf query syntax

Case-insensitive unless uppercase letters are used.

Token    Match type
─────    ──────────
sbtrkt   fuzzy match: contains chars in that order
         (--exact changes this to exact match)
'wild    exact match: contains 'wild'
         (--exact changes this to fuzzy match)
'wild'   exact word match: finds 'wild' as word
^music   prefix exact match: starts with 'music'
.mp3\$    suffix exact match: ends with '.mp3'
!fire    inverse exact match: does not contain 'fire'
!^music  inverse prefix match: does not start with 'music'
!.mp3\$   inverse suffix match: does not end with '.mp3'

Escape spaces with backslash:
  'foo\ bar   matches 'foo bar' exactly
  !foo\ bar   inverse exact match 'foo bar'

Combine tokens by separating with spaces (AND):
  ^core go\$     starts with 'core' AND ends with 'go'

Use | for OR:
  ^core | go\$   starts with 'core' OR ends with 'go'
" | __sp_pager --prompt "cheat --fzf-query | less - q to quit, h for help"
end
