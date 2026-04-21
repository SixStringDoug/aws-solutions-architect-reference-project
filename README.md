# AWS SAA Project – Study App (SAA-C03)

This repository contains a hands-on study project designed to reinforce concepts from the  
**AWS Certified Solutions Architect – Associate (SAA-C03)** exam.

The project centers on a **single, intentionally simple full-stack CRUD application** that is deployed multiple times using different AWS compute and deployment models.  
The goal is to demonstrate **architectural tradeoffs**, not application complexity.

---

## 🎯 Project Goals
- Practice AWS core services (EC2, ALB, RDS, ECS/Fargate, Elastic Beanstalk, S3, IAM, CloudWatch)
- Deploy the **same application artifact** across multiple AWS architectures
- Use **environment-based configuration** instead of code changes
- Manage infrastructure with **Infrastructure as Code** (Terraform / CloudFormation)
- Keep scope tight and costs low while reinforcing exam-relevant patterns
- Demonstrate real-world AWS account security best practices
- Implement professional-grade cost guardrails and teardown discipline

---

## 🧱 Application Overview
- **Backend:** Java / Spring Boot CRUD API (Tasks)
- **Frontend:** Lightweight React UI (Vite)
- **Persistence:** Postgres (local + AWS-managed equivalents)
- **Artifact:** Single reusable Spring Boot JAR

The frontend exists only to exercise the backend in real AWS environments.

---

## 🗂 Repository Structure
```
aws-saa-project-2/
├── artifacts/                      # Built JAR artifacts
├── backend/                        # Spring Boot CRUD API (TaskTracker)
│   └── tasktracker/
├── docs/                           # Architecture notes & diagrams
├── frontend/                       # React UI (Vite)
│   └── tasktracker-ui/
├── infra/                          # Infrastructure as Code (Terraform / CloudFormation)
│   ├── cloudformation/             # CFN component templates (VPC, ECS, etc.)
│   │   ├── components/
│   │   │   └── ecs-fargate/
│   │   ├── stacks/
│   │   │   └── ecs-fargate/
│   │   └── templates/
│   ├── docs/                       # IaC design standards, conventions, and deployment guidance
│   ├── scripts/                    # Deployment helper scripts
│   │   └── push-backend-image.sh
│   └── terraform/                  # Terraform orchestration (bootstrap state, env composition, reusable modules)
│       ├── bootstrap/
│       │   └── state/
│       ├── env/
│       │   └── dev/
│       └── modules/
│           ├── app_config/
│           ├── ec2_networking/
│           ├── ecr_repository/
│           ├── fargate_guardrails/
│           ├── networking_vpc/
│           ├── rds_postgres/
│           └── s3_attachments/
├── CHANGELOG.md
└── README.md
```

---

## ⚙️ Configuration Model
- Application behavior is controlled entirely via:
    - `SPRING_PROFILES_ACTIVE` (`ec2`, `fargate`, `beanstalk`, `local`)
    - Environment variables (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, etc.)
- **No code changes** are required to switch architectures.
- Sensitive values are injected via:
    - SSM Parameter Store         (primary, low-cost default)
    - Secrets Manager             (optional proof-of-concept)
    - RDS managed master password (optional toggle)

---

## 🧪 Deployment Configurations (tfvars)

### ⚠️ Important Notes

- **Only one configuration should be used at a time**
- Each configuration is independently deployable from a clean state
- No architecture relies on another configuration
- `.auto.tfvars` is intentionally not used to prevent unintended variable merging

This project supports multiple deployment architectures using separate Terraform variable files.

Each `.tfvars` file represents a complete, standalone infrastructure configuration.

### Available configurations (deploy only one at a time):
- `test-ec2.tfvars`     → EC2-based deployment
- `test-fargate.tfvars` → ECS Fargate-based deployment
- `test-beanstalk.tfvars` → (planned)

### 🔧 Deployment Workflow

All Terraform commands should be run from the project root unless otherwise specified.

#### 1. Bootstrap Terraform state (required once per session)

```bash
cd infra/terraform/bootstrap/state
terraform init
terraform apply
```

#### 2. Deploy infrastructure
```bash
cd infra/terraform/env/dev
terraform init -reconfigure
```

Choose Fargate or EC2 deployment **(choose only one configuration)**.

Fargate:
```bash
terraform apply -var-file="test-fargate.tfvars"
```

EC2:
```bash
terraform apply -var-file="test-ec2.tfvars"
```

#### 3. Destroy infrastructure

Choose Fargate or EC2 destroy **(choose same configuration you deployed)**.

Fargate:
```bash
cd infra/terraform/env/dev
terraform destroy -var-file="test-fargate.tfvars"
```
EC2:
```bash
cd infra/terraform/env/dev
terraform destroy -var-file="test-ec2.tfvars"
```

#### 4. Destroy bootstrap resources (when finished)
```bash
cd infra/terraform/bootstrap/state
terraform destroy
```

---

## 🚀 Local Development
### Backend
```bash
./mvnw clean package -DskipTests
java -jar artifacts/tasktracker.jar
```
Note: The application JAR is not stored in Git.
Build locally before deployment:
./mvnw clean package -DskipTests

### Health Check:
```bash
curl http://localhost:8080/health
```

---

### Frontend
```bash
cd frontend/tasktracker-ui
npm install
npm run dev
```

---

### Frontend runs at:
```arduino
http://localhost:5173
```

---
## 🏗 Infrastructure Overview (Phase 4 Complete)
### Remote Terraform State
- S3 backend bucket
- DynamoDB state locking
- Fully destroyable bootstrap

### App Storage
- Dedicated S3 bucket for attachments
- Versioning enabled
- Lifecycle rules (auto-expire dev objects)
- Public access blocked
- Optional (commented) KMS encryption
- Optional (commented) CloudTrail data events

### Secrets Strategy
- SSM Parameter Store (SecureString) as default
- Optional Secrets Manager proof
- Optional RDS managed master password toggle

### Data Service
- PostgreSQL (RDS)
- Cost-controlled defaults:
    - db.t4g.micro
    - 20GB gp3
    - Single AZ
- Optional proof toggles:
    - Multi-AZ
    - Managed master password (Secrets Manager-backed)

### Fargate Guardrails (Pre-Compute Safety)
- CloudWatch log retention guardrail
- Optional AWS Budget integration
- NAT Gateway demonstration block (disabled by default)

### Networking Foundation
- Custom VPC provisioned for application workloads
- Public subnets across multiple AZs
- Internet Gateway + public routing
- Baseline security groups for workload access
- RDS aligned to the custom VPC for EC2-based connectivity

### Compute Platform – ECS Fargate
- ECS Cluster provisioned
- CloudWatch ECS log group integrated
- Fargate service skeleton deployed
- Public-IP task networking model validated
- Terraform → CloudFormation orchestration confirmed
- ALB integration
- private task access model enforced (ALB-only ingress)
- health check routing
- stable deployment behavior

### Compute Platform – EC2
- EC2 instance provisioning validated in custom VPC
- Public-IP access model validated for direct application testing
- Port 8080 access enabled for direct application testing
- EC2 bootstrap via user_data implemented
- EC2 bootstrap logging enabled via user_data for troubleshooting and validation
- Spring Boot JAR uploaded automatically to S3 during Terraform apply (no manual deployment steps required)
- EC2 IAM role and instance profile added for secure S3 artifact retrieval and SSM Parameter Store access
- Application configuration injected dynamically from SSM Parameter Store
- EC2 → RDS connectivity validated end-to-end
- Full deploy → test → destroy lifecycle validated

### Application Layer

- ALB → ECS → RDS architecture
- HTTP routing via ALB
- health check endpoint
- zero direct task exposure

### Container Delivery Pipeline
- Docker multi-stage Java 17 build
- ECR repository lifecycle verified
- linux/amd64 image compatibility enforced
- ECS deployment stability validated (circuit breaker + health checks)

All infrastructure is:
- Modular
- Toggleable
- Destroyable
- Cost-conscious by design

---

## 💰 Cost & Safety Principles
- All AWS work is designed to be:
  - Free-tier aware where possible
  - Fully tear-downable
  - Explicitly controlled via IaC
- Expensive features are implemented behind toggles:
    - Multi-AZ
    - Managed RDS master password
    - Secrets Manager
    - NAT Gateway
- Monthly budget alerts configured at account level
- Default working region: us-east-2 (Ohio)
- Environment remains fully inert when destroyed
- Frequent stand-up / tear-down workflow prevents cost creep
- Full deploy → validate → destroy lifecycle tested with zero residual resources

---

## 🔒 Security Practices
- Root account MFA enabled
- Dedicated IAM admin user with MFA
- IAM billing access enabled (no root dependency for cost management)
- IAM roles preferred over static credentials
- EC2 instance profile used for application artifact and configuration access
- Least-privilege IAM policies applied progressively
- No credentials committed to source control
- Only architecture tfvars files are committed; all other tfvars (e.g., secrets) are excluded from version control
- Secrets stored in:
    - SSM SecureString (default)
    - Secrets Manager (optional)
    - RDS-managed secret (optional)
- ALB-only ingress to application layer
- ECS tasks not publicly accessible
- Security group isolation enforced

---

## 📍 Current Status

### ✅ Pre-Phase 1 (Application Baseline Complete)
Backend rebuilt and verified
- Canonical JAR artifact created
- Frontend wired and functional
- Local Postgres + CORS validated
- Environment-based configuration confirmed
- GitHub repository structured and published

### ✅ Phase 1 - Foundations & Core Services (Complete)
- AWS account provisioned
- Root MFA configured
- IAM admin user created with MFA
- IAM billing access enabled
- CLI configured with named profile
- AWS Budget guardrail (tasktracker-monthly-budget) created
- Cost alerts configured (80%, 100%, forecasted)
- Default working region selected (us-east-2)
- Professional documentation standards established

Account is secured and cost-guarded.
No billable infrastructure deployed during Phase 1.


### ✅ Phase 2 – Storage & Data Services
- S3 attachments bucket module
- SSM-based secrets management
- Optional Secrets Manager proof
- PostgreSQL RDS module with Multi-AZ toggle
- Managed master password toggle
- Fargate cost guardrails
- Bootstrap + environment teardown validated

### ✅ Phase 3 – Networking & Compute Basics

- Shared networking foundation
  - Custom VPC deployed
  - Public subnets provisioned across multiple AZs
  - Internet Gateway routing configured
  - Cost-safe stand-up / tear-down workflow validated

- Fargate path
  - ECS cluster provisioned and verified
  - Fargate service skeleton deployed
  - CloudWatch log group wired with retention policy
  - Docker multi-stage build pipeline validated (linux/amd64)
  - ECR repository lifecycle verified
  - End-to-end image push → ECS task startup confirmed
  - Full Terraform + CloudFormation orchestration cycle validated

- EC2 path
  - RDS realigned into the custom VPC for EC2 compatibility
  - EC2 instance provisioning validated in the custom VPC
  - Port 8080 access enabled for direct application testing
  - EC2 bootstrap via user_data implemented
  - JAR delivery automated through Terraform-managed S3 upload
  - EC2 IAM role + instance profile added for S3 and SSM access
  - Application configuration loaded dynamically from SSM Parameter Store
  - `/health` endpoint validated on EC2
  - EC2 → RDS connectivity validated through end-to-end CRUD API testing
  - Full deploy → validate → destroy lifecycle confirmed with zero residual resources

### ✅ Phase 4: Application Deployment & Security
- ALB introduced and validated
- ECS service behind ALB (no direct access)
- Target group + health checks configured (/health)
- Deployment stability features:
  - circuit breaker (rollback enabled)
  - health check grace period
  - rolling deployment tuning
- IAM role separation:
  - execution role vs task role
- Security group refinement:
  - ALB public access only
  - ECS restricted to ALB only
- Full deploy → test → destroy workflow validated

---

The project is now ready for:

### 🔜 Next Steps
- Bring EC2 deployment to Phase 4 parity (ALB + security hardening)
- Implement Elastic Beanstalk architecture

### ⏭️ Phase 5: Identity, Access Management & Monitoring

---

## 📚 Reference

- AWS Certified Solutions Architect – Associate (SAA-C03)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;https://aws.amazon.com/certification/certified-solutions-architect-associate/

---
