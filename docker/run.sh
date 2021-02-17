#!/bin/bash
nginx && \
/root/.cabal/bin/request2 -c /srv/config/request2.cfg create-db && \
exec /root/.cabal/bin/request2 -c /srv/config/request2.cfg run-server
