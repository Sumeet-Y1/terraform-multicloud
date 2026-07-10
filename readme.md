# terraform-multicloud

Terraform configurations for infrastructure across **AWS**, **Azure**, and **GCP**.

## Structure

```
terraform-multicloud/
├── aws/
│   ├── networking/
│   ├── compute/
│   └── storage/
├── azure/
│   ├── networking/
│   ├── compute/
│   └── storage/
├── gcp/
│   ├── networking/
│   ├── compute/
│   └── storage/
├── modules/        # shared/reusable modules (used across providers or environments)
├── envs/           # environment-specific tfvars (dev, staging, prod)
│   ├── dev/
│   ├── staging/
│   └── prod/
└── README.md
```

Each provider folder is split by concern (networking, compute, storage) so resources stay organized and easy to navigate as the repo grows.

## Usage

Each subfolder is meant to be run independently (or wired together via `modules/`):

```bash
cd aws/networking
terraform init
terraform plan
terraform apply
```

## Conventions

- Each `.tf` set includes `main.tf`, `variables.tf`, and `outputs.tf`.
- Environment-specific values (region, instance sizes, etc.) go in `envs/<env>/*.tfvars`, not hardcoded in the modules.
- Shared logic (tagging, naming conventions, common IAM patterns) belongs in `modules/`.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform) >= 1.5
- Provider CLI credentials configured locally:
    - AWS: `aws configure`
    - Azure: `az login`
    - GCP: `gcloud auth application-default login`

## Roadmap

- [ ] Add remote state backend config (S3/Azure Storage/GCS) per provider
- [ ] Add CI (terraform fmt/validate/plan) via GitHub Actions
- [ ] Add example `.tfvars` per environment