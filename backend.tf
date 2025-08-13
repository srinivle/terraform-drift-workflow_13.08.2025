terraform {
  backend "s3" {
    # Backend configuration will be provided via backend-config during init
    # bucket = "my-terraform-state-bucket"
    # key    = "terraform/region/account-id/terraform.tfstate"
    # region = "us-east-1"
  }
}