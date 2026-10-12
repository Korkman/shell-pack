function __sp_cd_tagged -d \
	"cd into tagged and history directories"
	begin
		echo 'enter:cd esc:abort f6/alt-r:rename f8/alt-d:delete'
		echo 'alt-up/k alt-down/j:move alt-pgup/K alt-pgdn/J:top/bottom'
	end | __sp_fzf_header
	set -l fzf_binds 'esc:cancel'
	
	__sp_fzf_defaults 'cd tagged directory'
	set -l fzf_args fzf $fzf_defaults --ansi --no-multi \
	--expect f6,alt-r,f8,alt-d,alt-up,alt-k,alt-page-up,alt-K,alt-down,alt-j,alt-page-down,alt-J
	
	set -l result
	set -l pos 1
	while true
		# --expect prints the pressed key (empty for enter), then the selected entry
		set -l out (begin
			lsdirtags
			set -l mentioned "$PWD" # dedup list
			for i in $dirnext
				if contains -- "$i" $mentioned; continue; end
				set -a mentioned "$i"
				echo ">:$i"
			end
			for i in $dirprev[-1..1]
				if contains -- "$i" $mentioned; continue; end
				set -a mentioned "$i"
				echo "<:$i"
			end
		end | command $fzf_args --bind "$fzf_binds,load:pos($pos)")
		set pos 1
		set -l key $out[1]
		set result $out[2]
		if test -z "$result"
			break
		end
		
		switch "$key"
			case f6 alt-r f8 alt-d
				set -l plain (string replace -ra '\e\[[^m]*m' '' -- "$result")
				set -l name (string replace --regex ':.*' '' -- "$plain")
				set -l tagdest (string replace --regex '.*?:' '' -- "$plain")
				# history entries are not tags
				if contains -- "$name" '>' '<'
					continue
				end
				if contains -- "$key" f8 alt-d
					untagdir "$tagdest"
				else
					read -P "rename '$name' to: " -c "$name" new_name
					and test -n "$new_name" -a "$new_name" != "$name"
					and tagdir "$tagdest" "$new_name"
				end
			case alt-up alt-k alt-page-up alt-K alt-down alt-j alt-page-down alt-J
				set -l tagdest (string replace -ra '\e\[[^m]*m' '' -- "$result" | string replace --regex '.*?:' '')
				set -l idx (contains --index -- "$tagdest" $__tagged_dirs_path_list)
				or continue # history entries are not tags
				set -l names $__tagged_dirs_name_list
				set -l paths $__tagged_dirs_path_list
				set -l n (count $names)
				set -l new $idx
				switch "$key"
					case alt-up alt-k
						set new (math "max($idx - 1, 1)")
					case alt-down alt-j
						set new (math "min($idx + 1, $n)")
					case alt-page-up alt-K
						set new 1
					case alt-page-down alt-J
						set new $n
				end
				set pos $new
				test $new -ne $idx; or continue
				set -l name $names[$idx]
				set -l path $paths[$idx]
				if test $new -eq 1 -o $new -eq $n; and test (math "abs($new - $idx)") -ne 1
					# jump to an end
					set -e names[$idx]
					set -e paths[$idx]
					if test $new -eq 1
						set names $name $names
						set paths $path $paths
					else
						set names $names $name
						set paths $paths $path
					end
				else
					# swap with neighbour
					set names[$idx] $names[$new]
					set paths[$idx] $paths[$new]
					set names[$new] $name
					set paths[$new] $path
				end
				set --universal __tagged_dirs_name_list $names
				set --universal __tagged_dirs_path_list $paths
				__sp_sync_tagdir_mc_hotlist
			case '*'
				break
		end
	end
	if [ -n "$result" ]
		set dest (string replace --regex '.*?:' '' -- "$result")
		# NOTE: while it is possible to navigate with prevd and nextd, it can be confusing when history is lost due to another cd
		#if string match --quiet --regex '^>' -- "$result" && set idx (contains --index $dest $dirnext[-1..1])
		#	nextd $idx
		#else
		cd -- "$dest"
		#end
	end
	commandline -f repaint
end
