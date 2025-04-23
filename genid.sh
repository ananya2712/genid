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
    
    # create the lock file exclusively
    while ! ln -s $$ "$LOCK_FILE" 2>/dev/null; do
        # check if timeout
        if [ $(($(date +%s) - start_time)) -gt $TIMEOUT ]; then
            echo "Error: Timed out waiting for lock" >&2
            return 1
        fi
        
        # check if lock is stale (parent dead)
        if [ -L "$LOCK_FILE" ]; then
            local lock_pid=$(readlink "$LOCK_FILE")
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                # remove if dead
                rm -f "$LOCK_FILE" 2>/dev/null
            fi
        fi
            sleep 0.01
    done
    
    # increment counter
    local counter=$(cat "$COUNTER_FILE")
    counter=$((counter + 1))
    echo "$counter" > "$COUNTER_FILE"
    
    # release lock
    rm -f "$LOCK_FILE"
    
    # output zero-padded ID
    printf "%0${PADDING}d\n" "$counter"
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    genid "$@"
fi