#!/usr/bin/env awk -f

BEGIN {
    y=0;
    x=0;
    SUM=0;
    count=0;
}

/Opened_tables/ {
    y=x; 
    x=$4; 
        
    if (count > 0 ) {
        diff = x - y;
        SUM = SUM + diff;
        printf "%d \t", diff;
    }

    count++;
} 
    
END {
    printf "\nAvg per second: %.2f\n", SUM/(count-1)
}
