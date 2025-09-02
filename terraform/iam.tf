# =============================================================================
# IAM ROLES - Permissions for Your Containers
# =============================================================================
# This creates the necessary permissions for ECS to run your containers
# Think of this as giving your containers an "ID card" with specific permissions

# ECS Task Execution Role - Allows ECS to pull Docker images and write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  # Trust policy - who can use this role (ECS service)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}