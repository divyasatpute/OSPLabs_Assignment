module "network" {

  source = "../../modules/network"

  project_name = "bookingapp"

  environment = "prod"

  region = var.region

  vpc_cidr = "10.1.0.0/16"

  availability_zones = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  public_subnets = [
    "10.1.1.0/24",
    "10.1.2.0/24"
  ]

  private_app_subnets = [
    "10.1.11.0/24",
    "10.1.12.0/24"
  ]

  private_db_subnets = [
    "10.1.21.0/24",
    "10.1.22.0/24"
  ]

}

module "security" {

  source = "../../modules/security"

  project_name = "bookingapp"

  environment = "prod"

  vpc_id = module.network.vpc_id

}

module "iam" {

  source = "../../modules/iam"

  project_name = "bookingapp"

  environment = "prod"

}

module "logs" {

  source = "../../modules/logs"

  project_name = "bookingapp"

  environment = "prod"

  retention_in_days = 30

}

module "alb" {

  source = "../../modules/alb"

  project_name = "bookingapp"

  environment = "prod"

  vpc_id = module.network.vpc_id

  public_subnets = module.network.public_subnets

  alb_security_group = module.security.alb_sg_id

}

module "ecs" {

  source = "../../modules/ecs"

  project_name = "bookingapp"

  environment = "prod"

  region = var.region

  #################################
  # Network
  #################################

  private_subnets = module.network.private_app_subnets

  ecs_security_group = module.security.ecs_sg_id

  #################################
  # Load Balancer
  #################################

  target_group_arn = module.alb.target_group_arn

  #################################
  # IAM
  #################################

  execution_role_arn = module.iam.execution_role_arn

  #################################
  # Logs
  #################################

  log_group_name = module.logs.log_group_name

  #################################
  # Container
  #################################

  container_name = "nginx"

  container_image = "nginx:latest"

  container_port = 80

  #################################
  # Production Resources
  #################################

  cpu = 512

  memory = 1024

  desired_count = 2

}

module "rds" {

  source = "../../modules/rds"

  project_name = "bookingapp"

  environment = "prod"

  db_name = "bookingdb"

  db_username = "postgres"

  db_password = var.db_password

  private_db_subnets = module.network.private_db_subnets

  rds_security_group = module.security.rds_sg_id

  instance_class = "db.t3.small"

  allocated_storage = 50

  backup_retention_period = 7

  deletion_protection = true

}
