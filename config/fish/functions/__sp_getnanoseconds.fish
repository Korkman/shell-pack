# this function will adapt to the local system and try to return precise time for measurements
# note that precision in fish scripts cannot be expected to be very high anyways, the function name
# might be a bit misleading. It is named after the date format parameter.
function __sp_getnanoseconds -d \
	'Get nanoseconds since epoch (self-redefining)'
	if date -u +%N | string match -q --regex '[0-9]{9}'
		# GNU date installed as "date"
		function __sp_getnanoseconds -d \
			'Get nanoseconds since epoch (detected "date" as GNU date)'
			date -u +%s%N
		end
		__sp_getnanoseconds
	else if command -sq gdate && gdate -u +%N | string match -q --regex '[0-9]{9}'
		# GNU date installed as "gdate"
		function __sp_getnanoseconds -d \
			'Get nanoseconds since epoch (detected "gdate" as GNU date)'
			gdate -u +%s%N
		end
		__sp_getnanoseconds
	else if command -sq python3
		# using python3 (µs precision)
		function __sp_getnanoseconds -d \
			'Get nanoseconds since epoch (detected python3, precision µs)'
			python3 -c 'import datetime; import time; print(str(int(time.time())) + datetime.datetime.now(datetime.UTC).strftime("%f") + "000")'
		end
		__sp_getnanoseconds
	else if command -sq python
		# using python (µs precision)
		function __sp_getnanoseconds -d \
			'Get nanoseconds since epoch (detected python, precision µs)'
			python -c 'import datetime; import time; print(str(int(time.time())) + datetime.datetime.utcnow().strftime("%f") + "000")'
		end
		__sp_getnanoseconds
	else
		# running out of ideas ...
		# TODO: be more creative on macOS
		function __sp_getnanoseconds -d \
			'Get nanoseconds since epoch (detected no compatible source, precision s)'
			date -u +%s000000000
		end
		__sp_getnanoseconds
	end
end
