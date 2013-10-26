#!/bin/bash

output_file=innodb.log
> ${output_file}

for ts in $(ls *-top | cut -d "-" -f 1)
do
    echo "--- TS: $ts" >> ${output_file}
    thd_concurrency=$(grep -w innodb_thread_concurrency ${ts}-variables | awk '{print $2}')
    
    echo "- innodb_thread_concurrency: $thd_concurrency" >> ${output_file}
    echo "- Mutex at:" >> ${output_file}
    grep "Mutex at" ${ts}-innodbstatus1 | cut -d "," -f 1 | sort | uniq -c | sort -nr >> ${output_file}

    echo "- Lock on:" >> ${output_file}
    grep "lock on" ${ts}-innodbstatus1 | cut -d "-" -f2- | sort | uniq -c | sort -nr >> ${output_file}

    echo "- Has waited at:" >> ${output_file}
    grep "has waited at " ${ts}-innodbstatus1 | awk '{print $6" "$7" "$8}' | sort | uniq -c | sort -nr >> ${output_file}

    echo "- Last time write locked:" >> ${output_file}
    grep "Last time write locked " ${ts}-innodbstatus1 | sort | uniq -c | sort -nr >> ${output_file}

    echo >> ${output_file}
done
