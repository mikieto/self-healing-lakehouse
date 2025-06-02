# rds.tf - Enterprise RDS with VPC Integration

module "lakehouse_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "lakehouse-db-${random_id.bucket_suffix.hex}"

  # Engine configuration
  engine               = "postgres"
  engine_version       = "15.7"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.micro"

  # Storage (enterprise-grade)
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  # Database
  db_name                     = "lakehouse"
  username                    = "dbadmin" # Changed from "admin" (PostgreSQL reserved word)
  manage_master_user_password = true      # AWS Secrets Manager

  # Network - enterprise VPC integration
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false # Enterprise security

  # Enterprise backup requirements
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Enterprise monitoring
  monitoring_interval          = 60
  monitoring_role_name         = "rds-monitoring-${random_id.bucket_suffix.hex}"
  create_monitoring_role       = true
  performance_insights_enabled = true

  # Multi-AZ for enterprise reliability
  multi_az = var.environment == "prod"

  # Environment-based deletion protection
  deletion_protection = var.environment == "prod"
  skip_final_snapshot = var.environment != "prod"

  tags = {
    Name        = "lakehouse-database"
    Purpose     = "self-healing-lakehouse"
    Environment = var.environment
    NetworkMode = "enterprise"
    Tier        = "database"
  }
}

# Enterprise Glue Connection
resource "aws_glue_connection" "rds" {
  name = "lakehouse-rds-${random_id.bucket_suffix.hex}"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${module.lakehouse_rds.db_instance_endpoint}/lakehouse"
    USERNAME            = "dbadmin" # Changed from "admin"
    PASSWORD            = module.lakehouse_rds.db_instance_master_user_secret_arn
  }

  physical_connection_requirements {
    availability_zone      = module.lakehouse_rds.db_instance_availability_zone
    security_group_id_list = [aws_security_group.application.id]
    subnet_id              = module.vpc.private_subnets[0]
  }

  tags = {
    Name = "lakehouse-rds-connection"
    Type = "enterprise"
  }
}

# Enterprise IAM permissions
resource "aws_iam_role_policy_attachment" "glue_rds_access" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
}

# Outputs
output "rds_connection_info" {
  description = "RDS connection information"
  value = {
    endpoint     = module.lakehouse_rds.db_instance_endpoint
    port         = module.lakehouse_rds.db_instance_port
    database     = module.lakehouse_rds.db_instance_name
    username     = module.lakehouse_rds.db_instance_username
    secret_arn   = module.lakehouse_rds.db_instance_master_user_secret_arn
    network_mode = "enterprise"
    vpc_id       = module.vpc.vpc_id
    subnet_group = module.vpc.database_subnet_group
  }
  sensitive = true
}

output "rds_enterprise_features" {
  description = "Enterprise features status"
  value = {
    vpc_isolation    = "complete"
    security_groups  = "3-tier-architecture"
    glue_integration = "enterprise"
    monitoring       = "enhanced"
    backup_strategy  = "enterprise_compliant"
    encryption       = "enabled"
    multi_az         = var.environment == "prod" ? "enabled" : "single_az_dev"
    network_tier     = "private_database_subnets"
  }
}