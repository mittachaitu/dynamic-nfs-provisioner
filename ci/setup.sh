#! /bin/bash

set -e

echo "Install openebs-hostpath operator"

kubectl apply -f https://raw.githubusercontent.com/openebs/charts/gh-pages/hostpath-operator.yaml
sleep 20

echo "Waiting for openebs hostpath operator to be up and running"

kubectl wait --for=condition=available --timeout=550s deployment/openebs-localpv-provisioner -n openebs

## Create a hostpath directory with root permissions
mkdir -p /tmp/openebs
chmod 744 /tmp/openebs

echo "Creating openebs-local-hostpath StorageClass"

## Create a StorageClass pointing to above hostPath
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-local-hostpath
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      - name: StorageType
        value: hostpath
      - name: BasePath
        value: /tmp/openebs
provisioner: openebs.io/local
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

## Installing OpenEBS dynamic nfs provisioner
kubectl apply -f ../deploy/kubectl/openebs-nfs-provisioner.yaml
sleep 10

echo "Waiting for openebs-nfs-provisioner"
kubectl wait --for=condition=available --timeout=550s deployment/openebs-nfs-provisioner -n openebs
