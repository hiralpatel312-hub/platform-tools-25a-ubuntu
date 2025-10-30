#!/bin/bash
set -o xtrace
set -o errexit
set -o pipefail

# --- Install dependencies ---
yum update -y
yum install -y aws-cli jq

# --- Install kubelet, aws-eks-bootstrap scripts ---
curl -o /etc/yum.repos.d/kubernetes.repo https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64.repo
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

# --- Configure EKS node to join cluster ---
CLUSTER_NAME="${CLUSTER_NAME}"
CLUSTER_ENDPOINT="${CLUSTER_ENDPOINT}"
CLUSTER_CA="${CLUSTER_CA}"

mkdir -p /etc/kubernetes
cat <<EOF >/etc/kubernetes/kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_ENDPOINT}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: aws-node
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
- name: aws-node
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${CLUSTER_NAME}"
EOF

# --- Bootstrap node ---
/etc/eks/bootstrap.sh ${CLUSTER_NAME} \
  --kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=on-demand' \
  --b64-cluster-ca "${CLUSTER_CA}" \
  --apiserver-endpoint "${CLUSTER_ENDPOINT}"

# --- Signal ASG that node is ready (optional) ---
/opt/aws/bin/cfn-signal -e 0 --stack ${CLUSTER_NAME}-nodes --resource NodeGroup --region ${AWS_DEFAULT_REGION}
