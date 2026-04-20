function _speedtest_measure -d "Run one bandwidth direction; args: direction(download|upload) time_limit start_size"
	set -l direction $argv[1]
	set -l time_limit $argv[2]
	set -l start_size $argv[3]

	set -l chunk_bytes
	set -l chunk_times
	set -l size $start_size
	set -l elapsed_ms 0
	set -l limit_ms (math -s0 "$time_limit * 1000")

	while test $elapsed_ms -lt $limit_ms
		if test "$direction" = download
			set -l url "https://speed.cloudflare.com/__down?bytes=$size"
			set -l result (curl -o /dev/null -s -w '%{size_download} %{time_total}' "$url" 2>/dev/null)
			if test $status -ne 0; or test -z "$result"
				break
			end
			set -a chunk_bytes (echo $result | awk '{print $1}')
			set -a chunk_times (echo $result | awk '{print $2}')
		else
			set -l result (dd if=/dev/urandom bs=$size count=1 2>/dev/null | curl -X POST -s -w '%{size_upload} %{time_total}' --data-binary @- "https://speed.cloudflare.com/__up" -o /dev/null 2>/dev/null)
			if test $status -ne 0; or test -z "$result"
				break
			end
			set -a chunk_bytes (echo $result | awk '{print $1}')
			set -a chunk_times (echo $result | awk '{print $2}')
		end
		set elapsed_ms (math -s0 "$elapsed_ms + $chunk_times[-1] * 1000")
		set size (math "$size * 2")
	end

	set -l iterations (count $chunk_bytes)
	if test $iterations -eq 0
		echo "failed"
		return
	end

	# Compute bandwidth from the last 3 chunks to counter latency distortion
	set -l window 3
	if test $iterations -lt 3
		set window $iterations
	end
	set -l start_idx (math "$iterations - $window + 1")
	set -l win_bytes 0
	set -l win_time 0
	for i in (seq $start_idx $iterations)
		set win_bytes (math "$win_bytes + $chunk_bytes[$i]")
		set win_time (math "$win_time + $chunk_times[$i]")
	end

	if test (math -s0 "$win_time * 1000") -eq 0
		echo "failed"
		return
	end

	set -l speed_bps (math "$win_bytes / $win_time")
	set -l speed_mbps (math "round($speed_bps * 8 / 1000000 * 100) / 100")
	set -l speed_mbs (math "round($speed_bps / 1000000 * 100) / 100")
	set -l total_bytes 0
	for b in $chunk_bytes
		set total_bytes (math "$total_bytes + $b")
	end
	set -l total_time 0
	for t in $chunk_times
		set total_time (math "$total_time + $t")
	end
	set -l mb (math "round($total_bytes / 1000000 * 100) / 100")
	set -l t (math "round($total_time * 100) / 100")
	echo "$speed_mbps Mbit/s ($speed_mbs MB/s) — $mb MB in $t s (estimated from $window of $iterations chunks)"
end

function speedtest -d "Measure internet speed (download, upload, latency) using curl"
	set -l do_download yes
	set -l do_upload yes
	set -l do_latency yes
	set -l time_limit 2          # seconds per direction
	set -l start_size 65536      # initial chunk size 64K

	argparse 'd/download-only' 'u/upload-only' 'l/latency-only' 't/time=' 's/start-size=' h/help -- $argv
	or return 1

	if set -q _flag_help
		begin
			echo "Usage: speedtest [OPTIONS]"
			echo
			echo "Measure internet speed using Cloudflare's speed test servers."
			echo "Download and upload loop with doubling chunk sizes until the"
			echo "time limit is reached, then bandwidth is computed from the"
			echo "last 3 chunks to counter latency distortion."
			echo
			echo "Options:"
			echo "  -d, --download-only     Only test download speed"
			echo "  -u, --upload-only       Only test upload speed"
			echo "  -l, --latency-only      Only test latency"
			echo "  -t, --time=SECONDS      Time limit per direction (default: $time_limit)"
			echo "  -s, --start-size=BYTES  Initial chunk size (default: $start_size)"
			echo "  -h, --help              Show this help"
		end >&2
		return 0
	end

	if set -q _flag_download_only
		set do_upload no
		set do_latency no
	end
	if set -q _flag_upload_only
		set do_download no
		set do_latency no
	end
	if set -q _flag_latency_only
		set do_download no
		set do_upload no
	end
	if set -q _flag_time
		set time_limit $_flag_time
	end
	if set -q _flag_start_size
		set start_size $_flag_start_size
	end

	if ! command -q curl
		echo "Error: curl is required but not found" >&2
		return 1
	end

	echo "Speedtest via Cloudflare"
	echo "========================"
	echo

	# --- Latency ---
	if test "$do_latency" = yes
		printf "Latency:   "
		set -l times
		for i in (seq 1 5)
			set -l t (curl -o /dev/null -s -w '%{time_connect}' https://speed.cloudflare.com/__down?bytes=0 2>/dev/null)
			if test $status -eq 0; and test -n "$t"
				set -a times $t
			end
		end
		if test (count $times) -gt 0
			set -l sum 0
			for t in $times
				set sum (math "$sum + $t")
			end
			set -l avg (math "$sum / "(count $times))
			set -l ms (math "round($avg * 1000 * 100) / 100")
			echo "$ms ms (avg of "(count $times)" pings)"
		else
			echo "failed"
		end
	end

	# --- Download / Upload ---
	if test "$do_download" = yes
		printf "Download:  "
		_speedtest_measure download $time_limit $start_size
	end
	if test "$do_upload" = yes
		printf "Upload:    "
		_speedtest_measure upload $time_limit $start_size
	end
end
