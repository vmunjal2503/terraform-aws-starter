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
Load Balancer (ALB, Layer 7, health-checked)
   │
   ├── Public Subnet (AZ-1) ──▶ EC2 (Nginx + Docker)
   └── Public Subnet (AZ-2) ──▶ (ready for auto-scaling)
                                    │
                                    ▼
                              Private Subnet
                              ┌──────────────┐
                              │ RDS PostgreSQL│ (encrypted, multi-AZ ready)
                              └──────────────┘
                                    │
                              NAT Gateway (outbound-only internet for private subnet)
```

All inside a properly configured VPC with public and private subnets, security groups, and IAM roles following AWS Well-Architected best practices.

---

## What problem does this solve?

**Without this:** You manually create each AWS resource through the console. It takes hours. You forget what you configured. When you need a second environment (staging), you start from scratch. When something breaks, there's no record of what was set up.

**With this:** Your entire infrastructure is defined in code. It's version-controlled, reproducible, and documented. Need a staging copy? Change one variable. Need to tear it down? Run `terraform destroy`. Everything is clean.

---

## What gets created?

| What | Why | Technical Details |
|------|-----|-------------------|
| **VPC + Subnets** | Your own private network isolated from other AWS accounts | CIDR `10.0.0.0/16`, 2 public + 2 private subnets across 2 AZs for high availability. NAT Gateway in public subnet for outbound traffic from private resources. |
| **EC2 Instance** | A server with Nginx and Docker already installed | `t3.micro` by default, user-data script bootstraps Docker + Nginx on launch. Placed in public subnet with Elastic IP. |
| **RDS PostgreSQL** | A managed database in a private subnet — only your server can reach it | Multi-AZ ready, automated backups (7-day retention), encryption at rest via AWS KMS, `db.t3.micro` default. Subnet group spans 2 AZs. |
| **S3 Bucket** | File storage with versioning and encryption | AES-256 server-side encryption, versioning enabled for rollback, lifecycle rules ready. Bucket policy blocks public access by default. |
| **Application Load Balancer** | Distributes traffic and health-checks your server | Layer 7 (HTTP/HTTPS), health checks every 30s at `/health`, cross-zone load balancing enabled. Listener rules ready for path-based routing. |
| **Security Groups** | Firewall rules — principle of least privilege | ALB: 80/443 from `0.0.0.0/0`. EC2: 80/443 from ALB only, 22 from your IP only. RDS: 5432 from EC2 security group only. No wide-open ports. |
| **IAM Role** | Server gets S3 read/write, nothing else | Instance profile with scoped policy — `s3:GetObject`, `s3:PutObject` on the specific bucket ARN only. No `*` permissions. |

---

## Architecture decisions

- **2 AZs, not 3** — Covers most availability needs while keeping NAT Gateway costs down. Easy to extend to 3 AZs by adding a variable.
- **Private subnets for RDS** — Database is never exposed to the internet. Connections only accepted from the EC2 security group via security group referencing (not IP-based).
- **NAT Gateway, not NAT Instance** — Managed, auto-scaling, no single point of failure. More expensive (~$32/mo) but zero maintenance.
- **Modular structure** — Each resource is a Terraform module. You can reuse `modules/vpc` in another project without touching the rest.
- **No hardcoded values** — Everything is parameterized via `variables.tf`. Region, instance size, CIDR blocks, tags — all configurable through `terraform.tfvars`.
- **State file** — Uses local state by default. For teams, switch to S3 backend with DynamoDB locking (commented out in `versions.tf`).

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
terraform plan      # Preview what will be created (review the plan!)
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
├── versions.tf                # Provider versions + optional S3 backend config
├── terraform.tfvars.example   # Sample configuration — copy and fill in
└── modules/
    ├── vpc/       # Network: VPC, 4 subnets (2 public + 2 private), NAT, route tables
    ├── ec2/       # Server: EC2 + user-data bootstrap (Nginx, Docker, CloudWatch agent)
    ├── rds/       # Database: PostgreSQL, private subnet group, encrypted, automated backups
    ├── s3/        # Storage: Encrypted bucket, versioning, public access blocked
    ├── alb/       # Load Balancer: HTTP/HTTPS listeners, target group, health checks
    └── security/  # Permissions: IAM instance profile, scoped S3 policy, security groups
```

Each module is independent — has its own `main.tf`, `variables.tf`, and `outputs.tf`. Need just a VPC and database? Remove the modules you don't need.

---

## Who is this for?

- Developers who want to deploy to AWS without clicking through the console
- Teams that need identical dev/staging/prod environments from one codebase
- Freelancers setting up infrastructure for clients (this is the template I use)

---

Built by **Vikas Munjal** | Open source under MIT License
