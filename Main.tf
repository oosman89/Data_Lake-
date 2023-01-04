# Created S3 bucket for data ingestion
resource "aws_s3_bucket" "data_logs" {
  bucket = var.bucket_name

}

# Created Ec2 as a data source to extract the logs 
resource "aws_instance" "logs" {
  ami                         = "ami-0742b4e673072066f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pub_1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.data_lake_sgrp.id]
  depends_on                  = [aws_internet_gateway.gw]
  user_data                   = <<-EOF
          #!/bin/bash 
          yum -y update
          yum install -y aws-kinesis-agent
          EOF
}

# IAM role for kenesis firehose
resource "aws_iam_role" "f_role" {
  name = "f_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "kenesis firehose role"
    }
  ]
}
EOF

}

# Attached kenesis firehose policy to the role
resource "aws_iam_role_policy" "f_delivery_policy" {
  role = aws_iam_role.f_role.id

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.data_logs.arn}"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.data_logs.arn}"
    }
  ]

}
EOT
}

# I need to create kenesis firehose

# Created the glue catalage 
resource "aws_glue_catalog_database" "glue_cataloge_db" {
  name = "glue_catalog_db"
}

# Created the glue crawlers to extract data from s3 and place into cataloge
resource "aws_glue_crawler" "glue_crawler" {
  database_name = aws_glue_catalog_database.glue_cataloge_db.name
  name          = "s3_crawler"
  role          = aws_iam_role.crawler_role.arn
  # I need to have a look at the iam role and policy needed for glue crawlers 

  s3_target {
    path = "s3://${aws_s3_bucket.data_logs.bucket}"
  }
}

#Created redshift cluster for Business analytics
resource "aws_redshift_cluster" "data_logs_db" {
  cluster_identifier = "data-logs-cluster"
  database_name      = "data_logs_db"
  master_username    = "admin"
  master_password    = "xxxx!"
  node_type          = "dc1.large"
  cluster_type       = "single-node"
}

# I need to create athena


# I need to create Quicksight

# I need to create cloudwatch

# I need to create Step Function
