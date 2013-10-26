#!/bin/bash

pid=$1

ps -p ${pid} -o rss,vsz > memory_usage.log

while true
do 
	ps -p ${pid} -o rss,vsz --no-headers >> memory_usage.log
	sleep 1
done
