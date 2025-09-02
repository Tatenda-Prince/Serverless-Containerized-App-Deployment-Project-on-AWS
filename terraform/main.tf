# =============================================================================
# MAIN CONFIGURATION - Where Everything Starts
# =============================================================================
# This file tells Terraform which cloud provider to use and basic settings
# Think of this as the "headquarters" that coordinates everything else

# Configure AWS as our cloud provider
provider "aws" {
  region = var.aws_region  # Deploy everything in this AWS region (us-east-1 = Virginia)
}
