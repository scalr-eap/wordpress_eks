# Create and RDS Instance for MySQL

data "aws_eks_cluster" "this_cluster" {
  name = var.cluster_name
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = "${data.aws_eks_cluster.this_cluster.vpc_config.0.subnet_ids}"

  tags = {
    Name = "Group1"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = var.mysql_password
  db_subnet_group_name = aws_db_subnet_group.default.name
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}
