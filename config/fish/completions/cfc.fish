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
complete -c cfc -n '__sp_complete_cfc_first_arg_is_dir' -f -a 'tar tar.gz tar.xz tar.zst tar.bz2 tar.lz4'
complete -c cfc -n '__sp_complete_cfc_first_arg_is_file' -f -a 'gz xz bz2 zst 7z zip lz4'
