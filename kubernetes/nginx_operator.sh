#!/usr/bin/env bash

# Operator that creates a Deployment when there's a new ConfigMap
# This is a work in progress

kubectl get --watch --output-watch-events configmap \
-o=custom-columns=type:type,name:object.metadata.name \
--no-headers | \
while read next; do                                        

    NAME=$(echo $next | cut -d' ' -f2)                     
    EVENT=$(echo $next | cut -d' ' -f1)

    case $EVENT in
        ADDED|MODIFIED)                                    
            kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata: { name: $NAME }
spec:
  selector:
    matchLabels: { app: $NAME }
  template:
    metadata:
      labels: { app: $NAME }
      annotations: { kubectl.kubernetes.io/restartedAt: $(date) }
    spec:
      containers:
      - image: nginx
        name: $NAME
        ports:
        - containerPort: 80
        volumeMounts:
        - { name: data, mountPath: /usr/share/nginx/html }
      volumes:
      - name: data
        configMap:
          name: $NAME
EOF
            ;;
        DELETED)                                            #E
            kubectl delete deploy $NAME
            ;;
    esac
done
