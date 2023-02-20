#!/usr/bin/env bash

# Given confusion between CPUs and vCPUs, this script provides a count of physical CPUs, logical CPUs and number of cores per physical CPU

CPUFILE=/proc/cpuinfo
test -f $CPUFILE || exit 1

echo "Physical CPUs: $(grep "physical id" $CPUFILE | sort -u | wc -l)"
echo "Logical Cores: $(grep "core id" $CPUFILE | sort -u | wc -l)"
echo "CPU count:     $(grep "processor" $CPUFILE | wc -l)"
