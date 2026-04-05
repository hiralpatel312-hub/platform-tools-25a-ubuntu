 #!/bin/bash
set -o errexit
set -o pipefail
set -o xtrace

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

# Join the EKS cluster
/etc/eks/bootstrap.sh ${CLUSTER_NAME} \
  --apiserver-endpoint "${CLUSTER_ENDPOINT}" \
  --b64-cluster-ca "${CLUSTER_CA}" \
  --kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=on-demand'