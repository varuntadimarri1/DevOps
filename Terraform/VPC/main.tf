# ----------------------------
# CONFIGURE OUR AWS CONNECTION
# ----------------------------

provider "aws" {
  region = "us-east-2"
}

#--------------
# Create a VPC
#--------------

resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "Practice VPC"
  }
}

# --------------------------------------------------------
# GET THE LIST OF AVAILABILITY ZONES IN THE CURRENT REGION
# --------------------------------------------------------

data "aws_availability_zones" "all" {}


#-------------------------------------------------
# Create a Public subnet on the First available AZ
#-------------------------------------------------

resource "aws_subnet" "public_ap_south_1a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet1_cidr
  availability_zone = data.aws_availability_zones.all.names[0]

  tags = {
    Name = "Practice Public Subnet"
  }
}


#-------------------------------
# Create an IGW for your new VPC
#-------------------------------
resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "practice IGW"
  }
}

#----------------------------------
# Create an RouteTable for your VPC
#----------------------------------
resource "aws_route_table" "my_vpc_public" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_vpc_igw.id
    }

    tags = {
        Name = "Practice Public RouteTable"
    }
}

#--------------------------------------------------------------
# Associate the RouteTable to the Subnet created at ap-south-1a
#--------------------------------------------------------------
resource "aws_route_table_association" "my_vpc_ap_south_1a_public" {
    subnet_id = aws_subnet.public_ap_south_1a.id
    route_table_id = aws_route_table.my_vpc_public.id
}

#-----------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO Web Server EC2 
#-----------------------------------------------------------
resource "aws_security_group" "instance" {
  name = "example-instance"
  vpc_id = aws_vpc.my_vpc.id

  # Allow all outbound 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Inbound for Web server
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------------------
# Create EC2 Server
#------------------
resource "aws_instance" "server" {
   ami           = var.amiid
   instance_type = var.type
   key_name      = var.pemfile
   vpc_security_group_ids = [aws_security_group.instance.id]
   subnet_id = aws_subnet.public_ap_south_1a.id
   availability_zone = data.aws_availability_zones.all.names[0]
   
   associate_public_ip_address = true
   
   user_data = <<-EOF
               #!/bin/bash
               echo '<html><body><h1 style="font-size:50px;color:blue;">
               VPC Through terraform <br> <font style="color:red;"> AWS   </h1>
                </body></html>' > index.html
               nohup busybox httpd -f -p 8080 &
              EOF

    tags = {
        Name = "Practice Web Server"
    }
  
}

#---------------------------------------------------
# Create a Private subnet on the Second available AZ
#---------------------------------------------------
resource "aws_subnet" "private_ap_south_1b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet2_cidr
  availability_zone = data.aws_availability_zones.all.names[1]

  tags = {
    Name = "Practice Private Subnet"
  }
}

#---------------------------------
# Create an RouteTable for your DB
#---------------------------------
resource "aws_route_table" "my_vpc_private" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = aws_instance.server.primary_network_interface_id
    }

    tags = {
        Name = "Practice Private RouteTable"
    }
}

#----------------------------------------------------------------
# Associate the DB RouteTable to the Subnet created at ap-south-1b
#----------------------------------------------------------------
resource "aws_route_table_association" "my_vpc_ap_south_1b_private" {
    subnet_id = aws_subnet.private_ap_south_1b.id
    route_table_id = aws_route_table.my_vpc_private.id
}

#----------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO DB Server EC2
#----------------------------------------------------------
resource "aws_security_group" "db" {
  name = "example-db"
  vpc_id = aws_vpc.my_vpc.id

  # Allow all outbound 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound for SSH
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.instance.id]
  }
  
}

#---------------------
# Create EC2 DB Server
#---------------------
resource "aws_instance" "db" {
   ami           = var.amiid
   instance_type = var.type
   key_name      = var.pemfile
   vpc_security_group_ids = [aws_security_group.db.id]
   subnet_id = aws_subnet.private_ap_south_1b.id
   availability_zone = data.aws_availability_zones.all.names[1]
   
   associate_public_ip_address = true

   tags = {
       Name = "Practice DB Server"
   }
  
}
