#!/usr/bin/env bash
# Run the CI/CD pipeline from a specific git reference

## Preconditions:
# - The target cluster resource must be already defined

# apiVersion: tekton.dev/v1alpha1
# kind: PipelineResource
# metadata:
#   name: mycluster
# spec:
#   type: cluster
#   params:
#     - name: url
#       value: <cluster-master-url>
#     - name: username
#       value: health-admin
#   secrets:
#     - fieldName: token
#       secretKey: tokenKey
#       secretName: cluster-secrets
#     - fieldName: cadata
#       secretKey: cadataKey
#       secretName: cluster-secrets

# - Service accounts, roles and secrets must exist in the target
# - For Knative, the istio ingress role must be bound to the health-admin
# - kubectl is configured to point to the cluster where the pipeline is executed

## Inputs
# Mandatory
CLUSTER_RESOURCE_NAME=${CLUSTER_RESOURCE_NAME:?"Please set CLUSTER_RESOURCE_NAME"}
CLUSTER_INGRESS_HOST=${CLUSTER_INGRESS_HOST:?"Please set CLUSTER_INGRESS_HOST"}
# Optional (with defaults)
GIT_REFERENCE=${GIT_REFERENCE:-master}
GIT_URL=${GIT_URL:-https://github.com/mtreinish/health-helm}
IMAGES_BASE_URL=${IMAGES_BASE_URL:-registry.ng.bluemix.net/andreaf}
IMAGE_TAG=${IMAGE_TAG:-$GIT_REFERENCE}
USE_IMAGE_CACHE=${USE_IMAGE_CACHE:-"true"}
TARGET_NAMESPACE=${TARGET_NAMESPACE:-health}
USE_KNATIVE=${USE_KNATIVE:-"true"}
PIPELINE_TAG=${PIPELINE_TAG:-$GIT_REFERENCE}

# Variables
declare -A IMAGE_RESOURCES

## Setup resources
# GIT
GIT_RESOURCE=$(cat <<EOF | kubectl create -o jsonpath='{.metadata.name}' -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  generateName: health-helm-git-knative-
  labels:
    app: health
    tag: $PIPELINE_TAG
spec:
  type: git
  params:
    - name: revision
      value: $GIT_REFERENCE
    - name: url
      value: $GIT_URL
EOF
)

# Images
for IMG in api frontend database; do
  IMAGE_RESOURCES[$IMG]=$(cat <<EOF | kubectl create -o jsonpath='{.metadata.name}' -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  generateName: health-$IMG-image-
  labels:
    app: health
    tag: $PIPELINE_TAG
spec:
  type: image
  params:
    - name: url
      description: The target URL
      value: $IMAGES_BASE_URL/health-$IMG
EOF
)
done

## Setup the pipelinerun
cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  generateName: health-helm-cd-pr-
  labels:
    app: health
    tag: $PIPELINE_TAG
    cluster: $CLUSTER_RESOURCE_NAME
spec:
  pipelineRef:
    name: health-helm-cd-pipeline
  params:
    - name: clusterIngressHost
      value: $CLUSTER_INGRESS_HOST
    - name: targetNamespace
      value: $TARGET_NAMESPACE
    - name: imageTag
      value: $IMAGE_TAG
    - name: useImageCache
      value: "$USE_IMAGE_CACHE"
    - name: useKnative
      value: "$USE_KNATIVE"
  trigger:
    type: manual
  serviceAccount: 'default'
  resources:
    - name: src
      resourceRef:
        name: $GIT_RESOURCE
    - name: api-image
      resourceRef:
        name: ${IMAGE_RESOURCES["api"]}
    - name: frontend-image
      resourceRef:
        name: ${IMAGE_RESOURCES["frontend"]}
    - name: database-image
      resourceRef:
        name: ${IMAGE_RESOURCES["database"]}
    - name: health-cluster
      resourceRef:
        name: $CLUSTER_RESOURCE_NAME
EOF

# Watch command
echo "watch kubectl get all -l tag=$PIPELINE_TAG"
