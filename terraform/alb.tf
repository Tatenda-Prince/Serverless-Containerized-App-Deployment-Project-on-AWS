# =============================================================================
# APPLICATION LOAD BALANCER (ALB) - The Traffic Director
# =============================================================================
# Think of this as a smart traffic cop that:
# - Receives all internet traffic coming to your banking app
# - Distributes traffic evenly across multiple app containers
# - Checks if containers are healthy before sending traffic
# - Provides a single public URL for users to access your app

# Create the main load balancer
resource "aws_lb" "alb" {
  name               = "ecs-alb"                    # Name of the load balancer
  internal           = false                        # false = accessible from internet, true = internal only
  load_balancer_type = "application"               # Application Load Balancer (handles HTTP/HTTPS traffic)
  security_groups    = [aws_security_group.alb_sg.id]  # Security rules (firewall) for the load balancer
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]  # Deploy across 2 public subnets for high availability
}

# =============================================================================
# TARGET GROUPS - Define which containers receive traffic
# =============================================================================

# Backend Target Group - Routes API calls to backend containers
resource "aws_lb_target_group" "backend_target_group" {
  name        = "backend-target-group"
  port        = 5000                               # Backend port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"                       # Backend health check endpoint
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Frontend Target Group - Routes web traffic to frontend containers
resource "aws_lb_target_group" "frontend_target_group" {
  name        = "frontend-target-group"
  port        = 80                                # Nginx port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"                       # Frontend health check endpoint
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# =============================================================================
# LOAD BALANCER LISTENER - Traffic Routing Rules
# =============================================================================

# Create a listener with path-based routing
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # Default action - send to frontend (main website)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}

# Listener rule - Route API calls to backend
resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]  # Route all /api/* requests to backend
    }
  }
}