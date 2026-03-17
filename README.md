# Terraform AWS Starter

**One command to deploy a full AWS infrastructure — VPC, servers, database, storage, and load balancer.**

---

## What is this?

Instead of spending hours clicking around the AWS console to set up your infrastructure, you run one command:

```bash
terraform apply
```

And in ~10 minutes, you get:

```
Internet
   │
   ▼
Load Balancer (distributes traffic)
   │
   ▼
Server (EC2 with Nginx + Docker pre-installed)
   │
   ▼
Database (PostgreSQL, private, encrypted)
   │
   ▼
File Storage (S3 bucket, versioned, encrypted)
```

All inside a properly configured network (VPC) with public and private subnets, security groups, and IAM roles.

---

## What problem does this solve?

**Without this:** You manually create each AWS resource through the console. It takes hours. You forget what you configured. When you need a second environment (staging), you start from scratch. When something breaks, there's no record of what was set up.

**With this:** Your entire infrastructure is defined in code. It's version-controlled, reproducible, and documented. Need a staging copy? Change one variable. Need to tear it down? Run `terraform destroy`. Everything is clean.

---

## What gets created?

| What | Why |
|------|-----|
| **VPC + Subnets** | Your own private network — 2 public subnets (for the server and load balancer) + 2 private subnets (for the database) |
| **EC2 Instance** | A server with Nginx and Docker already installed, ready to deploy your app |
| **RDS PostgreSQL** | A managed database sitting in a private subnet — only your server can talk to it |
| **S3 Bucket** | File storage with versioning turned on and encryption enabled |
| **Load Balancer** | Distributes incoming traffic and checks if your server is healthy |
| **Security Groups** | Firewall rules — only the right ports are open, nothing else |
| **IAM Role** | Your server gets permission to read/write to S3, nothing more |

---

## How to use it

```bash
# 1. Clone
git clone https://github.com/vmunjal2503/terraform-aws-starter.git
cd terraform-aws-starter

# 2. Set your values
cp terraform.tfvars.example terraform.tfvars
# Open terraform.tfvars and fill in your project name, region, SSH key, etc.

# 3. Deploy
terraform init      # Download AWS provider
terraform plan      # Preview what will be created
terraform apply     # Create everything (type 'yes')

# 4. See your outputs
terraform output    # Shows: server IP, database endpoint, S3 bucket name, load balancer URL
```

## How much does it cost?

| Resource | Monthly Cost |
|----------|-------------|
| EC2 (t3.micro) | ~$8.50 |
| RDS (db.t3.micro) | ~$14.00 |
| NAT Gateway | ~$4.50 |
| Load Balancer | ~$16.00 |
| S3 | ~$0.02 |
| **Total** | **~$43/month** |

To delete everything and stop charges: `terraform destroy`

---

## How is the code organized?

```
terraform-aws-starter/
├── main.tf                    # Connects all the modules together
├── variables.tf               # Configuration options (region, instance size, etc.)
├── outputs.tf                 # What you see after deployment (IPs, URLs, endpoints)
├── terraform.tfvars.example   # Sample configuration — copy and fill in
└── modules/
    ├── vpc/       # Network: VPC, subnets, NAT gateway, route tables
    ├── ec2/       # Server: EC2 instance with Nginx + Docker
    ├── rds/       # Database: PostgreSQL in private subnet
    ├── s3/        # Storage: Encrypted, versioned S3 bucket
    ├── alb/       # Load Balancer: Routes traffic to your server
    └── security/  # Permissions: IAM role for server → S3 access
```

Each module is independent. Need just a VPC and database? Remove the modules you don't need.

---

## Who is this for?

- Developers who want to deploy to AWS without clicking through the console
- Teams that need identical dev/staging/prod environments
- Freelancers setting up infrastructure for clients (this is the template I use)

---

Built by **Vikas Munjal** | Open source under MIT License
