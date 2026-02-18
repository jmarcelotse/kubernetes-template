terraform {
  backend "s3" {
    bucket       = "terraform-state-eks-template"
    key          = "staging/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true

    # Tags for the state object
    # Note: DynamoDB is NOT used for locking - S3 native locking is used instead
  }
}
