#!/bin/bash

# Search activity logs for historical access permissions for custom roles

start_time="2023-02-22"
time_offset="6h" # Use "7d" for specifying days

az monitor activity-log list \
           --start-time $start_time \
           --offset $time_offset \
           | jq -r '.[] | .operationName["value"] ' \
           | sort -u
