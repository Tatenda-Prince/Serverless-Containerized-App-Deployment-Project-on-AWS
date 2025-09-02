# =============================================================================
# CLOUDWATCH LOGS - Container Logging
# =============================================================================
# This creates a place to store logs from your containers
# Think of this as a logbook that records everything your app does

# Create CloudWatch Log Groups for ECS containers
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/shell-bank-backend"
  retention_in_days = 7

  tags = {
    Name = "shell-bank-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/shell-bank-frontend"
  retention_in_days = 7

  tags = {
    Name = "shell-bank-frontend-logs"
  }
}