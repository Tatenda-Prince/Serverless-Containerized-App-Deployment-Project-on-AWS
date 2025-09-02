# =============================================================================
# ECS (Elastic Container Service) - The Container Management System
# =============================================================================
# This is like a smart factory manager that:
# - Runs your banking app in containers (like shipping containers for code)
# - Automatically replaces containers if they crash
# - Scales up/down based on demand
# - Uses Fargate (AWS manages the servers for you - no server maintenance!)

# Variables for better maintainability
variable "ecr_repository_url" {
  description = "ECR repository base URL"
  type        = string
  default     = "472772625868.dkr.ecr.us-east-1.amazonaws.com"
}

variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  default     = "jwt-secret-key-banking-app-2024-secure"
  sensitive   = true
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  default     = "sqlite:///banking.db"
}

# Create the ECS Cluster - The "factory" that manages all containers
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name  # Name of your container cluster
}

# =============================================================================
# BACKEND TASK DEFINITION - Recipe for Backend Container (Flask API)
# =============================================================================

# Backend Task Definition
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "shell-bank-backend"         # Name for backend task
  network_mode             = "awsvpc"                     # Use AWS VPC networking
  requires_compatibilities = ["FARGATE"]                  # Use Fargate
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"                        # CPU for backend
  memory                   = "512"                        # Memory for backend

  # Backend container configuration
  container_definitions = jsonencode([{
    name  = "backend"
    image = "${var.ecr_repository_url}/shell-bank-backend:latest"
    portMappings = [{
      containerPort = 5000  # Backend runs on port 5000
      hostPort      = 5000
    }]
    environment = [
      {
        name  = "DATABASE_URL"
        value = var.database_url
      },
      {
        name  = "JWT_SECRET_KEY"
        value = var.jwt_secret_key
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/shell-bank-backend"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "backend"
      }
    }
  }])
}

# Backend ECS Service
resource "aws_ecs_service" "backend_service" {
  name            = "shell-bank-backend"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_backend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_target_group.arn
    container_name   = "backend"
    container_port   = 5000
  }

  desired_count = 2
  
  # Ensure proper dependency order for deletion
  depends_on = [aws_lb_listener_rule.api_rule]
}

# =============================================================================
# FRONTEND TASK DEFINITION - Recipe for Frontend Container (React App)
# =============================================================================

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "shell-bank-frontend"        # Name for frontend task
  network_mode             = "awsvpc"                     # Use AWS VPC networking
  requires_compatibilities = ["FARGATE"]                  # Use Fargate
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"                        # CPU for frontend
  memory                   = "512"                        # Memory for frontend

  # Frontend container configuration
  container_definitions = jsonencode([{
    name  = "frontend"
    image = "${var.ecr_repository_url}/shell-bank-frontend:latest"
    portMappings = [{
      containerPort = 80   # Nginx runs on port 80
      hostPort      = 80
    }]
    # No environment variables needed - API URL is baked into build
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/shell-bank-frontend"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "frontend"
      }
    }
  }])
}

# Frontend ECS Service
resource "aws_ecs_service" "frontend_service" {
  name            = "shell-bank-frontend"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_frontend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
    container_name   = "frontend"
    container_port   = 80
  }

  desired_count = 2
  
  # Ensure proper dependency order for deletion
  depends_on = [aws_lb_listener.alb_listener]
}