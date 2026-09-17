function ppage-if-much -d \
	'Print stdin as-is if it fits within $LINES, otherwise page it through ppage'
	ppage --quit-if-one-screen
end
