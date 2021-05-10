function __update_glyphs -S -d "Sets glyphs in the scope of the calling function"
	set right_arrow_glyph \uE0B1
	set left_arrow_glyph \uE0B3
	set right_black_arrow_glyph \uE0B0
	set left_black_arrow_glyph \uE0B2
	set happy_glyph \uF42E''
	set unhappy_glyph \uF467''
	set running_glyph \uE213
	set lock_glyph ''
	set lock_glyph \uE0A2
	set bookmark_glyph \uF041' '
	#set bookmark_glyph \uf461' '
	set tag_glyph \uF412' '
	set white_black_forward_block \uE0BA' '
	set black_white_forward_block \uE0BC' '
	set white_black_backward_block \uE0BE' '
	set black_white_backward_block \uE0B8' '
	set home_glyph \uF7DD
	set deleted_glyph 'ﰸ'

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
