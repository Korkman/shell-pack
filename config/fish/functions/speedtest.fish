function speedtest -d "Measure internet speed (download, upload, latency) using curl"
	set -l do_download yes
	set -l do_upload yes
	set -l do_latency yes
	set -l download_size 25000000  # 25 MB
	set -l upload_size 10000000    # 10 MB

	argparse 'd/download-only' 'u/upload-only' 'l/latency-only' 's/size=' h/help -- $argv
	or return 1

	if set -q _flag_help
		begin
			echo "Usage: speedtest [OPTIONS]"
			echo
			echo "Measure internet speed using Cloudflare's speed test servers."
			echo
			echo "Options:"
			echo "  -d, --download-only   Only test download speed"
			echo "  -u, --upload-only     Only test upload speed"
			echo "  -l, --latency-only    Only test latency"
			echo "  -s, --size=BYTES      Download test size in bytes (default: $download_size)"
			echo "  -h, --help            Show this help"
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
	if set -q _flag_size
		set download_size $_flag_size
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
		for i in (seq 1 3)
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

	# --- Download ---
	if test "$do_download" = yes
		printf "Download:  "
		set -l url "https://speed.cloudflare.com/__down?bytes=$download_size"
		set -l result (curl -o /dev/null -s -w '%{speed_download} %{time_total}' "$url" 2>/dev/null)
		if test $status -eq 0; and test -n "$result"
			set -l speed_bps (echo $result | awk '{print $1}')
			set -l duration (echo $result | awk '{print $2}')
			set -l speed_mbps (math "round($speed_bps * 8 / 1000000 * 100) / 100")
			set -l speed_mbs (math "round($speed_bps / 1000000 * 100) / 100")
			echo "$speed_mbps Mbit/s ($speed_mbs MB/s) in $duration s"
		else
			echo "failed"
		end
	end

	# --- Upload ---
	if test "$do_upload" = yes
		printf "Upload:    "
		set -l result (dd if=/dev/urandom bs=$upload_size count=1 2>/dev/null | curl -X POST -s -w '%{speed_upload} %{time_total}' --data-binary @- "https://speed.cloudflare.com/__up" -o /dev/null 2>/dev/null)
		if test $status -eq 0; and test -n "$result"
			set -l speed_bps (echo $result | awk '{print $1}')
			set -l duration (echo $result | awk '{print $2}')
			set -l speed_mbps (math "round($speed_bps * 8 / 1000000 * 100) / 100")
			set -l speed_mbs (math "round($speed_bps / 1000000 * 100) / 100")
			echo "$speed_mbps Mbit/s ($speed_mbs MB/s) in $duration s"
		else
			echo "failed"
		end
	end
end
