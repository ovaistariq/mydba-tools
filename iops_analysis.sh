#!/usr/bin/env bash

diskstats_file=$1

if [[ -z $diskstats_file ]]
then
        echo "Please provide the path to the diskstats file to analyze"
        exit 1
fi

for dev in xvdf xvdg xvdh xvdi
do
        echo "- Stats for $dev"

        /usr/bin/pt-diskstats $diskstats_file --devices-regex="${dev}\$" | /usr/bin/awk "
                BEGIN { 
                        total_iops = 0;
                        avg_iops = 0;
                        num_samples = 0;
                        max_iops = 0;
                }

                /${dev}/ {
                        total_iops += \$17;
                        num_samples += 1;

                        if ( \$17 > max_iops ) {
                                max_iops = \$17;
                        }
                }

                END {   
                        avg_iops = total_iops / num_samples;

                        printf \"AVG IOPS: %6.0f \nMAX IOPS: %6.0f \nTOT IOPS: %6.0f\n\", avg_iops, max_iops, total_iops;
                }"
        echo
done
