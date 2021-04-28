#! /usr/bin/env -S fish -c qumount

function qumount
  if test "$argv[1]" = ""
    echo "arg #1: device name (without /dev) required, may be '*' to umount all qmounts"
    return 1
  end
  
  if test "$argv[2]" != ""
    echo "no more than 1 argument allowed"
    return 1
  end
  cd /run/q
  umount /run/q/$argv[1]
end

