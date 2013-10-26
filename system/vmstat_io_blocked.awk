#!/usr/bin/env awk -f

BEGIN {
    avg_blocked=0; 
    io_blocked_per=0;
    num_io_blocked_100_per=0;
    num_samples=0; 
    sum_io_blocked_per=0;
} 

!/procs|swpd/ {
    if ( $1 != 0 ) {
        num_samples++; 
        io_blocked_per = $2 * 100 / $1; 
        sum_io_blocked_per += io_blocked_per;

        if ( io_blocked_per >= 100 ) {
            num_io_blocked_100_per++;
        } 

        #printf "Percentage of requests blocked on IO: %3.2f\n", io_blocked_per; 
    }
} 

END { 
    avg_blocked = sum_io_blocked_per / num_samples; 
    printf "Number of samples: %6d\n", num_samples;
    printf "Avg percentage of requests blocked on IO: %3.2f\n", avg_blocked;
    printf "100 percent of requests were blocked on IO %d times\n", num_io_blocked_100_per;
}
