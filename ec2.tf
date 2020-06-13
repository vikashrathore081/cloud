provider "aws" {
  region = "ap-south-1"
 profile = "default"
}



resource "aws_security_group" "allow_tls" {
  name        = "sg12345"
  description = "Allow TLS inbound traffic"
  
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
   ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg123"
  }
}


resource "aws_ebs_volume" "ebsTest" {
  availability_zone = aws_instance.myos1.availability_zone
  size              = 1

  tags = {
    Name = "EbsTest"
  }
}

/*variable "insert_key"{
	type=string
}*/

resource "aws_s3_bucket" "bucket1" {
  bucket = "lk1-bucket1234"
  acl    = "public-read"

  tags = {
    Name        = "My bucket1"
  }
}



resource "aws_instance" "myos1" {
  ami = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
   key_name = "mykey1"
   security_groups = ["sg12345"]

  tags = {
    Name = "Linux1OS"
  }
   
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsTest.id
  instance_id = aws_instance.myos1.id
  force_detach = true
  
  connection {
	type="ssh"
	user="ec2-user"
	private_key=file("E:/AWS/key/mykey1.pem")
	host= aws_instance.myos1.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
		
     "sudo yum install httpd php git -y",
		"sudo service httpd start",
		"sudo chkconfig httpd on",
		
    ]
  }
  
  provisioner "remote-exec" {
    inline = [
	 "sudo mkfs.ext4 /dev/xvdh",
	 "sudo mount /dev/xvdh /var/www/html",
	 "sudo rm -rf /var/www/html/*",
	 "sudo git clone https://github.com/vikashrathore081/cloud.git /var/www/html"
    ]
  }
  
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "lk1-bucket1234.s3.amazonaws.com"
    origin_id   = "S3-lk1-bucket1234"

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-lk1-bucket1234"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-lk1-bucket1234"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-lk1-bucket1234"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = [ "CA", "GB"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}