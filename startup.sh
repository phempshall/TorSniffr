#!/bin/bash

set -m

#starman -E production --port 8080 TorSniffr/bin/app.psgi &
#starman -E production --listen :8080 --workers 2 --max-requests 100 --disable-keepalive --error-log /var/log/starman.log --preload-app TorSniffr/bin/app.psgi &
starman -E development --listen :8080 --workers 2 --max-requests 100 --disable-keepalive --preload-app TorSniffr/bin/app.psgi &

tor

fg %1