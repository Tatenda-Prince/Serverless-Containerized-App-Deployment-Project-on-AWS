# =============================================================================
# CONFIGURATION VARIABLES - The Settings Panel
# =============================================================================
# This file contains all the configurable settings for your infrastructure
# Think of this as a control panel where you can adjust settings without
# changing the main code. Like adjusting volume, brightness, etc. on your phone

# AWS Region - Which geographic location to deploy your app
variable "aws_region" {
  default = "us-east-1"  # Virginia, USA - good for US-based users, lowest latency
}

# ECS Cluster Name - The name of your container management system
variable "ecs_cluster_name" {
  default = "my-ecs-cluster"  # You can change this to "shell-bank-cluster" or any name you prefer
}

# Container Name - What to call your banking app container
variable "container_name" {
  default = "banking-app"  # This will show up in AWS console
}

# Application Port - Which port your banking app listens on
variable "app_port" {
  default     = 3000  # Your React frontend runs on port 3000
  description = "Port on which the application runs"
}

# Health Check Path - URL the load balancer uses to check if your app is working
variable "alb_health_check_path" {
  default     = "/"  # Check the homepage to see if app is responding
  description = "Health check endpoint for ALB"
}

# Auto-Scaling Settings - How many containers to run
variable "max_capacity" {
  default = 5  # Maximum 5 containers during high traffic (like Black Friday)
}

variable "min_capacity" {
  default = 2  # Always keep at least 2 containers running (for reliability)
}

# CPU Thresholds - When to add or remove containers automatically
variable "cpu_scale_up_threshold" {
  default = 60  # Add more containers when CPU usage > 60% (app getting busy)
}

variable "cpu_scale_down_threshold" {
  default = 30  # Remove containers when CPU usage < 30% (app not busy, save money)
}