# Completion for the onman function

complete -c onman -f

complete -c onman -s h -l help -d "Show usage"
complete -c onman -l debug -d "Print each URL attempted to stderr"
complete -c onman -s t -l txt -d "Force plain-text URLs (skip roff sources)"
complete -c onman -l text -d "Force plain-text URLs (skip roff sources)"
complete -c onman -l roff -d "Force roff URLs (skip plain-text sources)"
complete -c onman -l html -d "Include browser-accessible HTML URLs"
complete -c onman -l urls -d "Print all candidate URLs and exit"
complete -c onman -l os -x -d "Override OS type (e.g. Linux, Darwin, FreeBSD)" -a "Linux Darwin FreeBSD NetBSD OpenBSD"
complete -c onman -l os-id -x -d "Override OS ID from os-release (e.g. debian, arch, alpine)"
complete -c onman -l os-version-id -x -d "Override VERSION_ID from os-release (e.g. 15, 43, 3.23)"
complete -c onman -l os-codename -x -d "Override VERSION_CODENAME from os-release (e.g. bookworm, noble)"
complete -c onman -l refresh -d "Refresh cache"
complete -c onman -l renderer -x -d "Force which tool renders roff man pages" -a "man mandoc groff"

# reuse fish's own man-page/section completion for the [section] <page> arguments
complete -c onman -a '(__fish_complete_man)'
