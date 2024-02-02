#!/bin/bash

# Define namespace and deployment parameters
NAMESPACE=loadtest
DEPLOYMENT_NAME=load-generator
IMAGE=busybox
REPLICAS=30 # Set a high number of replicas to generate load

# Create namespace if it doesn't already exist
kubectl get namespace $NAMESPACE &> /dev/null || kubectl create namespace $NAMESPACE

# Deploy a load-generating deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $DEPLOYMENT_NAME
    spec:
      containers:
      - name: $DEPLOYMENT_NAME
        image: $IMAGE
        command: ["sh", "-c", "yes > /dev/null"]
EOF

echo "Deployment $DEPLOYMENT_NAME created to generate load."

# Wait for a few minutes to allow cluster autoscaler to trigger
echo "Waiting for 5 minutes to allow autoscaler to react..."
sleep 300

# Extract and display relevant autoscaler events
echo "Extracting autoscaler events..."
kubectl get events --all-namespaces | grep -E 'ScaledUpGroup|ScaleDown'

# Optional: Clean up the deployment after checking the autoscaler events
echo "Do you want to delete the load generator deployment? (y/n)"
read DELETE_DEPLOYMENT

if [ "$DELETE_DEPLOYMENT" = "y" ]; then
  kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE
  echo "Load generator deployment deleted."
else
  echo "Load generator deployment not deleted."
fi
