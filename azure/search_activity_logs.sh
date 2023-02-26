#!/usr/bin/env bash

# Search activity logs for historical access patterns
# Useful for building custom roles

start_time="2023-02-22"          # Enter a date
time_offset="6h"                 # Use "7d" format for specifying days

az monitor activity-log list \
           --start-time $start_time \
           --offset $time_offset \
           | jq -r '.[] | .operationName["value"] ' \
           | sort -u

exit 0
