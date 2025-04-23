#!/bin/bash

# testid.sh - Test script for genid to verify concurrent operation
source ./genid.sh

PROCESSES=20          # Number of concurrent processes
IDS_PER_PROCESS=100   # Number of IDs to generate per process
RESULT_FILE="/tmp/genid_test_results"
COUNTER_FILE="/tmp/genid_counter"

# reset counter file
echo "0" > "$COUNTER_FILE"

# clear previous results
rm -f "$RESULT_FILE"
touch "$RESULT_FILE"

echo "=== Testing genid with $PROCESSES processes, $IDS_PER_PROCESS IDs per process ==="
echo "Total IDs to generate: $((PROCESSES * IDS_PER_PROCESS))"

generate_ids() {
    local process_id=$1
    local count=$2
    local output_file=$3
    
    echo "Process $process_id starting..." >&2
    
    for ((i=1; i<=count; i++)); do
        id=$(genid)
        echo "$id" >> "$output_file"
        
        # Occasionally sleep to increase chance of concurrency issues
        if ((i % 10 == 0)); then
            sleep 0.001
        fi
    done
    
    echo "Process $process_id completed" >&2
}

# start processes 
echo "Starting $PROCESSES concurrent processes..."
for ((p=1; p<=PROCESSES; p++)); do
    generate_ids $p $IDS_PER_PROCESS "$RESULT_FILE" &
done

# wait for all processes to complete
wait
echo "All processes completed."
echo "Verifying results..."

# sort results file
sort -n "$RESULT_FILE" > "${RESULT_FILE}.sorted"
# count total IDs 
total_generated=$(wc -l < "${RESULT_FILE}.sorted")
expected_total=$((PROCESSES * IDS_PER_PROCESS))

echo "Expected IDs: $expected_total"
echo "Generated IDs: $total_generated"

if [ "$total_generated" -ne "$expected_total" ]; then
    echo "ERROR: Number of generated IDs doesn't match expected count"
    exit 1
fi

# duplicate check
duplicates=$(uniq -d "${RESULT_FILE}.sorted")
if [ -n "$duplicates" ]; then
    echo "ERROR: Duplicate IDs found:"
    echo "$duplicates" | head -10
    exit 1
fi

# gap check
first_id=$(head -1 "${RESULT_FILE}.sorted")
last_id=$(tail -1 "${RESULT_FILE}.sorted")

if [ "$first_id" -ne 1 ] || [ "$last_id" -ne "$expected_total" ]; then
    echo "ERROR: Sequence has gaps or doesn't start at 1"
    echo "First ID: $first_id (expected: 1)"
    echo "Last ID: $last_id (expected: $expected_total)"
    
    # find and print gaps(if found)
    prev=0
    while read -r line; do
        current=$line
        if [ $((current - prev)) -ne 1 ]; then
            echo "Gap found: missing IDs between $prev and $current"
        fi
        prev=$current
    done < "${RESULT_FILE}.sorted"
    
    exit 1
fi

echo "SUCCESS: All $total_generated IDs were generated correctly with no gaps or duplicates"
echo "First ID: $first_id"
echo "Last ID: $last_id"

rm -f "${RESULT_FILE}" "${RESULT_FILE}.sorted"

exit 0