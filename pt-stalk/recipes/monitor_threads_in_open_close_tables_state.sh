#!/bin/bash

trg_plugin() {
        mysqladmin $EXT_ARGV ping &> /dev/null
        mysqld_alive=$?

        if [[ $mysqld_alive == 0 ]]
        then
                num_open_close_tables_state=$(mysql $EXT_ARGV -NB -e "select count(*) from PROCESSLIST where state in ('Opening tables', 'closing tables')" -A information_schema)
                echo $num_open_close_tables_state
        else
                echo 1
        fi
}

# Uncomment below to test that trg_plugin function works as expected
# trg_plugin

# Usage
# /usr/bin/pt-stalk \
#    --function=/root/pt-plug.sh \
#    --variable=thread_state_open_or_close_tables \
#    --threshold=100 \
#    --cycles=15 \
#    --notify-by-email=ovais.tariq@percona.com \
#    --log=/root/pt-stalk.log \
#    --pid=/root/pt-stalk.pid \
#    --daemonize
