#!/usr/bin/env awk -f

BEGIN {
    redo_log_size = 4 * 1024 * 1024 * 1024
    redo_async_limit = redo_log_size * 3 / 4
    redo_sync_limit = redo_log_size * 7 / 8

    prev_bp_flushed=0
    curr_bp_flushed=0
    bp_flushed_sec=0

    prev_checkpoint_age=0
    curr_checkpoint_age=0
    checkpoint_age=0
    checkpoint_age_per_second=0

    redo_async_limit_diff=0
    redo_sync_limit_diff=0
    
    prev_history_length=0
    curr_history_length=0
    history_length_changes_per_sec=0
    
    matches=0

    printf "BP Flushed Per Second\tHistory Length Changes Per Second\tCheckpoint Age Cumulative\tCheckpoint Age Per Second\t+/- Redo Async Limit\t+/- Redo Sync Limit\n"
}

$2 ~ /Innodb_buffer_pool_pages_flushed/ { 
    matches=1

    curr_bp_flushed = $4

    if (prev_bp_flushed == 0) {
        matches=0
    }

    bp_flushed_sec = curr_bp_flushed - prev_bp_flushed
        
    prev_bp_flushed=curr_bp_flushed
}

$2 ~ /Innodb_checkpoint_age/ { 
    matches++

    curr_checkpoint_age = $4

    if (prev_checkpoint_age == 0) {
        matches=0
    }

    checkpoint_age_per_second = curr_checkpoint_age - prev_checkpoint_age
    checkpoint_age = curr_checkpoint_age
    redo_async_limit_diff = redo_async_limit - checkpoint_age
    redo_sync_limit_diff = redo_sync_limit - checkpoint_age

    prev_checkpoint_age = curr_checkpoint_age
}

$2 ~ /Innodb_history_list_length/ { 
    matches++

    if (prev_history_length == 0) {
        matches=0
    }

    curr_history_length = $4
    history_length_changes_per_sec = curr_history_length - prev_history_length

    prev_history_length = curr_history_length

    if (matches == 3) {
        printf "%22d\t%34d\t%26d\t%26d\t%21d\t%20d\n", bp_flushed_sec, history_length_changes_per_sec, checkpoint_age, checkpoint_age_per_second, redo_async_limit_diff, redo_sync_limit_diff
    }
}

END {
    matches=0
}
