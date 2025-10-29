#!/bin/bash
set -o xtrace

# Bootstrap EKS node
/etc/eks/bootstrap.sh ${cluster_name} \
  --kubelet-extra-args "--node-labels=role=worker,Name=${cluster_name}-node"

# Install iSCSI for EBS volumes
yum install -y iscsi-initiator-utils
systemctl enable iscsid
systemctl start iscsid
