#!/bin/bash


read -p "Pls specify the ServiceName: " SERVICENAME
read -p "Pls specify the NameSpace: " NAMESPACE


PORT=$(kubectl get svc -n $NAMESPACE $SERVICENAME -o jsonpath='{.spec.ports[0].nodePort}')


MINI_PROFILE=$(minikube profile | awk '{print $2}')

CLUSTER_IP=$(minikube ip --profile $MINI_PROFILE)

argocd login  $CLUSTER_IP:$PORT  --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure
