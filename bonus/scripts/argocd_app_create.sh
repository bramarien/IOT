#!/bin/bash

ARGO_PASS="$(cat /vagrant/argoPW)"

echo "y" | argocd login argocd.iot --username admin --password "$ARGO_PASS" --insecure --grpc-web

argocd app create dev --repo http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/devWil.git --path devWil --dest-server https://kubernetes.default.svc --dest-namespace dev --insecure --grpc-web
argocd app set dev --sync-policy automated --auto-prune --self-heal --grpc-web
