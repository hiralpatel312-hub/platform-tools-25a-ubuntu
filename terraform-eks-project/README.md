# 🚀 Amazon EKS Cluster Deployment with Terraform and GitHub Actions

## 📘 Purpose
This project provisions an **Amazon EKS (Elastic Kubernetes Service)** cluster inside a **newly created VPC**, following **modular Terraform architecture** and **GitOps best practices** via **GitHub Actions**.

---

## 🧩 Architecture Overview
**Modules:**
- **VPC Module** – Creates the base AWS networking environment.
- **EKS Module** – Deploys the EKS control plane, worker nodes, and add-ons.
  
The root module orchestrates both modules, ensuring the VPC is created before the EKS cluster.

**GitOps Workflow:**
- All Terraform commands are executed via **GitHub Actions**.
- Two branch workflows:
  - `feature/*` → Development environment.
  - `main` → Production (temporarily points to `dev` during testing phase).
- Pull Requests (PRs) into `main` require:
  - 1 approval from Project Manager.
  - 2 peer/team approvals.

---

## 🧱 Terraform Modular Design

### VPC Module (`modules/vpc`)
**Purpose:** Create a custom VPC for EKS and RDS communication.

**Configuration:**
- New VPC with unique CIDR.
- 3 Public + 3 Private subnets across multiple Availability Zones.
- No NAT Gateway (private subnets are isolated).
- Internet Gateway attached to public subnets.
- Outputs exported for use by the EKS module:
  - `vpc_id`
  - `public_subnet_ids`
  - `private_subnet_ids`
  - `vpc_cidr`

---

### EKS Module (`modules/eks`)
**Purpose:** Provision an EKS cluster and worker nodes.

**Configuration Highlights:**
- Kubernetes version: one minor release before the latest supported by AWS.
- Self-managed node group using ASG (not managed node groups).
- Node mix:  
  - 20% On-demand, 80% Spot Instances  
  - Instance types: `t3.medium`, `t3a.medium`, `c5.large`, etc.  
  - Desired: 3 nodes | Min: 1 | Max: 5  
- Multi-AZ placement.
- Security groups with minimal rules.
- EKS placed in **public subnets**.

---

## 🧩 EKS Cluster Add-Ons

The following add-ons are installed automatically in the EKS cluster:

| Add-On                     | Purpose                                                                 |
|-----------------------------|-------------------------------------------------------------------------|
| **VPC CNI (`aws-node`)**    | Assigns VPC IP addresses to pods, enabling secure networking and integration with AWS resources. |
| **kube-proxy**              | Manages internal networking and routing between services inside the cluster. |
| **Amazon EBS CSI Driver**   | Enables pods to use Amazon EBS volumes for persistent storage, supporting dynamic provisioning and snapshots. |
| **CoreDNS**                 | Provides internal DNS resolution for pods and services.                  |

These add-ons are essential for networking, storage, and service discovery within the EKS cluster.


## ⚙️ GitHub Actions Workflow
Located in `.github/workflows/terraform.yml`

**Actions:**
- `terraform init` (with remote backend in S3)
- `terraform validate`
- `terraform plan`
- `terraform apply` (on PR approval or merge to `main`)
  
**IAM Role Integration:**
- Uses `GitHubActionsTerraformIAMrole` created in AWS.
- GitHub environment `dev` stores IAM role ARN in `IAM_ROLE` secret.

---

## 🧩 Directory Structure


🧩 Directory Structure
terraform-eks-project/
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │
│   └── eks/
│       ├── bootstrap.sh.tpl
│       ├── eks_access.tf
│       ├── iam.tf
│       ├── workers.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
├── dev.tfvars
├── aws_auth.tf
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── backend.tf
└── README.md

🚀 Deployment Instructions
1️⃣ Prerequisites

AWS account access and correct IAM role.

GitHub Repository with Actions enabled.

Secrets configured:

IAM_ROLE → ARN of GitHubActionsTerraformIAMrole.

2️⃣ First-Time Setup
# Initialize Terraform
terraform init -backend-config="backend.hcl"

# Validate configuration
terraform validate

3️⃣ Running via GitHub Actions

Push code to a branch:

git checkout -b feature/eks-cluster-setup
git push origin feature/eks-cluster-setup


GitHub Actions will automatically:

Run terraform plan using dev.tfvars

Await PR merge approval.

Merge PR into main → triggers terraform apply.

✅ Verification Steps

After successful deployment:

aws eks describe-cluster --name eks-cluster-dev-cluster --region us-east-1
kubectl get nodes -o wide
kubectl get pods -A


Expected Output:

EKS cluster running.

Nodes Ready with mixed instance types.

Add-ons (CNI, EBS CSI) in Active state.