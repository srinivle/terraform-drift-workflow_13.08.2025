provider "aws" {
  region = var.region
  
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformRole"
  }
  
  default_tags {
    tags = {
      Environment   = var.environment
      ManagedBy     = "Terraform"
      Region        = var.region
      AccountId     = var.account_id
    }
  }
}

# Special provider for China regions
provider "aws" {
  alias  = "china"
  region = var.region
  
  assume_role {
    role_arn = "arn:aws-cn:iam::${var.account_id}:role/TerraformRole"
  }
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.region
      AccountId   = var.account_id
    }
  }
}

# EC2 Instance Module
module "ec2" {
  source = "./modules/ec2"
  
  region      = var.region
  environment = var.environment
  account_id  = var.account_id
  
  instance_type = var.instance_type
  key_pair_name = var.key_pair_name
  
  # Use China provider for China regions
  providers = {
    aws = startswith(var.region, "cn-") ? aws.china : aws
  }
}