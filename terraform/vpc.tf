# =============================================================================
# VPC (Virtual Private Cloud) - Your Private Network in AWS
# =============================================================================
# Think of this as building your own private neighborhood in the cloud:
# - Public areas (where visitors can come) = Public Subnets
# - Private areas (where your app lives safely) = Private Subnets  
# - Security gates and rules = Security Groups
# - Internet connection = Internet Gateway
# - Private internet access = NAT Gateway

# =============================================================================
# MAIN NETWORK SETUP
# =============================================================================

# Create the main VPC - Your private cloud network
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"    # IP address range for your network (65,536 possible addresses)
  enable_dns_support   = true             # Allow DNS resolution (so containers can find each other by name)
  enable_dns_hostnames = true             # Allow DNS hostnames (friendly names instead of IP addresses)

  tags = {
    Name = "ecs-vpc"  # Name tag for easy identification in AWS console
  }
}

# =============================================================================
# PUBLIC SUBNETS - Where Load Balancer Lives (Internet Accessible)
# =============================================================================

# Public Subnet 1 - In Availability Zone A (like a different building in your neighborhood)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id    # Which VPC this subnet belongs to
  cidr_block              = "10.0.1.0/24"        # IP range for this subnet (256 addresses)
  availability_zone       = "us-east-1a"         # Physical location (data center A)
  map_public_ip_on_launch = true                 # Automatically assign public IPs to resources here

  tags = {
    Name = "public-subnet-1"
  }
}

# Public Subnet 2 - In Availability Zone B (backup location for high availability)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id    # Which VPC this subnet belongs to
  cidr_block              = "10.0.2.0/24"        # Different IP range for this subnet
  availability_zone       = "us-east-1b"         # Physical location (data center B)
  map_public_ip_on_launch = true                 # Automatically assign public IPs

  tags = {
    Name = "public-subnet-2"
  }
}

# =============================================================================
# PRIVATE SUBNETS - Where Your Banking App Containers Live (Secure)
# =============================================================================

# Private Subnet 1 - Secure area for your app containers
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id    # Which VPC this subnet belongs to
  cidr_block        = "10.0.3.0/24"        # IP range for this subnet
  availability_zone = "us-east-1a"         # Same AZ as public subnet 1 (for pairing)

  tags = {
    Name = "private-subnet-1"
  }
}

# Private Subnet 2 - Backup secure area (high availability)
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id    # Which VPC this subnet belongs to
  cidr_block        = "10.0.4.0/24"        # Different IP range
  availability_zone = "us-east-1b"         # Same AZ as public subnet 2

  tags = {
    Name = "private-subnet-2"
  }
}

# =============================================================================
# INTERNET CONNECTIVITY
# =============================================================================

# Internet Gateway - The main door to the internet for public subnets
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id    # Attach to our VPC

  tags = {
    Name = "ecs-internet-gateway"
  }
}

# Elastic IP - A permanent public IP address for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"    # This IP belongs to our VPC
}

# NAT Gateway - Allows private subnets to access internet securely
# Think of this as a secure proxy that lets your app download updates
# but prevents direct internet access to your containers
resource "aws_nat_gateway" "ecs_nat" {
  allocation_id = aws_eip.nat_eip.id           # Use the Elastic IP we created
  subnet_id     = aws_subnet.public_subnet_1.id    # Place in public subnet (needs internet access)

  tags = {
    Name = "ecs-nat-gateway"
  }
}

# =============================================================================
# ROUTING TABLES - Traffic Direction Rules
# =============================================================================

# Public Route Table - Rules for public subnet traffic
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "public-route-table"
  }
}

# Connect public subnets to the public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id    # Public subnet 1
  route_table_id = aws_route_table.public_rt.id     # Use public routing rules
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id    # Public subnet 2  
  route_table_id = aws_route_table.public_rt.id     # Use public routing rules
}

# Route all internet traffic from public subnets to Internet Gateway
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id    # Which route table
  destination_cidr_block = "0.0.0.0/0"                    # All internet traffic (0.0.0.0/0 = everywhere)
  gateway_id             = aws_internet_gateway.ecs_igw.id  # Send to Internet Gateway
}

# Private Route Table - Rules for private subnet traffic
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "private-route-table"
  }
}

# Connect private subnets to the private route table
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id    # Private subnet 1
  route_table_id = aws_route_table.private_rt.id     # Use private routing rules
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id    # Private subnet 2
  route_table_id = aws_route_table.private_rt.id     # Use private routing rules
}

# Route internet traffic from private subnets through NAT Gateway (secure)
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id    # Which route table
  destination_cidr_block = "0.0.0.0/0"                     # All internet traffic
  nat_gateway_id         = aws_nat_gateway.ecs_nat.id      # Send through NAT Gateway (secure proxy)
}

# =============================================================================
# SECURITY GROUPS - Firewall Rules
# =============================================================================

# Security Group for Load Balancer - Controls who can access your app
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  # Allow incoming HTTP traffic (port 80) from anywhere on the internet
  ingress {
    from_port   = 80                # Port 80 (standard web traffic)
    to_port     = 80
    protocol    = "tcp"             # TCP protocol
    cidr_blocks = ["0.0.0.0/0"]    # From anywhere on the internet
  }

  # Allow incoming HTTPS traffic (port 443) from anywhere on the internet
  ingress {
    from_port   = 443               # Port 443 (secure web traffic)
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # From anywhere on the internet
  }

  # Allow all outgoing traffic (load balancer needs to talk to containers)
  egress {
    from_port   = 0                 # All ports
    to_port     = 0
    protocol    = "-1"              # All protocols
    cidr_blocks = ["0.0.0.0/0"]    # To anywhere
  }

  tags = {
    Name = "alb-security-group"
  }
}

# Security Group for Backend Containers - Controls access to Flask API
resource "aws_security_group" "ecs_backend_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  # Allow incoming traffic on port 5000 ONLY from the load balancer
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-security-group"
  }
}

# Security Group for Frontend Containers - Controls access to React app
resource "aws_security_group" "ecs_frontend_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  # Allow incoming traffic on port 80 ONLY from the load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend-security-group"
  }
}