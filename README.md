# 🚀 Amazon EKS Cluster Deployment with Terraform and GitHub Actions

## 📘 Purpose

This project provisions a **production-grade Amazon EKS cluster** on AWS inside a custom VPC, using **modular Terraform architecture** and **GitOps best practices** via GitHub Actions.

Designed with government client requirements in mind — every infrastructure change goes through Git, has peer review, passes security scanning, and leaves a full audit trail in S3 state history.

---

## 🏗️ Architecture Overview

```
GitHub Actions Pipeline
        │
        ▼
┌─────────────────────────────────────────┐
│           AWS Account (us-east-1)        │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │         Custom VPC               │   │
│  │  ┌─────────┐  ┌──────────────┐  │   │
│  │  │ Public  │  │   Private    │  │   │
│  │  │ Subnets │  │   Subnets    │  │   │
│  │  │  (ALB)  │  │   (Nodes)    │  │   │
│  │  └────┬────┘  └──────┬───────┘  │   │
│  │       │ NAT GW       │          │   │
│  │  ┌────▼──────────────▼───────┐  │   │
│  │  │       EKS Cluster         │  │   │
│  │  │   3 Worker Nodes (ASG)    │  │   │
│  │  │   vpc-cni │ coredns       │  │   │
│  │  │   kube-proxy │ ebs-csi    │  │   │
│  │  └───────────────────────────┘  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  S3 (Terraform State) + DynamoDB (Lock) │
└─────────────────────────────────────────┘
```

---

## 🧱 Terraform Modular Design

### Root Module
Orchestrates both child modules. Ensures VPC is fully created before EKS module runs.

### VPC Module (`modules/vpc/`)
Creates the complete networking layer:

| Resource | Details |
|---|---|
| VPC | 10.11.0.0/16 CIDR |
| Public Subnets | 3 subnets across 3 AZs — for ALB and NAT Gateway |
| Private Subnets | 3 subnets across 3 AZs — worker nodes run here |
| Internet Gateway | Outbound internet for public subnets |
| NAT Gateway | Outbound internet for private subnet nodes (ECR, S3, AWS APIs) |
| Route Tables | Public route → IGW, Private route → NAT Gateway |

> **Why private subnets for nodes?** Worker nodes should never be directly reachable from the internet. Private subnets with a NAT Gateway is the correct security architecture for EKS worker nodes.

### EKS Module (`modules/eks/`)

| Component | Details |
|---|---|
| Kubernetes version | 1.32 (one minor release before latest) |
| Node type | Self-managed via ASG — not managed node groups |
| Instance types | t3.micro (Free Tier dev account) |
| ASG sizing | Min: 1, Desired: 3, Max: 5 |
| Authentication | API_AND_CONFIG_MAP mode |
| OIDC Provider | Dynamic thumbprint — enables IRSA |
| Access | EKS Access Entries for GitHub Actions runner |

---

## 🔐 IAM Design

| Role | Purpose | Created by |
|---|---|---|
| `eks-cluster-dev-cluster-role` | EKS control plane calls AWS APIs | Terraform |
| `eks-cluster-dev-node-role` | EC2 nodes join cluster, pull from ECR | Terraform |
| `eks-cluster-dev-ebs-csi-role` | EBS CSI addon manages EBS volumes (IRSA) | Terraform |
| `GitHubActionsTerraformIAMrole` | GitHub Actions authenticates via OIDC | Manual (one-time) |

**No long-lived AWS credentials anywhere.** Pipeline uses OIDC — GitHub generates a short-lived JWT token, exchanges it with AWS STS for temporary credentials (~1 hour expiry).

---

## 🧩 EKS Add-Ons

| Add-On | Status | Purpose |
|---|---|---|
| VPC CNI (`aws-node`) | ✅ Active | Assigns VPC IPs to pods |
| CoreDNS | ✅ Active | Internal DNS resolution |
| kube-proxy | ✅ Active | Service networking and routing |
| EBS CSI Driver | ✅ Running | Persistent volume provisioning |

---

## ⚙️ GitHub Actions Pipeline

**File:** `.github/workflows/deploy.yml`

### 3-Stage Pipeline

```
Push to feature/* ──► Security Scan ──► Terraform Plan
                                              │
                                        (saves artifact)
                                              │
Merge to main ──► Security Scan ──► Terraform Plan ──► [APPROVAL] ──► Deploy
```

### Stage 1 — Security Scan
- `tfsec` scans all Terraform for IaC misconfigurations
- HIGH or CRITICAL findings block the pipeline
- Runs on every branch — no code reaches AWS without passing security scan

### Stage 2 — Terraform Plan
- Authenticates to AWS via OIDC (no stored credentials)
- Runs `terraform fmt -check`, `terraform validate`, `terraform plan`
- Saves plan as build artifact tied to commit SHA

### Stage 3 — Deploy (main branch only)
- Manual approval gate via GitHub environment protection
- Downloads the **exact plan artifact** from Stage 2 — no new plan at apply time
- Runs `terraform apply`
- Updates kubeconfig and deploys k8s manifests via `kubectl apply`

> **Why save the plan as an artifact?** What was reviewed in the plan is exactly what gets applied. No drift between review and apply — critical for government audit requirements.

---

## 📁 Directory Structure

```
platform-tools-25a-ubuntu/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← GitHub Actions pipeline
│
├── terraform-eks-project/      ← Root Terraform module
│   ├── main.tf                 ← Calls vpc + eks modules
│   ├── providers.tf            ← AWS + Kubernetes providers
│   ├── backend.tf              ← S3 remote state + DynamoDB lock
│   ├── variables.tf
│   ├── outputs.tf
│   ├── aws_auth.tf             ← aws-auth ConfigMap for node registration
│   ├── dev.tfvars              ← Dev environment values
│   │
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf         ← VPC, subnets, IGW, NAT, route tables
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       └── eks/
│           ├── main.tf         ← EKS cluster, OIDC, addons
│           ├── workers.tf      ← Launch template, ASG, security groups
│           ├── iam.tf          ← All IAM roles
│           ├── eks_access.tf   ← EKS Access Entries
│           ├── bootstrap.sh.tpl← Node bootstrap script
│           ├── variables.tf
│           └── outputs.tf
│
└── k8s/                        ← Kubernetes manifests
    ├── namespace.yaml
    ├── deployment.yaml         ← nginx app, 1 replica, rolling update
    ├── service.yaml            ← NodePort on 30080
    └── ingress.yaml            ← ALB Ingress (requires t3.medium+)
```

---

## 🚀 Deployment Instructions

### Prerequisites
- AWS account with IAM user configured locally
- GitHub repository with Actions enabled
- AWS CLI and kubectl installed locally

### One-Time AWS Bootstrap (new account)
```bash
# Create S3 state bucket
aws s3api create-bucket \
  --bucket YOUR_ACCOUNT_ID-state-bucket-dev1 \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket YOUR_ACCOUNT_ID-state-bucket-dev1 \
  --versioning-configuration Status=Enabled

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name terraformlock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Register GitHub OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create GitHub Actions IAM role
# See setup-aws-roles.sh for complete script
```

### GitHub Secrets Required
| Secret | Value |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActionsTerraformIAMrole` |

### GitHub Environment Required
- Name: `production`
- Required reviewers: add yourself

### Deploy via Pipeline
```bash
# Create feature branch
git checkout -b feature/eks-cluster-setup

# Push — triggers security scan + terraform plan
git push origin feature/eks-cluster-setup

# Open PR → get approval → merge to main
# Merge triggers full deploy with manual approval gate
```

---

## ✅ Verification

```bash
# Cluster status
aws eks describe-cluster \
  --name eks-cluster-dev-cluster \
  --query 'cluster.{Name:name,Status:status,Version:version}' \
  --output json

# Nodes
kubectl get nodes -o wide

# All pods
kubectl get pods -A

# App
kubectl get pods -n my-app
kubectl get svc -n my-app

# Access app locally
kubectl port-forward -n my-app svc/my-app-svc 8080:80
# Open http://localhost:8080
```

**Expected output:**
- EKS cluster `ACTIVE`
- 3 nodes `Ready`
- System pods `Running` (aws-node, coredns, kube-proxy)
- App pod `Running` in `my-app` namespace

---

## 🐛 Challenges and Solutions

| Challenge | Root Cause | Solution |
|---|---|---|
| EBS CSI DEGRADED | Nodes in wrong subnets, SG not attached to launch template, missing IRSA role | Moved nodes to private subnets, added vpc_security_group_ids to launch template, created EBS CSI IRSA role |
| Nodes not joining cluster | aws-auth ConfigMap not created — Kubernetes provider authenticated before cluster was ready | Switched to `kubernetes_config_map_v1_data` (patches instead of creates) |
| EKS Access Entry failed | Cluster authentication mode was CONFIG_MAP, not API_AND_CONFIG_MAP | Added `access_config` block to cluster resource |
| Addon version error | Hardcoded versions didn't exist for Kubernetes 1.32 | Queried `aws eks describe-addon-versions` for correct versions |
| ASG already exists | Failed Terraform run created ASG but didn't record in state | Deleted ASG via CLI, let Terraform recreate cleanly |
| t3.micro pod limit | ENI limit of 4 pods per node — nodes full with system pods | Scaled down non-critical system deployments to free scheduling slots |

---

## 📝 Notes

- **Branch strategy:** `feature/*` → dev environment (plan only). `main` → production (plan + apply). Main temporarily points to dev account since production account was not available during this phase.
- **Instance types:** Dev account restricted to Free Tier (t3.micro). Production would use t3.medium+ with AWS Load Balancer Controller for ALB Ingress.
- **EBS CSI:** Running in cluster, managed outside Terraform state to avoid addon timeout issues.
- **NodePort vs ALB:** Using NodePort (port 30080) for dev demo. ALB Ingress manifest is ready — requires t3.medium nodes and AWS Load Balancer Controller.
