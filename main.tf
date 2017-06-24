provider "aws" {
    region = "eu-west-1"
}

resource "aws_security_group" "Hadoop_cluster_sc" {
    name = "Hadoop_cluster_sc"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 9000
        to_port     = 9000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 50070
        to_port     = 50070
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "Namenode" {
    count = 1
    ami = "ami-a8d2d7ce"
    instance_type = "t2.micro"
    key_name = "ssh-key"
    tags {
        Name = "s01"
    }
    private_ip = "172.31.32.101"
    vpc_security_group_ids = ["${aws_security_group.Hadoop_cluster_sc.id}"]

    provisioner "file" {
        source      = "install-hadoop.sh"
        destination = "/tmp/install-hadoop.sh"

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file("~/.aws/ssh-key.pem")}"
        }
    }

    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/authorized_keys'"
    }
    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa.pub'"
    }
    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa'"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/install-hadoop.sh",
            "/tmp/install-hadoop.sh",
            "/opt/hadoop-2.7.2/bin/hadoop namenode -format"
        ]
        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file("~/.aws/ssh-key.pem")}"
        }

    }

}

resource "aws_instance" "Datanode" {
    count = 2
    ami = "ami-a8d2d7ce"
    instance_type = "t2.micro"
    key_name = "ssh-key"
    tags {
        Name = "${lookup(var.hostnames,count.index)}"
    }
    private_ip = "${lookup(var.ips,count.index)}"
    vpc_security_group_ids = ["${aws_security_group.Hadoop_cluster_sc.id}"]

    provisioner "file" {
        source      = "install-hadoop.sh"
        destination = "/tmp/install-hadoop.sh"

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file("~/.aws/ssh-key.pem")}"
        }
    }

    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/authorized_keys'"
    }
    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa.pub'"
    }
    provisioner "local-exec" {
        command = "cat ~/.ssh/id_rsa | ssh -o StrictHostKeyChecking=no -i ~/.aws/ssh-key.pem  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa'"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/install-hadoop.sh",
            "/tmp/install-hadoop.sh",
        ]
        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file("~/.aws/ssh-key.pem")}"
        }

    }

}