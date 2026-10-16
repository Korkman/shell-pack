# Completion for the cfd function

# number of positional arguments before the cursor, ignoring options; a lone dash counts
function __sp_complete_cfd_positionals
    set -l count 0
    for token in (commandline --current-process --cut-at-cursor --tokenize)[2..-1]
        if test "$token" = "-"; or not string match -q -- '-*' "$token"
            set count (math $count + 1)
        end
    end
    echo $count
end

function __sp_complete_cfd_no_arg_yet
    test (__sp_complete_cfd_positionals) -eq 0
end

function __sp_complete_cfd_second_arg
    test (__sp_complete_cfd_positionals) -eq 1; and not __fish_seen_argument -l get-type
end

complete -c cfd -f -d 'Compressed file decompression'
complete -c cfd -n '__sp_complete_cfd_no_arg_yet' -F -a '(for file in *.gz *.bz2 *.xz *.lz4 *.zst *.br *.7z *.zip *.tar *.tb2 *.tbz *.tbz2 *.tz2 *.taz *.tgz *.tlz *.txz *.tZ *.taZ *.tzst *.lz *.lzma *.lzo *.Z *.cpio *.squashfs *.sqfs; echo $file; end)'
complete -c cfd -n '__sp_complete_cfd_no_arg_yet' -f -a "(printf '%s\\t%s\\n' - 'Read data from stdin')"
complete -c cfd -n '__sp_complete_cfd_second_arg' -f -a '(__fish_complete_directories)'
complete -c cfd -n '__sp_complete_cfd_second_arg' -f -a "(printf '%s\\t%s\\n' - 'Write data to stdout')"
complete -c cfd -s h -l help -d 'Show help'
complete -c cfd -l get-type -d 'Print detected format and exit'
complete -c cfd -l deep -d 'With --get-type, also use file magic detection'
