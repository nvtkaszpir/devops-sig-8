#!/bin/sh
# watch specific config forever in a loop if written
# exits immediately on detected change
inotifywait -e modify -e close_write -e create -e delete /etc/app/
# send SIGTERM to all processes
killall5 -15
