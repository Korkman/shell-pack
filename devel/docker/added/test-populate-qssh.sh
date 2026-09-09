#! /usr/bin/fish

timeout 1 qssh 127.1 &
timeout 1 qssh 127.2 &
timeout 1 qssh 127.3 &
wait
