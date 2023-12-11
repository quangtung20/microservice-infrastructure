module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "fgms-vpc"
  cidr = "13.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b"]
  private_subnets  = ["13.0.1.0/24", "13.0.2.0/24"]
  public_subnets   = ["13.0.101.0/24", "13.0.102.0/24"]
  database_subnets = ["13.0.51.0/24", "13.0.52.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    group       = "fgms"
    Environment = "dev"
  }
}
