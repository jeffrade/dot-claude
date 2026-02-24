---
name: dns-setup
description: "Load this skill when setting up DNS for a new subdomain under an existing parent domain without provisioning full infrastructure. Covers the complete workflow: AWS CLI hosted zone creation, Terraform A record and NS delegation configuration, git-ignored terraform.tfvars for sensitive IPs, and DNS verification via dig."
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# DNS Subdomain Setup

Set up DNS configuration for a new subdomain (e.g., `dev.client-example.devixlabs.com`) without creating full infrastructure folders.

## When to Use This Skill

Use this skill when:
- Adding a new subdomain under an existing parent domain
- Need DNS resolution without provisioning other AWS resources
- Want to manage subdomain DNS in the parent domain directory (not a separate folder)
- Have an IP address that should resolve to the subdomain

## Overview

This skill automates the complete workflow for adding Route53 DNS records for a subdomain. It differs from full domain setup by:
- Creating the hosted zone via AWS CLI (avoiding Terraform state management)
- Managing all records in the parent domain's Terraform configuration
- Storing sensitive IPs in git-ignored `terraform.tfvars` files
- Using Terraform data sources to reference the hosted zone

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform installed
- `openssl` available (for generating random caller reference)
- Working directory in the parent domain folder (e.g., `devixlabs.com/`)

## Step-by-Step Workflow

### Step 1: Create the Hosted Zone via AWS CLI

Create the Route53 hosted zone for the subdomain using a random caller reference to ensure uniqueness:

```bash
aws route53 create-hosted-zone \
  --name client-example.devixlabs.com \
  --caller-reference $(openssl rand -hex 16)
```

**Output to note:** The response contains the Zone ID and 4 nameservers. These will be used in the next steps.

### Step 2: Create Terraform Configuration File

Create a new file in the parent domain directory (e.g., `devixlabs.com/client-example-dns.tf`) containing:
- Variable definition for the sensitive IP address
- Data source to reference the newly created hosted zone
- Resource for the A record pointing to the subdomain
- Resource for NS delegation in the parent zone
- Outputs for verification

**Template structure:**
```hcl
variable "client_example_dev_ip" {
  description = "IP address for dev.client-example.devixlabs.com A record"
  type        = string
  sensitive   = true
}

data "aws_route53_zone" "client_example" {
  name = "client-example.devixlabs.com."
}

data "aws_route53_zone" "selected" {
  name = "devixlabs.com."
}

resource "aws_route53_record" "client_example_dev" {
  zone_id = data.aws_route53_zone.client_example.zone_id
  name    = "dev.client-example.devixlabs.com"
  type    = "A"
  ttl     = 300
  records = [var.client_example_dev_ip]
}

resource "aws_route53_record" "client_example_ns_delegation" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "client-example.devixlabs.com"
  type    = "NS"
  ttl     = 300
  records = data.aws_route53_zone.client_example.name_servers
}

output "client_example_nameservers" {
  description = "Nameservers for client-example.devixlabs.com zone"
  value       = data.aws_route53_zone.client_example.name_servers
}

output "client_example_dev_fqdn" {
  description = "Fully qualified domain name for dev subdomain"
  value       = aws_route53_record.client_example_dev.fqdn
}
```

### Step 3: Create .gitignore File

Create or update `devixlabs.com/.gitignore` to protect sensitive files:

```
# Terraform sensitive values
terraform.tfvars

# Terraform state
*.tfstate
*.tfstate.*
.terraform/
```

### Step 4: Create terraform.tfvars File

Create `devixlabs.com/terraform.tfvars` (git-ignored) with the sensitive IP:

```hcl
client_example_dev_ip = "192.168.1.100"
```

**Important:** This file will not be tracked by git due to .gitignore.

### Step 5: Initialize and Apply Terraform

Run in the parent domain directory:

```bash
cd devixlabs.com/
terraform init
terraform plan
terraform apply
```

Verify that Terraform creates 3 resources:
- `data.aws_route53_zone.client_example` (data source)
- `aws_route53_record.client_example_dev` (A record)
- `aws_route53_record.client_example_ns_delegation` (NS delegation)

### Step 6: Verify DNS Resolution

Test DNS resolution using one of the nameservers from the hosted zone creation:

```bash
dig @ns-74.awsdns-09.com dev.client-example.devixlabs.com A
```

Expected output should show:
- Status: NOERROR
- Answer section with your IP address
- TTL: 300 (or your configured value)

## Verification Checklist

- [ ] Hosted zone created via AWS CLI
- [ ] `<subdomain>-dns.tf` file created in parent domain directory
- [ ] `.gitignore` updated with `terraform.tfvars`
- [ ] `terraform.tfvars` created and git-ignored
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` shows 3 resources to create
- [ ] `terraform apply` completed without errors
- [ ] DNS resolution test successful (dig returns correct IP)
- [ ] `terraform plan` shows "No changes" on second run

## Key Design Decisions

### Why AWS CLI for Hosted Zone Creation?
- Avoids Terraform state management for the zone itself
- The zone is created once and referenced by Terraform via data source
- Reduces coupling between parent and child zones

### Why git-ignored terraform.tfvars?
- Sensitive IP addresses should never be committed to version control
- Allows different environments to have different IPs without changing code
- Team members can configure their own values locally

### Why DNS in Parent Directory?
- Keeps related DNS records together
- Easier to manage DNS for multiple subdomains
- Avoids creating separate folders for DNS-only configurations

## Adding Additional Subdomains

To add another subdomain under the same parent zone (e.g., `api.client-example.devixlabs.com`):

1. Add a new variable: `client_example_api_ip`
2. Add new A record resource: `aws_route53_record.client_example_api`
3. Update `terraform.tfvars` with the new IP
4. Run `terraform plan && terraform apply`

## Troubleshooting

### "No matching Route53 Zone found" Error
- Verify the hosted zone was created: `aws route53 list-hosted-zones`
- Ensure zone name ends with a dot: `greenwood.devixlabs.com.`
- Check that AWS credentials are valid

### "Terraform has no changes" After Apply
- This is normal on second run - indicates no drift
- Run `terraform state list` to verify resources exist

### DNS Not Resolving
- Wait for TTL propagation (usually 5 minutes)
- Verify using the correct nameserver from hosted zone creation
- Check that NS delegation record was created in parent zone: `aws route53 list-resource-record-sets --hosted-zone-id <zone-id>`

## Related Documentation

See `iac-conventions` skill for:
- Full new domain setup workflow (register.sh → init.sh → terraform apply → publish.sh)
- AWS provider configuration details
- Other iac workflows and known technical debt
