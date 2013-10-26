#!/bin/bash

trg_plugin() {
        mysqladmin $EXT_ARGV ping &> /dev/null
        mysqld_alive=$?

        if [[ $mysqld_alive == 0 ]]
        then
                seconds_behind_master=$(mysql $EXT_ARGV -e "show slave status" --vertical |  grep Seconds_Behind_Master | awk '{print $2}')
                echo $seconds_behind_master
        else
                echo 1
        fi
}

# Uncomment below to test that trg_plugin function works as expected
# trg_plugin

# Usage
# /usr/bin/pt-stalk \
#    --function=/root/pt-plug.sh \
#    --variable=seconds_behind_master \
#    --threshold=150 \
#    --cycles=30 \
#    --notify-by-email=ovais.tariq@percona.com \
#    --log=/root/pt-stalk.log \
#    --pid=/root/pt-stalk.pid \
#    --daemonize
