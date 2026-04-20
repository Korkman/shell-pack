#!/usr/bin/env fish
# completions for the `speedtest` function
# Generated to provide completions for flags used by config/fish/functions/speedtest.fish

complete -c speedtest -s d -l download-only -d "Only test download speed"
complete -c speedtest -s u -l upload-only -d "Only test upload speed"
complete -c speedtest -s l -l latency-only -d "Only test latency"
complete -c speedtest -s t -l time -r -d "Time limit per direction (seconds)"
complete -c speedtest -s s -l start-size -r -d "Initial chunk size in bytes"
complete -c speedtest -s h -l help -d "Show help"
