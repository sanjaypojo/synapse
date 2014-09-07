#!/bin/sh

export PATH=/usr/local/bin:$PATH
forever start -c coffee --spinSleepTime 6000 --minUptime 3000 /home/twiddly/synapse/production/src/app.coffee
