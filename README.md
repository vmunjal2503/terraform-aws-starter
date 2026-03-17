# Terraform AWS Starter — Production-Ready Infrastructure

Deploy a complete, secure AWS infrastructure in minutes using Terraform modules.

## Why I Built This

**The Problem:** Every new AWS project starts the same way — manually clicking through the console to create a VPC, subnets, security groups, EC2 instances, and databases. It takes hours, is error-prone, and impossible to replicate consistently across environments. When something breaks at 2 AM, there's no documentation of what was configured or why.

**The Solution:** This project provides a modular, battle-tested Terraform setup that deploys a complete AWS infrastructure in under 10 minutes. Every resource is version-controlled, tagged, documented, and reproducible. Need a staging environment identical to production? Run `terraform apply -var="environment=staging"` — done.

**Built from real-world experience** managing infrastructure at scale as a Staff SRE. These modules follow the same patterns I use for production systems handling millions of requests.

```
                          ┌─────────────────────────────────────────────┐
                          │              AWS Cloud (us-east-1)          │
                          │                                             │
    ┌──────────┐          │  ┌──────────────────────────────────────┐   │
    │  Users /  │────────▶│  │     Application Load Balancer (ALB)  │   │
    │  Internet │         │  └──────────────┬───────────────────────┘   │
    └──────────┘          │                 │                           │
                          │  ┌──────────────▼───────────────────────┐   │
                          │  │         Public Subnets (x2)          │   │
                          │  │  ┌────────────────────────────────┐  │   │
                          │  │  │   EC2 Instance (Nginx+Docker)  │  │   │
                          │  │  │   IAM Role → S3 Access         │  │   │
                          │  │  └────────────────────────────────┘  │   │
                          │  └──────────────┬───────────────────────┘   │
                          │                 │                           │
                          │  ┌──────────────▼───────────────────────┐   │
                          │  │        Private Subnets (x2)          │   │
                          │  │  ┌────────────────────────────────┐  │   │
                          │  │  │   RDS PostgreSQL (encrypted)   │  │   │
                          │  │  └────────────────────────────────┘  │   │
                          │  └─────────────────────────────────────┘    │
                          │                                             │
                          │  ┌─────────────────────────────────────┐    │
                          │  │  S3 Bucket (versioned, encrypted)   │    │
                          │  └─────────────────────────────────────┘    │
                          └─────────────────────────────────────────────┘
```

## What Gets Deployed

| Resource | Details |
|---|---|
| **VPC** | Custom VPC with DNS support |
| **Subnets** | 2 public + 2 private across 2 AZs |
| **NAT Gateway** | Internet access for private subnets |
| **EC2** | t3.micro with Nginx + Docker pre-installed |
| **RDS** | PostgreSQL 15 in private subnet, encrypted |
| **S3** | Versioned bucket with AES-256 encryption |
| **ALB** | Application Load Balancer with health checks |
| **Security Groups** | Least-privilege access rules |
| **IAM** | EC2 role with scoped S3 access |

## Prerequisites

- [Terraform](https://terraform.io) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- An AWS account with permissions to create the above resources

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/terraform-aws-starter.git
cd terraform-aws-starter

# 2. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Initialize and deploy
terraform init
terraform plan          # Review what will be created
terraform apply         # Type 'yes' to confirm

# 4. Get outputs
terraform output        # Shows ALB DNS, EC2 IP, RDS endpoint, etc.
```

## Cost Estimate

Running all resources in us-east-1 with defaults:

| Resource | Estimated Monthly Cost |
|---|---|
| EC2 t3.micro | ~$8.50 |
| RDS db.t3.micro | ~$14.00 |
| NAT Gateway | ~$4.50 + data |
| ALB | ~$16.00 + data |
| S3 | ~$0.02 |
| **Total** | **~$43/month** |

> Use `terraform destroy` to tear everything down when done testing.

## Clean Up

```bash
terraform destroy       # Type 'yes' to confirm — removes ALL resources
```

## Module Structure

```
terraform-aws-starter/
├── main.tf                    # Root module — calls all sub-modules
├── variables.tf               # Input variables with defaults
├── outputs.tf                 # Key infrastructure outputs
├── versions.tf                # Provider and Terraform version constraints
├── terraform.tfvars.example   # Example variable values
├── .gitignore
└── modules/
    ├── vpc/                   # VPC, subnets, NAT, IGW, route tables
    ├── ec2/                   # EC2 instance, security group, user_data
    ├── rds/                   # RDS PostgreSQL, subnet group, security group
    ├── s3/                    # S3 bucket, versioning, encryption, lifecycle
    ├── alb/                   # ALB, target group, listener, security group
    └── security/              # IAM role, policy, instance profile
```

## Customization

- Change instance sizes in `terraform.tfvars`
- Add more subnets by modifying `modules/vpc`
- Swap RDS engine by changing `engine` parameter in `modules/rds`
- Add CloudFront, ElastiCache, or other modules as needed

---

Built by **Vikas Munjal** | Open source under MIT License
