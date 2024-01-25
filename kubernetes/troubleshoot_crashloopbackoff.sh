#!/bin/bash

# Define the namespace (if needed)
NAMESPACE=default

# Check for pods in CrashLoopBackOff state
echo "Checking for pods in CrashLoopBackOff state..."
PODS=$(kubectl get pods -n $NAMESPACE | grep 'CrashLoopBackOff' | awk '{print $1}')

# Check if any pods are found
if [ -z "$PODS" ]
then
    echo "No pods in CrashLoopBackOff state found."
else
    # Loop through the pods and describe them
    for POD in $PODS
    do
        echo "Describing pod $POD..."
        kubectl describe pod $POD -n $NAMESPACE
        echo "Fetching last 50 logs for pod $POD..."
        kubectl logs --tail=50 $POD -n $NAMESPACE
    done
fi
