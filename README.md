# Terraform Service Catalog

Reusable Terraform modules and service configurations for AWS infrastructure.

## Modules

| Module | Description |
|--------|-------------|
| `vpc` | VPC with public subnet, Internet Gateway, Route Tables |
| `ec2-app` | Application server EC2 instance |
| `ec2-db` | Database server EC2 instance |
| `security` | Security groups for App and DB servers |
| `iam` | IAM roles and instance profiles |

## Services

| Service | Description |
|---------|-------------|
| `aws-app-db` | Complete 2-tier application stack (App + DB) |

## Usage with Terraform Cloud

### 1. Create Workspace

```bash
# Login to Terraform Cloud
terraform login

# Initialize with cloud backend
cd services/aws-app-db
terraform init
```

### 2. Configure Variables in Terraform Cloud

**Environment Variables:**
- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)

**Terraform Variables:**
- `key_name` - Your AWS SSH key name
- `db_password` - Database password (sensitive)

### 3. Run

```bash
terraform plan
terraform apply
```

## Module Documentation

### VPC Module

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "us-east-1a"
  environment        = "dev"
  tags               = {}
}
```

### EC2 App Module

```hcl
module "app" {
  source = "../../modules/ec2-app"

  ami_id               = "ami-xxxxx"
  instance_type        = "t2.micro"
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security.app_sg_id
  key_name             = "my-key"
  iam_instance_profile = module.iam.instance_profile_name
  app_name             = "flask-app"
  environment          = "dev"
}
```

### EC2 DB Module

```hcl
module "db" {
  source = "../../modules/ec2-db"

  ami_id               = "ami-xxxxx"
  instance_type        = "t2.micro"
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security.db_sg_id
  key_name             = "my-key"
  iam_instance_profile = module.iam.instance_profile_name
  environment          = "dev"
}
```

