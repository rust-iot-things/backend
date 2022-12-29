terraform {
  required_version = ">0.14.7"
  backend "s3" {}

  required_providers {
    aws = {
      version = "~> 4.48"
      source  = "hashicorp/aws"
    }
  }
}
