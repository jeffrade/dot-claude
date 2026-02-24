---
name: iac-conventions
description: "Conventions, patterns, and known issues for the DevixLabs iac project (multi-domain AWS infrastructure via Terraform + Bash scripts). Load this skill when working on Terraform configurations, running register.sh/init.sh/publish.sh, adding new domains, managing Route53 DNS, or troubleshooting iac infrastructure. Also applies when discussing AWS provider versions, S3 state management, SOPS secrets, or per-domain directory isolation."
tools: Bash, Read, Glob, Grep, Edit, Write
---

# iac Conventions — DevixLabs CTO Knowledge

The `iac/` project manages all DevixLabs AWS infrastructure across multiple domains using Terraform (HCL) + Bash scripts. It is the only project that touches real cloud resources.

**Technology**: Terraform, AWS CLI v2+, Bash, SOPS, Packer

---

## Repository Structure

```
iac/
├── main.tf                  # Root: shared S3 state bucket, static site modules
├── main.auto.tfvars         # Hex-based caller references for idempotent hosted zone creation
├── <domain>/                # Per-domain Terraform configuration (isolated)
│   ├── main.tf / *.tf       # Domain-specific resources
│   └── *.auto.tfvars        # Domain-specific variables
├── register.sh              # One-time domain registration via Route53
├── init.sh                  # Hosted zone creation + Terraform module scaffolding
├── publish.sh               # S3 sync with CloudFront-optimized cache headers
├── patch.sh                 # Download and fix 404 responses before republishing
├── setup.sh                 # Environment setup
└── Makefile                 # shellcheck validation only (make check)
```

**Design principle**: Per-domain directory isolation — each domain owns its Terraform config. No cross-domain resource references.

---

## Standard Workflows

### New Domain Setup (complete flow)
```bash
cd iac
./register.sh example.com         # 1. Register domain via Route53
./init.sh example.com             # 2. Create hosted zone + scaffold Terraform module
terraform init && terraform plan && terraform apply  # 3. Provision infrastructure
./publish.sh /path/to/site example.com  # 4. Deploy static content to S3
```

### Standard Terraform Operations
```bash
terraform init
terraform plan
terraform apply
terraform refresh    # Sync state after manual AWS changes
```

### New Subdomain DNS Setup (DNS-only, no new infrastructure)
```bash
# 1. Create hosted zone via AWS CLI (NOT Terraform — avoids resource drift)
aws route53 create-hosted-zone --name sub.example.com --caller-reference $(openssl rand -hex 16)

# 2. Add DNS Terraform file in parent domain folder
# e.g., example.com/subdomain-dns.tf with:
#   - data.aws_route53_zone (reference created zone)
#   - aws_route53_record (A records for subdomain)
#   - NS delegation records from data.aws_route53_zone.name_servers

# 3. Externalize sensitive IPs to git-ignored terraform.tfvars (not auto.tfvars)
# 4. terraform init && terraform plan && terraform apply in parent domain dir
# 5. Verify: dig @<nameserver> <subdomain> A
```

### Site Publishing
```bash
./publish.sh /path/to/site-files domain.com           # Standard sync
./publish.sh /path/to/site-files domain.com --dryrun  # Preview changes
./publish.sh /path/to/site-files domain.com --delete  # Remove deleted files
./publish.sh /path/to/site-files domain.com --exact-timestamps
```

### Validate Scripts
```bash
make check    # shellcheck on all .sh files
```

Always run `make check` after modifying any Bash script. shellcheck errors must be resolved to exit 0.

---

## Deployment Types Supported

| Type | Resources | Example |
|------|-----------|---------|
| Static website | S3 + CloudFront via `cloudmaniac/static-website/aws` | Most domains |
| Kubernetes | EKS + VPC + subnets + security groups | flashpaper.dev/eks |
| Container service | ECS + RDS + ECR | keypost.io |
| DNS-only | Route53 hosted zone + A/CNAME records | Subdomains |

---

## State Management

Central S3 state backend (`tf-state-dlabs` bucket):
```hcl
terraform {
  backend "s3" {
    bucket = "tf-state-dlabs"
    key    = "network/terraform.tfstate"   # or project-specific path
    region = "us-east-1"
  }
}
```

**Known issue**: Only `flashpaper.dev/static` currently has proper S3 backend configuration. Other domains may use local state — dangerous for shared environments. This is tracked technical debt.

---

## Configuration Patterns

**Hex-based caller references** in `main.auto.tfvars`: Used for idempotent hosted zone creation. Each domain has a hex variable that prevents duplicate zone creation on re-apply.

**Sensitive values**: Store in git-ignored `terraform.tfvars` (not in `*.auto.tfvars` which are committed). Example: IP addresses, API keys.

**SOPS encryption**: Used for encrypted configuration management (see keypost.io pattern). Provider: `carlpett/sops ~> 0.5`.

---

## External Modules Reference

| Module | Version | Purpose |
|--------|---------|---------|
| `cloudmaniac/static-website/aws` | v1.0.1 / v1.1 | S3 + CloudFront static sites |
| `cloudposse/dynamic-subnets/aws` | v2.0.4 | VPC subnet management |
| `cloudposse/ecr/aws` | v0.35.0 | Container registry |
| `cloudposse/rds/aws` | v0.40.0 | RDS instances |
| `cloudposse/key-pair/aws` | v0.18.3 | SSH key management |
| `terraform-aws-modules/vpc/aws` | v3.18.1 | VPC infrastructure |
| `terraform-aws-modules/eks/aws` | v19.4.2 | EKS clusters |

**Local module**: `../../../terraform-aws-static-website` (custom static site module)

---

## Known Technical Debt (Don't Introduce More)

1. **AWS provider version drift**: Range from `~> 2.0` to `~> 3.76` across domain configs. Do not add new configs without explicit version pinning.
2. **Missing S3 state backends**: Most domains lack backend config — local state files are risky. When adding new domains, always include S3 backend.
3. **Module version inconsistencies**: `cloudmaniac/static-website/aws` used at both v1.0.1 and v1.1. Pin to v1.1 for new configs.
4. **Unquoted version in jeffra.de**: Uses unquoted `"1.1"` — syntax error requiring fix before next apply.
5. **Missing provider versions**: Several configs lack explicit versioning. Always add explicit constraints.

When working in a domain directory, check its provider version before making changes. The `devixlabs.com` config uses `~> 2.0` (required for Route53 data sources in subdomain DNS patterns).

---

## AWS Provider Versions by Domain

| Domain Config | AWS Provider |
|--------------|-------------|
| `devixlabs.com/` | `~> 2.0` (supports Route53 data sources) |
| `main.tf` | `~> 2.70` |
| `flashpaper.dev/static/` | `~> 3.76` |
| Several others | No version constraint |

---

## Bash Scripts: What Each Does

| Script | Purpose | When to use |
|--------|---------|-------------|
| `register.sh` | Domain registration via Route53 with pre-configured contact info | Once per new domain |
| `init.sh` | Hosted zone creation + Terraform module scaffolding | Once after domain registration |
| `publish.sh` | S3 sync with CloudFront-optimized cache headers | Every content deployment |
| `patch.sh` | Download site, fix 404 responses, prep for re-publish | When recovering broken content |
| `setup.sh` | Environment setup | Initial setup |

All scripts must pass shellcheck. Run `make check` after any script modification.

---

## Relationship to Other DevixLabs Projects

- **templisite** builds static sites → `publish.sh` deploys the `dist/` output to S3
- **kreatisite** handles domain registration (Route53Domains) → iac handles full infrastructure provisioning (S3, CloudFront, EKS, ECS, Route53 zones)
- **appget-generated servers** → iac provisions ECS/EKS they deploy to
- iac provides the infrastructure layer; it does NOT build application code

---

## Security Rules

- Never commit `terraform.tfvars` with sensitive values — always git-ignored
- Use SOPS for encrypted secrets (see keypost.io pattern)
- IAM: least-privilege per service; separate credentials per deployment type
- S3 state bucket (`tf-state-dlabs`): requires appropriate IAM access for all operators
- CloudFront OAI recommended for S3 origins (prevents direct S3 access)
