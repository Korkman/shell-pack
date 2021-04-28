#! /usr/bin/env -S fish -c qmount

# quick mount - mkdir and mount and cd and ls
function qmount
  if test "$argv[1]" = ""
    echo "qmount will create /run/q/[device name], mount and cd there"
    echo "arg #1: device name (without /dev) required"
    return 1
  end
  
  if test "$argv[2]" != ""
    echo "no more than 1 argument allowed"
    return 1
  end

  set -l devdisk $argv[1]

  if not blkid /dev/$devdisk
    echo "/dev/$devdisk is not recognized by blkid"
    return $status
  end

  mkdir -p /run/q/$devdisk
  and mount /dev/$devdisk /run/q/$devdisk
  and cd /run/q/$devdisk
  and ls -al
end
