#!/bin/bash

# This requires jq to be installed

## Secrets to access the CR

# The default token UUID is for US South
TOKEN_UUID=${CR_TOKEN_UUID:-5a611fd2-87d9-5662-8218-30eaba26610b}

CR_TOKEN=$(ibmcloud cr token-get $TOKEN_UUID -q)
CR_URL=$(ibmcloud cr info | awk '/Container Registry/{ print $3 }' | head -1)
sed -e 's/__CR_TOKEN__/'"$CR_TOKEN"'/g' \
    -e 's/__CR_URL__/'"$CR_URL"'/g' cr-secret.yaml.template > cr-secret.yaml

## Secrets to access the target cluster

CLUSTER_NAME=${TARGET_CLUSTER_NAME:-af-pipelines}
eval $(ibmcloud cs cluster-config $CLUSTER_NAME --export)

# This works as long as config returns one cluster and one user
SERVICE_ACCOUNT_SECRET_NAME=$(kubectl get serviceaccount/health-admin -n health -o json | jq .secrets[0].name -r)
CA_DATA=$(kubectl get secret/$SERVICE_ACCOUNT_SECRET_NAME -n health -o json | jq '.data["ca.crt"]' -r)
TOKEN=$(kubectl get secret/$SERVICE_ACCOUNT_SECRET_NAME -n health -o json | jq '.data.token' -r)

sed -e 's/__CLUSTER_NAME__'"$TARGET_CLUSTER_NAME"'/g' \
    -e 's/__CA_DATA_KEY__/'"$CA_DATA"'/g' \
    -e 's/__TOKEN_KEY__/'"$TOKEN"'/g' cluster-secrets.yaml.template > ${TARGET_CLUSTER_NAME}-secrets.yaml
