function __update_glyphs -S -d "(obsolete, subject to removal, see __spt) Sets glyphs in the scope of the calling function"
	set right_arrow_glyph ''
	set left_arrow_glyph ''
	set right_black_arrow_glyph ''
	set left_black_arrow_glyph ''
	set happy_glyph ''
	set unhappy_glyph ''
	set running_glyph ''
	set lock_glyph ''
	set bookmark_glyph ' '
	set tag_glyph ' '
	set white_black_forward_block ''
	set black_white_forward_block ''
	set white_black_backward_block ''
	set black_white_backward_block ''
	set home_glyph '󰋞'
	set deleted_glyph ''

	if [ "$theme_powerline_fonts" = "no" ]
		set right_black_arrow_glyph  ''
		set left_black_arrow_glyph  ''
	end
	if [ "$theme_nerd_fonts" = "no" ]
		set happy_glyph ':-)'
		set unhappy_glyph ':-('
		set running_glyph 'jobs'
		set lock_glyph '!ro'
		set tag_glyph '#'
		set white_black_forward_block '██'
		set black_white_forward_block '  '
		set white_black_backward_block '██'
		set black_white_backward_block '  '
		set bookmark_glyph ''
		set home_glyph '~'
		set deleted_glyph '🛇'
	end
end
