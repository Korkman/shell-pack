# Completion for the cfc function
# first positional argument, skipping options like -f; a lone dash is kept (stdin)
function __sp_complete_cfc_first_arg
    set -l tokens (commandline --current-process --cut-at-cursor --tokenize)
    for token in $tokens[2..-1]
        if test "$token" = "--"
            return 1
        else if test "$token" = "-"; or not string match -q -- '-*' "$token"
            echo "$token"
            return 0
        end
    end
    return 1
end

function __sp_complete_cfc_first_arg_is_dir
    set -l first (__sp_complete_cfc_first_arg)
    test -n "$first" && test -d "$first"
end

function __sp_complete_cfc_first_arg_is_file
    set -l first (__sp_complete_cfc_first_arg)
    test -n "$first" && begin; test -f "$first"; or test "$first" = "-"; end
end

function __sp_complete_cfc_no_arg_yet
    not __sp_complete_cfc_first_arg >/dev/null
end

function __sp_complete_cfc_has_arg
    __sp_complete_cfc_first_arg >/dev/null
end

complete -c cfc -d 'Compressed file creation'
complete -c cfc -n '__sp_complete_cfc_no_arg_yet' -f -a "(printf '%s\\t%s\\n' - 'Read data from stdin')"
complete -c cfc -n '__sp_complete_cfc_has_arg' -f -a "(printf '%s\\t%s\\n' - 'Write data to stdout')"
complete -c cfc -n '__sp_complete_cfc_first_arg_is_dir' -f -a 'tar tar.gz taz tgz tar.xz txz tar.zst tzst tar.bz2 tb2 tbz tbz2 tz2 tar.lz4 tar.lz tar.lzma tlz tar.lzo tar.br tar.Z tZ taZ squashfs sqfs cpio cpio.gz cpio.zst cpio.bz2 cpio.xz cpio.lz cpio.lzma cpio.lzo cpio.lz4 cpio.br cpio.Z'
complete -c cfc -n '__sp_complete_cfc_first_arg_is_file' -f -a 'gz xz bz2 zst 7z zip lz4 lz lzma lzo br Z'
complete -c cfc -s f -l force -f -d 'Overwrite existing destination without asking'
