#!/bin/bash
set -o xtrace

CLUSTER_NAME="${CLUSTER_NAME}"
CLUSTER_ENDPOINT="${CLUSTER_ENDPOINT}"
CLUSTER_CA="${CLUSTER_CA}"

# Bootstrap EKS node
/etc/eks/bootstrap.sh $CLUSTER_NAME \
  --apiserver-endpoint $CLUSTER_ENDPOINT \
  --b64-cluster-ca $CLUSTER_CA \
  --kubelet-extra-args "--node-labels=role=worker,Name=${CLUSTER_NAME}-node"

# Install iSCSI for EBS volumes
yum install -y iscsi-initiator-utils
systemctl enable iscsid
systemctl start iscsid
