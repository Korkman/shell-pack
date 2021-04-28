#! /usr/bin/env -S fish -c ssmart

# super smartctl
function ssmart
  if test "$argv[1]" = ""
    echo "ssmart will 'smartctl -x | less' for a device name"
    echo "set env like this for additional params: SSMART_EXTRA='-d sat'"
    echo "arg #1: device name (without /dev) required"
    return 1
  end
  
  if test "$argv[2]" != ""
    echo "no more than 1 argument allowed"
    return 1
  end
  smartctl $SSMART_EXTRA -x /dev/$argv[1] | less
end
