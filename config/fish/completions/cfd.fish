# Completion for the cfc function
complete -c cfd -d 'Compressed file decompression'
complete -c cfd -F -a '(for file in *.gz *.bz2 *.xz *.lz4 *.zst *.7z *.zip; echo $file; end)'
