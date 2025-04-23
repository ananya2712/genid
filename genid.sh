#!/bin/bash

genid() {
    local COUNTER_FILE="${COUNTER_FILE:-/tmp/genid_counter}"
    local LOCK_FILE="${COUNTER_FILE}.lock"
    local PADDING=${PADDING:-5}
    
    # counter file creation
    if [ ! -f "$COUNTER_FILE" ]; then
        echo "0" > "$COUNTER_FILE" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: Unable to create counter file at $COUNTER_FILE" >&2
            return 1
        fi
    fi
    
    # lock with timeout
    local TIMEOUT=10
    local start_time=$(date +%s)

    # acquire lock using flock
    local lock_fd=200

    # open lock file with file descriptor(fd)
    eval "exec $lock_fd>$LOCK_FILE"
    
    # create the lock file exclusively
     while ! flock -n $lock_fd; do
        # check if timeout
        if [ $(($(date +%s) - start_time)) -gt $TIMEOUT ]; then
            echo "Error: Timed out waiting for lock" >&2
            eval "exec $lock_fd>&-"  # close fd
            return 1
        fi
        # sleep to reduce CPU load
        sleep 0.01
    done
    
    # increment counter
    local counter=$(cat "$COUNTER_FILE")
    counter=$((counter + 1))
    echo "$counter" > "$COUNTER_FILE"
    
    # output zero-padded ID
    printf "%0${PADDING}d\n" "$counter"

    # release lock
    eval "exec $lock_fd>&-"
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    genid "$@"
fi