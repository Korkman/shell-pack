function td-test-cfc -d \
	"Run a short automated test suite for cfc and cfd"
	argparse 'h/help' 'p/partial' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-cfc [--partial]"
		echo
		echo "  Round-trips data through cfc and cfd in a temporary directory,"
		echo "  covering files, directories, stdin / stdout and '-' arguments, binary data,"
		echo "  help and error exit statuses and removal of cfd's temporary files."
		echo "  Returns the number of failed checks (max 125)."
		echo
		echo "  By default all compression tools must be installed, except compress (.Z),"
		echo "  which is optional. With -p / --partial, formats whose tools are missing"
		echo "  are skipped instead (gzip is still required)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	# prints the tools among the arguments which are not installed or lack the needed features
	# (busybox lzma only decompresses)
	function __td_missing_tools
		for tool in $argv
			switch $tool
				case 7z
					not command -q 7z; and not command -q 7zz; and not command -q 7za; and not command -q 7zr; and echo 7z
				case lzma
					if not command -q lzma; or not printf x | lzma -c >/dev/null 2>&1
						echo "lzma (compressing)"
					end
				case '*'
					command -q $tool; or echo $tool
			end
		end
	end

	# prints the tools cfc and cfd need for a format
	function __td_fmt_tools
		set -l base $argv[1]
		switch $base
			case taz tgz; set base tar.gz
			case tzst; set base tar.zst
			case tb2 tbz tbz2 tz2; set base tar.bz2
			case tlz; set base tar.lzma
			case txz; set base tar.xz
			case tZ taZ; set base tar.Z
			case sqfs; set base squashfs
		end
		set -l tools
		if test $base = tar
			echo tar
			return
		else if test $base = cpio
			echo cpio
			return
		else if string match -q 'tar.*' -- $base
			set base (string replace 'tar.' '' -- $base)
			set tools tar
		else if string match -q 'cpio.*' -- $base
			set base (string replace 'cpio.' '' -- $base)
			set tools cpio
		end
		switch $base
			case gz; set -a tools gzip gunzip
			case bz2; set -a tools bzip2
			case lz; set -a tools lzip
			case lzma; set -a tools lzma
			case lzo; set -a tools lzop
			case xz; set -a tools xz
			case Z; set -a tools compress
			case lz4; set -a tools lz4
			case zst; set -a tools zstd
			case br; set -a tools brotli
			case zip; set -a tools zip unzip
			case 7z; set -a tools 7z
			case squashfs; set -a tools mksquashfs unsquashfs
		end
		printf '%s\n' $tools
	end

	# every tool cfc / cfd can use, so that all formats get tested; compress (.Z) is optional
	# because it is not shipped by default on all systems, e.g. Alpine, and its formats are skipped
	set -l all_tools tar gzip gunzip bzip2 xz lzma zstd lzip lzop lz4 brotli cpio zip unzip mksquashfs unsquashfs 7z file script
	set -l missing (__td_missing_tools $all_tools)
	if set -q _flag_partial
		set -l hard (__td_missing_tools gzip)
		if test (count $hard) -gt 0
			echo "td test-cfc: missing binaries needed even with --partial: $hard" >&2
			functions -e __td_missing_tools __td_fmt_tools
			return 1
		end
	else if test (count $missing) -gt 0
		echo "td test-cfc: missing required binaries: $missing" >&2
		echo "Install everything in one go with:" >&2
		echo "  apt:  apt install tar gzip bzip2 xz-utils zstd lzip lzop lz4 brotli ncompress cpio zip unzip p7zip-full squashfs-tools file bsdutils" >&2
		echo "  apk:  apk add tar gzip bzip2 xz zstd lzip lzop lz4 brotli ncompress cpio zip unzip 7zip squashfs-tools file util-linux-misc" >&2
		echo "Or run with --partial to skip formats whose tools are missing." >&2
		functions -e __td_missing_tools __td_fmt_tools
		return 1
	end

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-test-cfc)
	or return 1
	pushd "$tmp"; or return 1
	mkdir runtime; or return 1
	set -lx XDG_RUNTIME_DIR "$tmp/runtime"
	set -g __td_test_failed 0
	set -g __td_test_total 0
	set -g __td_test_skipped 0

	printf 'hello\n' > a.txt
	printf 'dashed\n' > ./-d.txt
	mkdir -p dir/sub
	printf 'inner\n' > dir/sub/i.txt

	# usage: __td_check DESCRIPTION EXPECTED ACTUAL
	function __td_check
		set -g __td_test_total (math $__td_test_total + 1)
		if test "$argv[2]" = "$argv[3]"
			echo "ok     $argv[1]"
		else
			set -g __td_test_failed (math $__td_test_failed + 1)
			echo "FAILED $argv[1]: expected '$argv[2]', got '$argv[3]'"
		end
	end

	# usage: __td_skip DESCRIPTION MISSING_TOOLS...
	function __td_skip
		set -g __td_test_skipped (math $__td_test_skipped + 1)
		echo "skip   $argv[1] (missing: $argv[2..-1])"
	end

	# cfc only writes to a named file when stdout is a terminal, emulated with script
	function __td_cfc_to_file
		script -qec "cfc $argv[1] $argv[2]" /dev/null >/dev/null 2>&1
	end

	set -l file_formats gz bz2 lz lzma lzo xz Z lz4 zst br
	set -l magic_formats gz bz2 lz lzma lzo xz lz4 zst
	set -l tar_formats tar tar.gz taz tgz tar.zst tzst tar.bz2 tb2 tbz tbz2 tz2 tar.lz tar.lzma tlz tar.lzo tar.lz4 tar.br tar.xz txz tar.Z tZ taZ
	set -l cpio_formats cpio cpio.gz cpio.zst cpio.bz2 cpio.xz cpio.lz cpio.lzma cpio.lzo cpio.lz4 cpio.br cpio.Z
	set -l other_dir_formats zip 7z squashfs sqfs

	# single file compressors: file and stdin sources, via stdout
	for fmt in $file_formats
		set -l miss (__td_missing_tools (__td_fmt_tools $fmt))
		if test (count $miss) -gt 0
			__td_skip "single file round trip ($fmt)" $miss
			continue
		end
		cfc a.txt $fmt > a.out.$fmt 2>/dev/null
		__td_check "file to stdout, cfd by extension ($fmt)" hello (cfd a.out.$fmt - 2>/dev/null)
		printf 'hello\n' | cfc - $fmt - > s.out.$fmt 2>/dev/null
		__td_check "stdin to stdout, cfd by extension ($fmt)" hello (cfd s.out.$fmt - 2>/dev/null)
	end
	for fmt in $magic_formats
		set -l miss (__td_missing_tools file (__td_fmt_tools $fmt))
		if test (count $miss) -gt 0
			__td_skip "stdin magic detection ($fmt)" $miss
			continue
		end
		__td_check "stdin | cfc - $fmt - | cfd - (magic)" hello (printf 'hello\n' | cfc - $fmt - 2>/dev/null | cfd - 2>/dev/null)
	end

	# directory archivers: compress to a named file, extract, compare content
	for fmt in $tar_formats $other_dir_formats
		set -l miss (__td_missing_tools script (__td_fmt_tools $fmt))
		if test (count $miss) -gt 0
			__td_skip "directory round trip ($fmt)" $miss
			continue
		end
		__td_cfc_to_file dir dir-$fmt.$fmt
		mkdir x-$fmt
		cfd dir-$fmt.$fmt x-$fmt >/dev/null 2>&1
		__td_check "directory round trip ($fmt)" inner (cat x-$fmt/dir/sub/i.txt 2>/dev/null)
	end

	# compressed cpio is decompressed by cfd to a plain cpio first, which is then extracted
	for fmt in $cpio_formats
		set -l miss (__td_missing_tools script (__td_fmt_tools $fmt) gzip gunzip)
		if test (count $miss) -gt 0
			__td_skip "directory round trip ($fmt)" $miss
			continue
		end
		__td_cfc_to_file dir dir-$fmt.$fmt
		mkdir x-$fmt
		if test $fmt = cpio
			cfd dir-$fmt.$fmt x-$fmt >/dev/null 2>&1
		else
			cfd dir-$fmt.$fmt plain-$fmt.cpio >/dev/null 2>&1
			cfd plain-$fmt.cpio x-$fmt >/dev/null 2>&1
		end
		__td_check "directory round trip ($fmt)" inner (cat x-$fmt/dir/sub/i.txt 2>/dev/null)
	end

	# cfd detects the format of stdin by magic, which needs file
	set -l miss (__td_missing_tools file)
	if test (count $miss) -gt 0
		__td_skip "stdin | cfc | cfd - (default format)" $miss
		__td_skip "stdin | cfc - - (explicit dashes)" $miss
	else
		__td_check "stdin | cfc | cfd - (default format)" hello (printf 'hello\n' | cfc 2>/dev/null | cfd - 2>/dev/null)
		__td_check "stdin | cfc - - (explicit dashes)" hello (printf 'hello\n' | cfc - - 2>/dev/null | cfd - 2>/dev/null)
	end

	# compressor args after --
	__td_check "compressor args pass through" hello (cfc a.txt gz -- -1 2>/dev/null | gzip -dc)
	cfc a.txt gz -- --bogus-option >/dev/null 2>&1
	__td_check "invalid compressor args fail" 1 $status

	# directories
	set -l miss (__td_missing_tools tar)
	if test (count $miss) -gt 0
		__td_skip "directory to stdout as tar.gz" $miss
		__td_skip "cfd extracts directory archive" $miss
	else
		__td_check "directory to stdout as tar.gz" sub/i.txt (cfc dir tar.gz 2>/dev/null | tar tz | string match 'dir/sub/i.txt' | string replace 'dir/' '')
		mkdir out-dir
		cfc dir tar.gz > dir.tar.gz 2>/dev/null
		cfd dir.tar.gz out-dir >/dev/null 2>&1
		__td_check "cfd extracts directory archive" inner (cat out-dir/dir/sub/i.txt 2>/dev/null)
	end

	# files named like options
	__td_check "file starting with a dash" dashed (cfc ./-d.txt gz 2>/dev/null | gzip -dc)
	__td_check "file starting with a dash, no ./" dashed (cfc -d.txt gz 2>/dev/null | gzip -dc)

	# cfd on files
	cfc a.txt gz > a.txt.gz 2>/dev/null
	__td_check "cfd FILE - (stdout)" hello (cfd a.txt.gz - 2>/dev/null)
	cfd a.txt.gz copy.txt >/dev/null 2>&1
	__td_check "cfd FILE DEST" hello (cat copy.txt 2>/dev/null)
	if test (count (__td_missing_tools file)) -gt 0
		__td_skip "cfd - FILE (stdin)" file
	else
		__td_check "cfd - FILE (stdin)" hello (cfd - < a.txt.gz 2>/dev/null)
	end
	__td_check "cfd --get-type" gz (cfd --get-type a.txt.gz 2>/dev/null)

	# refusals
	printf 'x\n' | cfc - tar.gz - >/dev/null 2>&1
	__td_check "archive format from stdin is refused" 1 $status
	printf 'x\n' | cfc - gz extra - >/dev/null 2>&1
	__td_check "too many arguments with -" 1 $status

	# help and error exit statuses
	cfc --help >/dev/null 2>&1
	__td_check "cfc --help exits 1" 1 $status
	cfd --help >/dev/null 2>&1
	__td_check "cfd --help exits 1" 1 $status
	cfd "$tmp/missing" - >/dev/null 2>&1
	__td_check "cfd rejects missing file" 1 $status
	cfd --get-type "$tmp/missing" >/dev/null 2>&1
	__td_check "cfd --get-type rejects missing file" 1 $status
	cfd - - </dev/null >/dev/null 2>&1
	__td_check "cfd rejects empty input" 1 $status
	printf 'not compressed\n' | cfd - - >/dev/null 2>&1
	__td_check "cfd rejects uncompressed input" 1 $status

	# binary data survives compression and decompression
	dd if=/dev/urandom bs=1024 count=256 of=random.bin 2>/dev/null
	cfc - gz < random.bin > random.bin.gz 2>/dev/null; and cfd - - < random.bin.gz > random.out 2>/dev/null; and cmp -s random.bin random.out
	__td_check "binary round trip via stdin and stdout" 0 $status
	cfd random.bin.gz - > random.out 2>/dev/null; and cmp -s random.bin random.out
	__td_check "binary decompression from file" 0 $status

	# a directory destination receives the output of stdin, named after stdin
	mkdir to-dir
	cfd - to-dir < random.bin.gz >/dev/null 2>&1; and cmp -s random.bin to-dir/stdin
	__td_check "cfd - DIR writes stdin output as stdin" 0 $status

	# file destination with stdin (needs a terminal on stdout, emulated with script)
	if test (count (__td_missing_tools script)) -gt 0
		__td_skip "stdin to file destination" script
	else
		printf 'piped\n' | script -qec "fish -c 'cfc - from-stdin.gz'" /dev/null >/dev/null 2>&1
		__td_check "stdin to file destination" piped (gzip -dc from-stdin.gz 2>/dev/null)
	end

	# cfd removes its temporary files
	__td_check "cfd temporary files removed" 0 (count (find "$tmp/runtime" -name 'cfd-head.*' -print))

	popd
	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed, $__td_test_skipped skipped"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total __td_test_skipped
	functions -e __td_check __td_cfc_to_file __td_skip __td_missing_tools __td_fmt_tools
	test $failed -gt 125; and set failed 125
	return $failed
end
