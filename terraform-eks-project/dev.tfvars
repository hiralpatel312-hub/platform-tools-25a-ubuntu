project_name = "eks-cluster"
environment  = "dev"
aws_region   = "us-east-1"
vpc_cidr     = "10.11.0.0/16"
k8s_version  = "1.29"
ec2_instance_types = ["t3.medium","t3a.medium"]
admin_role_arn = "arn:aws:iam::383585068161:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Administrator_a72305569e9173dc" 
github_runner_role_arn = "arn:aws:iam::383585068161:role/GitHubActionsTerraformRole" 

