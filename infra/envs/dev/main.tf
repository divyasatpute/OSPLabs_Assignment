module "network" {

  source = "../../modules/network"

  project_name = "bookingapp"

  environment = "dev"

  region = var.region

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_app_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  private_db_subnets = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]

}

module "security" {

  source = "../../modules/security"

  project_name = "bookingapp"

  environment = "dev"

  vpc_id = module.network.vpc_id

}

module "iam" {

  source = "../../modules/iam"

  project_name = "bookingapp"

  environment = "dev"

}

module "logs" {

  source = "../../modules/logs"

  project_name = "bookingapp"

  environment = "dev"

  retention_in_days = 7

}

module "alb" {

  source = "../../modules/alb"

  project_name = "bookingapp"

  environment = "dev"

  vpc_id = module.network.vpc_id

  public_subnets = module.network.public_subnets

  alb_security_group = module.security.alb_sg_id

}

module "ecs" {

  source = "../../modules/ecs"

  project_name = "bookingapp"

  environment = "dev"

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
  # ECS
  #################################

  cpu = 256

  memory = 512

  desired_count = 2

}

module "rds" {

  source = "../../modules/rds"

  project_name = "bookingapp"

  environment = "dev"

  db_name = "bookingdb"

  db_username = "postgres"

  db_password = var.db_password

  private_db_subnets = module.network.private_db_subnets

  rds_security_group = module.security.rds_sg_id

  instance_class = "db.t3.micro"

  allocated_storage = 20

  backup_retention_period = 1

  deletion_protection = false

}
