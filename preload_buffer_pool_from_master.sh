#!/bin/bash

# Variables
active_master=
passive_master=
ib_buffer_pool_path=/data/mysql_data/ib_buffer_pool

# Functions
function vlog() {
    datetime=$(date "+%Y-%m-%d %H:%M:%S")
    msg="[${datetime}] $1"

    echo ${msg}
}

function show_error_n_exit() {
    error_msg=$1
    echo "ERROR: ${error_msg}"
    exit 1
}

# Usage info
function show_help() {
cat << EOF
Usage: ${0##*/} --active-master ACTIVE_MASTER --passive-master PASSIVE_MASTER
Failover from ACTIVE_MASTER to PASSIVE_MASTER on POD_NAME

Options:

    --help                          display this help and exit
    --active-master ACTIVE_MASTER   the hostname of the active MySQL master 
                                    that will be used as source for target
                                    buffer pool state
    --passive-master PASSIVE_MASTER the hostname of the passive master that
                                    will be have the target buffer pool state
                                    applied
EOF
}

function show_help_and_exit() {
    show_help >&2
    exit 22 # Invalid parameters
}

# Command line processing
OPTS=$(getopt -o ha:p: --long help,active-master:,passive-master: -n 'preload_buffer_pool_from_master.sh' -- "$@")
[ $? != 0 ] && show_help_and_exit

eval set -- "$OPTS"

while true; do
  case "$1" in
    -a | --active-master )
                                active_master="$2";
                                shift; shift
                                ;;
    -p | --passive-master )
                                passive_master="$2";
                                shift; shift
                                ;;
    -h | --help )
                                show_help >&2
                                exit 1
                                ;;
    -- )                        shift; break
                                ;;
    * )
                                show_help >&2
                                exit 1
                                ;;
  esac
done

# Sanity checking
[[ -z ${active_master} ]] && show_help_and_exit >&2

[[ -z ${passive_master} ]] && show_help_and_exit >&2


# Do actual work
# Dump the buffer pool on the active master
vlog "Dumping the buffer pool state on ${active_master}"
ssh root@${active_master} "mysql -e 'SET GLOBAL innodb_buffer_pool_dump_now=ON'"

# Wait for the buffer pool dump on the active master to complete
buffer_pool_dump_completed=$(ssh root@${active_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_dump_status\"'" | grep -c "dump completed")
while [[ ${buffer_pool_dump_completed} != 1 ]]; do
    sleep 0.1
    buffer_pool_dump_completed=$(ssh root@${active_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_dump_status\"'" | grep -c "dump completed")
done
vlog "Buffer pool state dumped successfully on ${active_master}"

# Sanitize the buffer pool state file
vlog "Copying the buffer pool state file to ${passive_master}"
scp root@${active_master}:${ib_buffer_pool_path} /tmp/${active_master}-ib_buffer_pool
scp /tmp/${active_master}-ib_buffer_pool root@${passive_master}:/tmp/ib_buffer_pool
ssh root@${passive_master} "chmod 0660 /tmp/ib_buffer_pool && chown mysql:mysql /tmp/ib_buffer_pool"

# Backup
ssh root@${passive_master} "cp ${ib_buffer_pool_path} ${ib_buffer_pool_path}.bak"
ssh root@${passive_master} "chmod 0660 ${ib_buffer_pool_path}.bak && chown mysql:mysql ${ib_buffer_pool_path}.bak"
ssh root@${passive_master} "mv /tmp/ib_buffer_pool ${ib_buffer_pool_path} && chmod 0660 ${ib_buffer_pool_path} && chown mysql:mysql ${ib_buffer_pool_path}"

# Abort any running buffer pool load on passive master
vlog "Aborting any running buffer pool state load operation on ${passive_master}"
ssh root@${passive_master} "mysql -NB -e \"SET GLOBAL innodb_buffer_pool_load_abort=ON\""

# Wait for the buffer pool abort on the passive master to complete
buffer_pool_abort_completed=$(ssh root@${passive_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_load_status\"'" | egrep -c "load aborted|load completed")
while [[ ${buffer_pool_abort_completed} != 1 ]]; do
    sleep 0.1
    buffer_pool_abort_completed=$(ssh root@${passive_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_load_status\"'" | egrep -c "load aborted|load completed")
done

# Reload the buffer pool state on passive master
vlog "Loading the buffer pool state on ${passive_master}"
ssh root@${passive_master} "mysql -e 'SET GLOBAL innodb_buffer_pool_load_now=ON'"

# Wait for the buffer pool reload on passive master to complete
buffer_pool_load_state=$(ssh root@${passive_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_load_status\"'")
buffer_pool_load_completed=$(echo "${buffer_pool_load_state}" | grep -c "load completed")
while [[ ${buffer_pool_load_completed} != 1 ]]; do
    if [[ "${buffer_pool_load_state}" =~ "Loaded" ]]; then
        total_pages_to_load=$(echo "${buffer_pool_load_state}" | cut -d '/' -f 2 | awk '{print $1}')
        num_pages_loaded=$(echo "${buffer_pool_load_state}" | cut -d '/' -f 1 | awk '{print $3}')
        echo "${num_pages_loaded} ${total_pages_to_load}" | awk '{printf "%.2f percent buffer pool loaded\n", $1/$2*100}'
    fi

    sleep 5

    buffer_pool_load_state=$(ssh root@${passive_master} "mysql -NB -e 'SHOW STATUS LIKE \"Innodb_buffer_pool_load_status\"'")
    buffer_pool_load_completed=$(echo "${buffer_pool_load_state}" | grep -c "load completed")
done
vlog "Buffer pool state loaded successfully on ${passive_master}"
