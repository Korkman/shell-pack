# Completion for the cfc function
complete -c cfd -d 'Compressed file decompression'
complete -c cfd -F -a '(for file in *.gz *.bz2 *.xz *.lz4 *.zst *.7z *.zip *.tar *.tb2 *.tbz *.tbz2 *.tz2 *.taz *.tgz *.tlz *.txz *.tZ *.taZ *.tzst *.lz *.lzma *.lzo *.Z; echo $file; end)'
