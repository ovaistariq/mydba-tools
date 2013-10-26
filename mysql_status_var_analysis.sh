#!/bin/bash

mysql_status_var=$1

if [[ -z $mysql_status_var ]]
then
    echo "Please provide a MySQL status variable name to run the analysis on"
    exit 1
fi

echo "--- Analyzing variable $mysql_status_var"

for f in *-mysqladmin
do
    ts=$(echo $f | cut -d "-" -f 1)
    echo "-- $mysql_status_var on timestamp: $ts"

    #awk -f variable_distribution.awk $f
    awk "BEGIN {
        y=0;
        x=0;
        SUM=0;
        count=0;
    }

    /$mysql_status_var/ {
        y=x; 
        x=\$4; 
                
        if (count > 0 ) { 
            diff = x - y;
            SUM = SUM + diff;
            printf \"%d \t\", diff;
        }   

        count++;
    } 
    
    END {
        printf \"\nAvg per second: %.2f\n\", SUM/(count-1)
    }" $f

    echo
done

