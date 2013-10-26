#!/bin/bash

trg_plugin() {
        mysqladmin $EXT_ARGV ping &> /dev/null
        mysqld_alive=$?

        if [[ $mysqld_alive == 0 ]]
        then
                wsrep_flow_control_paused_duration=$(mysql $EXT_ARGV -NB -e "SHOW STATUS LIKE 'wsrep_flow_control_paused'" | awk '{print $2}')
                echo "$wsrep_flow_control_paused_duration 0" | awk '{if ($1 > $2) print 2; else print $2}'
        else
                echo 1
        fi
}

# Uncomment below to test that trg_plugin function works as expected
# trg_plugin

# Usage
# /usr/bin/pt-stalk \
    #    --function=/root/pt-plug.sh \
    #    --variable=wsrep_flow_control_paused \
    #    --threshold=1 \
    #    --cycles=30 \
    #    --notify-by-email=ovais.tariq@percona.com \
    #    --log=/root/pt-stalk.log \
    #    --pid=/root/pt-stalk.pid \
    #    --daemonize

