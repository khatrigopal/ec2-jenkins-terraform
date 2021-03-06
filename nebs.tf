provider "aws" {
  region = "ap-south-1"
  profile = "khatrig"
}


resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "testkp"
  security_groups = [ "default" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("/code/webserver/testkp.pem")}"
    host     = "${aws_instance.web.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "FirstOS"
  }
}

resource "aws_ebs_volume" "esb1" {
  availability_zone = "${aws_instance.web.availability_zone}"
  size              = 1
  tags = {
    Name = "khatrigebs"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.esb1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}



output "myos_dns" {
  value = "${aws_instance.web.public_dns}"
}

resource "null_resource" "nulllocal1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web.public_ip} > publicip.txt"
  	}
}

resource "null_resource" "nullremote3"  {

depends_on = [
    "aws_volume_attachment.ebs_att",
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("/code/webserver/testkp.pem")}"
    host     = "${aws_instance.web.public_ip}"
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/khatrigopal/webpage.git /var/www/html"
    ]
  }
}	

