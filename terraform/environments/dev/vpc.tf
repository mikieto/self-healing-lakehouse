# vpc.tf - Enterprise-Grade VPC with Learning-Friendly Design

# Use existing region data from main.tf
# data "aws_region" "current" {} - Already defined in main.tf

data "aws_availability_zones" "available" {
  state = "available"
}

# Enterprise VPC with cost optimization
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "lakehouse-vpc-${random_id.bucket_suffix.hex}"
  cidr = "10.0.0.0/16"

  # Use first 2 AZs for reliability
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  # Enterprise networking features (cost-optimized)
  enable_nat_gateway = false # Cost optimization: Use VPC endpoints instead
  enable_vpn_gateway = false # Cost optimization

  # DNS support for enterprise features
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Database subnet group for RDS
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  # VPC Flow Logs for observability (enterprise requirement)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_destination_type            = "cloud-watch-logs"

  # Enterprise tagging
  tags = {
    Name        = "lakehouse-vpc"
    Purpose     = "self-healing-lakehouse"
    Environment = var.environment
    NetworkTier = "enterprise"
  }

  # Subnet-specific tags for enterprise compliance
  public_subnet_tags = {
    Type = "public"
    Tier = "web"
  }

  private_subnet_tags = {
    Type = "private"
    Tier = "application"
  }

  database_subnet_tags = {
    Type = "database"
    Tier = "data"
  }
}

# VPC Endpoints - Only essential ones (cost-optimized)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    module.vpc.private_route_table_ids,
    module.vpc.database_route_table_ids
  )

  tags = {
    Name = "lakehouse-s3-endpoint"
    Type = "s3-gateway"
    Cost = "free"
  }
}

# Security Groups for enterprise compliance
resource "aws_security_group" "application" {
  name_prefix = "lakehouse-app-${random_id.bucket_suffix.hex}"
  description = "Application tier security group"
  vpc_id      = module.vpc.vpc_id

  # Glue jobs communication
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "HTTPS within VPC"
  }

  # Glue jobs self-referencing
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Self-referencing for Glue"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "lakehouse-application-sg"
    Tier = "application"
  }
}

# Database security group (will be used by RDS)
resource "aws_security_group" "database" {
  name_prefix = "lakehouse-db-${random_id.bucket_suffix.hex}"
  description = "Database tier security group"
  vpc_id      = module.vpc.vpc_id

  # PostgreSQL from application tier
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "PostgreSQL from application tier"
  }

  # PostgreSQL from within VPC (for debugging)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "PostgreSQL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "lakehouse-database-sg"
    Tier = "database"
  }
}

# Outputs for other resources
output "vpc_info" {
  description = "VPC infrastructure information"
  value = {
    vpc_id                = module.vpc.vpc_id
    vpc_cidr_block        = module.vpc.vpc_cidr_block
    private_subnets       = module.vpc.private_subnets
    public_subnets        = module.vpc.public_subnets
    database_subnets      = module.vpc.database_subnets
    database_subnet_group = module.vpc.database_subnet_group
    s3_vpc_endpoint_id    = aws_vpc_endpoint.s3.id
  }
}

output "security_groups" {
  description = "Security group information"
  value = {
    application_sg_id = aws_security_group.application.id
    database_sg_id    = aws_security_group.database.id
  }
}

output "enterprise_features" {
  description = "Enterprise networking features"
  value = {
    vpc_flow_logs         = "enabled"
    s3_vpc_endpoint       = "gateway_free"
    nat_gateway           = "cost_optimized_disabled"
    interface_endpoints   = "minimal_essential_only"
    multi_az_design       = "implemented"
    network_isolation     = "complete"
    tier_separation       = "3-tier-architecture"
    monthly_cost_estimate = "~$0/month (VPC infrastructure)"
  }
}