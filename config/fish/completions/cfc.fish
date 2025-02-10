# Completion for the cfc function
function __sp_complete_cfc_first_arg_is_dir
    set -l tokens (commandline --current-process --cut-at-cursor --tokenize)
    if test "$tokens[2]" != "" && test -d "$tokens[2]"
        return 0
    else
        return 1
    end
end

function __sp_complete_cfc_first_arg_is_file
    set -l tokens (commandline --current-process --cut-at-cursor --tokenize)
    if test "$tokens[2]" != "" && test -f "$tokens[2]"
        return 0
    else
        return 1
    end
end

complete -c cfc -d 'Compressed file creation'
complete -c cfc -n '__sp_complete_cfc_first_arg_is_dir' -f -a 'tar tar.gz taz tgz tar.xz txz tar.zst tzst tar.bz2 tb2 tbz tbz2 tz2 tar.lz4 tar.lz tar.lzma tlz tar.lzo tar.Z tZ taZ'
complete -c cfc -n '__sp_complete_cfc_first_arg_is_file' -f -a 'gz xz bz2 zst 7z zip lz4 lz lzma lzo Z'
