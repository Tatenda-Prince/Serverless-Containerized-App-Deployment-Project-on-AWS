# =============================================================================
# AUTO SCALING - Automatically adjust container count based on demand
# =============================================================================
# This monitors CPU usage and adds/removes containers automatically
# Think of this as a smart manager that hires/fires workers based on workload

# Backend Auto Scaling Target
resource "aws_appautoscaling_target" "backend_target" {
  max_capacity       = var.max_capacity                                                           # Maximum containers (5)
  min_capacity       = var.min_capacity                                                           # Minimum containers (2)
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.backend_service.name}"  # Backend service
  scalable_dimension = "ecs:service:DesiredCount"                                                 # Scale container count
  service_namespace  = "ecs"                                                                      # ECS namespace
}

# Backend Auto Scaling Policy
resource "aws_appautoscaling_policy" "backend_scaling_policy" {
  name               = "backend-scaling-policy"
  policy_type        = "TargetTrackingScaling"                                                   # Track CPU and scale accordingly
  resource_id        = aws_appautoscaling_target.backend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"                                 # Monitor CPU usage
    }
    target_value       = 60                                                                      # Target 60% CPU (from variables)
    scale_in_cooldown  = 120                                                                     # Wait 2 minutes before scaling down
    scale_out_cooldown = 120                                                                     # Wait 2 minutes before scaling up
  }
}

# Frontend Auto Scaling Target
resource "aws_appautoscaling_target" "frontend_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.frontend_service.name}"  # Frontend service
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Frontend Auto Scaling Policy
resource "aws_appautoscaling_policy" "frontend_scaling_policy" {
  name               = "frontend-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60                                                                      # Target 60% CPU
    scale_in_cooldown  = 120                                                                     # Wait 2 minutes before scaling down
    scale_out_cooldown = 120                                                                     # Wait 2 minutes before scaling up
  }
}
