#!/bin/bash

trg_plugin() {
    mysqladmin $EXT_ARGV ping &> /dev/null
    mysqld_alive=$?

    if [[ $mysqld_alive == 0 ]]
    then
        hanging_commit_sql="SELECT count(*) FROM PROCESSLIST WHERE INFO LIKE 'commit' and TIME > 1"
        num_hanging_commits=$(mysql $EXT_ARGV -NB -e "$hanging_commit_sql" information_schema)
        echo $num_hanging_commits
    else
        echo 1
    fi
}

# Uncomment below to test that trg_plugin function works as expected
# trg_plugin

# Usage
# /usr/bin/pt-stalk \
    #    --function=/root/pt-plug.sh \
    #    --variable=num_hanging_commits \
    #    --threshold=5 \
    #    --cycles=5 \
    #    --notify-by-email=ovais.tariq@percona.com \
    #    --log=/root/pt-stalk.log \
    #    --pid=/root/pt-stalk.pid \
    #    --daemonize
