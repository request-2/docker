#!/bin/bash
umask 002
nginx && \
/usr/bin/request2 -c /srv/config/request2.cfg create-db && \
exec /usr/bin/request2 -c /srv/config/request2.cfg run-server
