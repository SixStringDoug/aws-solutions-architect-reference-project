# AWS SAA Project – Study App (SAA-C03)

This repository contains a hands-on study project designed to reinforce concepts from the  
**AWS Certified Solutions Architect – Associate (SAA-C03)** exam.

The project centers on a **single, intentionally simple full-stack CRUD application** that is deployed multiple times using different AWS compute and deployment models.  
The goal is to demonstrate **architectural tradeoffs**, not application complexity.

---

## 🎯 Project Goals
- Practice AWS core services (EC2, ALB, RDS, ECS/Fargate, S3, IAM, CloudWatch)
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
    - `SPRING_PROFILES_ACTIVE` (`ec2`, `fargate`, `local`)
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
terraform fmt -recursive
terraform validate
```

Choose Fargate or EC2 deployment **(choose only one configuration)**.

Fargate:
```bash
# Confirm:
# infra/terraform/env/dev/test-fargate.tfvars
# enable_cloudformation = false

terraform apply -var-file="test-fargate.tfvars"

# Return to project root
cd ../../../../
# Build Docker image, push to ECR,
# and publish nested CloudFormation artifacts
./infra/scripts/push-backend-image.sh ph4

# Confirm:
# infra/terraform/env/dev/test-fargate.tfvars
# enable_cloudformation = true

cd infra/terraform/env/dev
terraform init -reconfigure
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
Note: The application JAR is not stored in Git.  Build locally before deployment:
```bash
./mvnw clean package -DskipTests
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
## 🏗 Infrastructure Overview
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
- Public and private subnets provisioned across multiple AZs
- Internet Gateway + public routing configured
- NAT Gateway routing implemented for private subnet outbound access
- Baseline security groups for workload isolation
- Public ALB → private compute routing model implemented
- RDS aligned to the custom VPC for EC2 and Fargate connectivity

### Compute Platform – ECS Fargate
- ECS Cluster provisioned
- CloudWatch ECS log group integrated
- Fargate service deployed via CloudFormation (nested stack)
- Terraform → CloudFormation orchestration model implemented
- Security group ownership moved to Terraform to eliminate cross-stack dependency issues
- ALB integration with target group and `/health` checks
- Health check tuning implemented:
  - Increased grace period for application startup latency
  - Adjusted healthy/unhealthy thresholds for stability
- Private task access model enforced (ALB-only ingress)
- RDS connectivity via Terraform-managed security group rules
- Stable deployment behavior validated (no task cycling)
- ECS multi-task deployment validated
- ECS service auto scaling implemented and validated
- ECS deployment resiliency enhancements implemented
- ECS deployment circuit breaker with rollback enabled and validated
- ECS rolling deployment behavior validated through forced redeployment testing
- CloudWatch Fargate healthy host alarm added for service availability visibility
- CloudWatch Fargate ALB target 5XX alarm added for application failure visibility
- Terraform outputs added for Fargate operational monitoring resources
- Automated nested CloudFormation artifact publishing integrated into deployment workflow
- Full deploy → validate → destroy lifecycle validated

### Compute Platform – EC2
- EC2 instance provisioning validated in custom VPC
- Spring Boot JAR uploaded automatically to S3 during Terraform apply
- EC2 bootstrap via user_data implemented
- EC2 bootstrap logging enabled via user_data for troubleshooting and validation
- EC2 IAM role and instance profile used for secure S3 artifact retrieval and SSM Parameter Store access
- Application configuration injected dynamically from SSM Parameter Store
- ALB introduced as the public application entry point
- EC2 application access restricted to ALB-only ingress
- Target group health checks configured against `/health`
- RDS access restricted to the EC2 application security group
- EC2 → RDS CRUD validation completed through ALB
- Dedicated CloudWatch log group added for EC2 operational logs
- CloudWatch Agent integrated into EC2 bootstrap workflow
- EC2 bootstrap logs streamed to CloudWatch
- EC2 application logs streamed to CloudWatch
- IAM permissions refined for CloudWatch log publishing
- EC2 operational observability validated end-to-end
- CloudWatch EC2 status check alarms added for infrastructure health monitoring
- CloudWatch ALB unhealthy host alarms added for target health visibility
- CloudWatch ALB target 5XX alarms added for application failure visibility
- Terraform outputs added for operational monitoring resources
- Launch Template introduced for immutable EC2 instance configuration
- Auto Scaling Group (ASG) introduced for resilient EC2 orchestration
- Multi-instance EC2 deployment validated across multiple Availability Zones
- ALB target registration managed dynamically through ASG integration
- EC2 desired/min/max capacity controls implemented
- EC2 instance replacement behavior validated through intentional termination testing
- Self-healing ASG recovery behavior validated end-to-end
- Private EC2 subnet deployment implemented
- Public internet-facing ALB separated from private EC2 application tier
- NAT-backed outbound bootstrap access validated for private EC2 instances
- Public IP assignment removed from EC2 application instances
- Full CRUD validation completed through ALB → private EC2 → RDS routing path
- Full deploy → validate → destroy lifecycle validated

### Application Layer

- ALB → ECS → RDS architecture (Fargate)
- Public ALB → private EC2 Auto Scaling Group → private RDS architecture (EC2)
- Multi-instance EC2 resiliency validated through Auto Scaling replacement behavior
- ECS rolling deployment behavior validated through forced redeployment testing
- ECS deployment resiliency validated with zero-downtime task replacement behavior
- HTTP routing via ALB
- `/health` endpoint used for load balancer health checks
- Zero direct task exposure (Fargate)
- Zero direct instance exposure (EC2)
- Shared backend artifact deployed across both compute models
- Environment-driven configuration ensures identical behavior across architectures

### Container Delivery Pipeline
- Docker multi-stage Java 17 build
- ECR repository lifecycle verified
- linux/amd64 image compatibility enforced
- ECS deployment stability validated (circuit breaker and health checks)
- Cross-architecture deployment validated using the same backend application codebase across containerized Fargate and JAR-based EC2 workflows

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
- EC2 CloudWatch logging permissions scoped to dedicated log group
- No credentials committed to source control
- Only architecture tfvars files are committed; all other tfvars (e.g., secrets) are excluded from version control
- Secrets stored in:
    - SSM SecureString (default)
    - Secrets Manager (optional)
    - RDS-managed secret (optional)
- ALB-only ingress to application layer
- ECS tasks not publicly accessible
- EC2 application instance not directly publicly accessible
- EC2 application ingress restricted to ALB security group only
- RDS ingress restricted to application security groups only
- Security group isolation enforced

---

## 📍 Current Status

### ✅ Pre-Phase 1
Backend rebuilt and verified
- Canonical JAR artifact created
- Frontend wired and functional
- Local Postgres + CORS validated
- Environment-based configuration confirmed
- GitHub repository structured and published

### ✅ Phase 1 - Foundations & Core Services
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
- Fargate path
  - ALB introduced and validated
  - ECS service deployed via CloudFormation nested stack
  - Terraform-managed networking and security groups (single source of truth)
  - Target group + `/health` checks configured
  - Deployment stability tuning:
    - increased health check grace period
    - adjusted ALB health thresholds
    - ECS circuit breaker (rollback enabled)
  - Resolved cross-stack dependency issue between Terraform and CloudFormation
  - RDS connectivity validated through security group alignment
  - Stable ECS service (no task churn)
  - Full destroy → deploy → validate lifecycle confirmed from clean state

- EC2 path
  - ALB introduced and validated
  - EC2 application routing moved behind ALB
  - Target group + health checks configured (/health)
  - EC2 public port 8080 access removed
  - EC2 application ingress restricted to ALB security group only
  - RDS public database access removed
  - RDS ingress restricted to EC2 security group only
  - EC2 IAM decrypt permissions refined for SSM SecureString access
  - ALB → EC2 → RDS CRUD flow validated end-to-end
  - Dedicated CloudWatch log group integrated for EC2 operational visibility
  - EC2 bootstrap logs centralized in CloudWatch
  - EC2 application runtime logs centralized in CloudWatch
  - CloudWatch Agent installation and lifecycle validated on Amazon Linux 2023
  - Full destroy → deploy → validate lifecycle confirmed from clean state

### ✅ Phase 5: Identity, Access Management & Monitoring
- Fargate path
  - Fargate IAM roles and CloudWatch logging reviewed
  - Fargate healthy host monitoring implemented
  - Fargate ALB target 5XX monitoring implemented
  - Terraform operational outputs added for Fargate monitoring visibility
  - Fargate Phase 5 monitoring validated from clean deploy

- EC2 path
  - EC2 CloudWatch infrastructure alarms implemented
  - ALB unhealthy target monitoring implemented
  - ALB target 5XX monitoring implemented
  - Terraform operational outputs added for monitoring visibility
  - EC2 Phase 5 monitoring validated from clean deploy

### ✅ Phase 6: Resilience & Performance
- Fargate path
  - Private Fargate task subnet migration completed
  - Public ALB retained as internet ingress layer
  - ECS tasks no longer publicly addressable
  - Multi-task ECS deployment validated
  - ECS service auto scaling implemented and validated
  - ECS deployment resiliency enhancements implemented
  - ECS deployment circuit breaker with rollback enabled validated
  - ECS rolling deployment behavior validated through forced redeployment testing
  - Automated nested CloudFormation artifact publishing integrated into deployment workflow
  - Full private-task ALB → ECS → RDS CRUD validation completed
  - Full deploy → validate → destroy lifecycle validated after resiliency enhancements

- EC2 path
  - Launch Template introduced for immutable infrastructure behavior
  - Auto Scaling Group (ASG) introduced
  - Multi-instance deployment validated across multiple Availability Zones
  - Desired/min/max capacity controls implemented
  - ALB target registration integrated with ASG lifecycle
  - Instance replacement behavior validated through intentional EC2 termination
  - Self-healing recovery validated end-to-end
  - Private EC2 subnet migration completed
  - Public ALB retained as internet ingress layer
  - EC2 application instances no longer publicly addressable
  - NAT-backed outbound bootstrap access validated
  - Full ALB → private EC2 → RDS CRUD validation completed
  - Full deploy → validate → destroy lifecycle validated after resiliency migration


### ✅ Phase 7: Governance, Automation & Cost Management
- AWS Well-Architected Tool Review
  - AWS Well-Architected Framework review completed against the EC2 architecture
  - Workload evaluated across all six Well-Architected pillars
  - Existing architecture validated against AWS best practices
  - Improvement opportunities identified for distributed tracing, telemetry, and enterprise governance processes

- Cost Visibility & Budget Governance
  - AWS Budget alerts reviewed and validated
  - Cost Explorer used to review service-level spending across project resources
  - Cost governance workflow validated through deploy → validate → destroy lifecycle discipline
  - Cost allocation tag strategy reviewed for deployed resources

- RDS Backup & Snapshot Strategy
  - RDS automated backup retention exposed as a Terraform variable
  - Low-cost one-day retention retained for the dev workload
  - Final snapshots remain disabled during destroy to preserve clean teardown behavior
  - AWS Backup plans deferred as unnecessary for this single-developer educational project

- S3 Storage Recovery Review
  - S3 versioning retained to support object recovery
  - Lifecycle rules retained to control long-term dev storage costs
  - Public access block, SSE-S3 encryption, and secure transport enforcement reviewed and validated
  - Optional SSE-KMS and CloudTrail S3 data event configurations retained as future production-oriented enhancements
  - AWS Backup, cross-region replication, and Object Lock deferred as unnecessary for this destroyable dev workload

- Safe CI Validation Workflow
  - GitHub Actions workflow added for backend build validation
  - Backend artifact build integrated into Terraform validation workflow
  - Terraform formatting and validation checks added
  - CI intentionally avoids AWS deployment to prevent accidental resource creation
  - Workflow supports both EC2 and Fargate paths by validating shared application and infrastructure code

---

## 🧠 Key Architectural Lessons Learned

### Infrastructure & Orchestration
- Infrastructure ownership must be clearly defined:
  - Terraform owns networking and security groups
  - CloudFormation consumes those resources
- Cross-stack dependencies (Terraform ↔ CloudFormation) can cause timing failures if not properly designed
- Nested CloudFormation stacks require deterministic artifact publication workflows to prevent deployment drift
- Shared infrastructure can support multiple independent compute models when architectural boundaries remain clean

### Deployment & Resiliency
- Application startup time must be aligned with ALB health check configuration
- ECS task failures are often orchestration issues—not application failures
- Infrastructure resiliency validation should include intentional failure testing, not only successful deployments
- Immutable replacement behavior is easier to validate and reason about than in-place instance repair
- Not every configurable infrastructure behavior should be exposed as a parameter
- ECS deployment resiliency features are more reliable as architecture defaults than environment toggles
- Clean-room rebuild testing exposes deployment lifecycle issues that incremental updates can hide

### Networking & Architecture
- Public load balancers and private compute tiers should use independently controlled subnet placement
- Private application tiers improve security posture while preserving public application accessibility through ALBs
- Auto Scaling Groups fundamentally change EC2 lifecycle ownership and recovery behavior
- A single application artifact can successfully support multiple compute platforms when configuration is externalized

---

## 🧪 Validation Summary

Both compute paths have been fully validated from a **clean destroyed state**:

### Fargate Validation
- ✅ Fargate: deploy → stabilize → serve traffic → destroy
- ✅ ECS multi-task deployment validated
- ✅ ECS service auto scaling implemented and validated
- ✅ ECS rolling deployment behavior validated through forced redeployment testing
- ✅ Automated nested CloudFormation artifact publishing workflow validated from clean state
- ✅ Full private-task ALB → ECS → RDS architecture validated end-to-end

### EC2 Validation
- ✅ EC2: deploy → stabilize → serve traffic → destroy
- ✅ EC2 Auto Scaling replacement behavior validated through intentional instance termination
- ✅ Private EC2 subnet architecture validated successfully
- ✅ Public ALB → private EC2 → private RDS architecture validated end-to-end

### Shared Validation
- ✅ Shared services (RDS, SSM, S3) function correctly across both architectures
- ✅ CloudWatch logging validated independently for both EC2 and Fargate paths
- ✅ No residual dependencies between compute models
- ✅ Full clean-room rebuild validation completed for both architectures

This confirms a **production-aligned, architecture-agnostic deployment model**.

---

### The project is now ready for:

### ⏭️ Phase 7: Governance, Automation & Cost Management

---

## 📚 Reference

- AWS Certified Solutions Architect – Associate (SAA-C03)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;https://aws.amazon.com/certification/certified-solutions-architect-associate/

---
