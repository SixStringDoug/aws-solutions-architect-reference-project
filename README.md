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

## 🚀 Local Development
### Backend
```bash
./mvnw clean package -DskipTests
java -jar artifacts/tasktracker.jar
```
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
## 🏗 Infrastructure Overview (Phase 3 Complete)
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
- VPC provisioned via CloudFormation nested stack
- Public subnets across multiple AZs
- Internet Gateway + public routing
- Baseline security group for container workloads

### Compute Foundation – ECS Fargate Skeleton
- ECS Cluster provisioned
- CloudWatch ECS log group integrated
- Fargate service skeleton deployed
- Public-IP task networking model validated
- Terraform → CloudFormation orchestration confirmed

### Container Delivery Pipeline
- Docker multi-stage Java 17 build
- ECR repository lifecycle verified
- linux/amd64 image compatibility enforced
- ECS deployment stability validated via CLI

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

---

## 🔒 Security Practices
- Root account MFA enabled
- Dedicated IAM admin user with MFA
- IAM billing access enabled (no root dependency for cost management)
- IAM roles preferred over static credentials
- Least-privilege IAM policies applied progressively
- No credentials committed to source control
- .tfvars excluded from version control
- Secrets stored in:
    - SSM SecureString (default)
    - Secrets Manager (optional)
    - RDS-managed secret (optional)

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
- VPC baseline deployed via CloudFormation nested stack
- Public subnets provisioned across multiple AZs
- Internet Gateway routing configured
- ECS cluster provisioned and verified
- Fargate service skeleton deployed
- CloudWatch log group wired with retention policy
- Docker multi-stage build pipeline validated (linux/amd64)
- ECR repository lifecycle verified
- End-to-end image push → ECS task startup confirmed
- CLI-based deployment verification workflow established
- Full Terraform + CloudFormation orchestration cycle validated
- Stand-up / tear-down workflow confirmed cost-safe

The project is now ready for:

### ⏭️ Phase 4: Application Deployment & Security

---

##📚 Reference

- AWS Certified Solutions Architect – Associate (SAA-C03)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;https://aws.amazon.com/certification/certified-solutions-architect-associate/

---
