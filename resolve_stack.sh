#!/bin/bash

mysqld_path=$1
stack_trace_file=$2

cat ${stack_trace_file} | cut -d "[" -f 2 | awk '{print "["$1}' > tmp.txt
mv tmp.txt ${stack_trace_file}

nm --demangle -D -n ${mysqld_path} > mysqld_symbols.sym
resolve_stack_dump -s ./mysqld_symbols.sym -n $stack_trace_file
