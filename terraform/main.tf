resource "cherryservers_project" "myproject" {
  team_id = "${var.team_id}"
  name = "Terraform Hadoop Project"
}
resource "cherryservers_ssh" "mykey" {
  name = "terraformkey"
  public_key = "${file("~/.ssh/cherry.pub")}"
}
resource "cherryservers_ip" "floating-ip-master" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
}
resource "cherryservers_ip" "floating-ip-node-1" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
}
resource "cherryservers_ip" "floating-ip-node-2" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
}

data "template_file" "coresite" {
  template = "${file("./templates/core-site.xml.tmpl")}"
  vars = {
    hadoop_temp_dir = "/tmp/hadoop/hdfs/tmp"
    hadoop_master_ip = "${cherryservers_ip.floating-ip-master.address}"
  }
}
data "template_file" "hdfssite" {
  template = "${file("./templates/hdfs-site.xml.tmpl")}"
  vars = {
    hdfs_replication_factor = "3"
    hadoop_data_dir = "/var/hadoop/data"
    hadoop_name_dir = "/var/hadoop/name"
  }
}
data "template_file" "hadoopenv" {
  template = "${file("./templates/hadoop-env.sh.tmpl")}"
  vars = {
    java_home = "/usr/lib/jvm/java-11-openjdk-amd64/"
  }
}
data "template_file" "sparkenv" {
  template = "${file("./templates/spark-env.sh.tmpl")}"
  vars = {
    java_home = "/usr/lib/jvm/java-11-openjdk-amd64/"
    spark_master_ip = "${cherryservers_ip.floating-ip-master.address}"
    spark_master_port = 7077
    spark_worker_work_port = 65000
    spark_worker_ui_port = 8080
  }
}
data "template_file" "sparkprofile" {
  template = "${file("./templates/spark-profile.sh.tmpl")}"
  vars = {
    spark_installation_dir = "/opt/spark-2.4.0-bin-without-hadoop"
  }
}
data "template_file" "slaves" {
  template = "${file("./templates/slaves.tmpl")}"
  vars = {
    hosts = "${cherryservers_ip.floating-ip-node-1.address}\n${cherryservers_ip.floating-ip-node-2.address}"
  }
}

# Create a Master server
resource "cherryservers_server" "my-master-server" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
  hostname = "${cherryservers_ip.floating-ip-master.address}"
  image = "${var.image}"
  plan_id = "${var.plan_id}"
  ssh_keys_ids = [
    "${cherryservers_ssh.mykey.id}"]
  ip_addresses_ids = [
    "${cherryservers_ip.floating-ip-master.id}"]

  provisioner "file" {
    source = "install-hadoop.sh"
    destination = "/tmp/install-hadoop.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-master.address}"
      private_key = "${file(var.private_key)}"
      agent = false
    }
  }

  provisioner "file" {
    source = "install-spark.sh"
    destination = "/tmp/install-spark.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-master.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -r hadoop",
      "sudo useradd -m -r spark",
      "sudo mkdir -p /home/spark/.ssh /home/hadoop/.ssh"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-master.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "local-exec" {
    command = <<EOT
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa';
EOT
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 700 /home/spark/.ssh ; sudo chmod 0600 /home/spark/.ssh/id_rsa ",
      "sudo chmod 700 /home/hadoop/.ssh ; sudo chmod 0600 /home/hadoop/.ssh/id_rsa",
      "chmod +x /tmp/install-hadoop.sh",
      "/tmp/install-hadoop.sh",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/core-site.xml <<EOL",
      "${data.template_file.coresite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hdfs-site.xml <<EOL",
      "${data.template_file.hdfssite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hadoop-env.sh <<EOL",
      "${data.template_file.hadoopenv.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/slaves <<EOL",
      "${data.template_file.slaves.rendered}",
      "EOL",
      "chmod +x /tmp/install-spark.sh",
      "/tmp/install-spark.sh",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/slaves <<EOL",
      "${data.template_file.slaves.rendered}",
      "EOL",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/hadoop-env.sh <<EOL",
      "${data.template_file.sparkenv.rendered}",
      "EOL",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/spark-profile.sh <<EOL",
      "${data.template_file.sparkprofile.rendered}",
      "EOL",
      "sudo chown -R spark /opt/spark-2.4.0-bin-without-hadoop",
      "sudo chown -R hadoop /opt/hadoop-2.8.2",
      "sudo su - hadoop -c '/opt/hadoop-2.8.2/bin/hadoop namenode -format'"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-master.address}"
      private_key = "${file(var.private_key)}"
    }
  }
}
output "master_ip" {
  value = "${cherryservers_ip.floating-ip-master.address}"
}

# Create a node server
resource "cherryservers_server" "my-node-1-server" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
  hostname = "${cherryservers_ip.floating-ip-node-1.address}"
  image = "${var.image}"
  plan_id = "${var.plan_id}"
  ssh_keys_ids = [
    "${cherryservers_ssh.mykey.id}"]
  ip_addresses_ids = [
    "${cherryservers_ip.floating-ip-node-1.id}"]


  provisioner "file" {
    source = "install-hadoop.sh"
    destination = "/tmp/install-hadoop.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-1.address}"
      private_key = "${file(var.private_key)}"
      agent = false
    }
  }

  provisioner "file" {
    source = "install-spark.sh"
    destination = "/tmp/install-spark.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-1.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -r hadoop",
      "sudo useradd -m -r spark",
      "sudo mkdir -p /home/spark/.ssh /home/hadoop/.ssh"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-1.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "local-exec" {
    command = <<EOT
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa';
EOT
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 700 /home/spark/.ssh ; sudo chmod 0600 /home/spark/.ssh/id_rsa ",
      "sudo chmod 700 /home/hadoop/.ssh ; sudo chmod 0600 /home/hadoop/.ssh/id_rsa",
      "chmod +x /tmp/install-hadoop.sh",
      "/tmp/install-hadoop.sh",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/core-site.xml <<EOL",
      "${data.template_file.coresite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hdfs-site.xml <<EOL",
      "${data.template_file.hdfssite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hadoop-env.sh <<EOL",
      "${data.template_file.hadoopenv.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/slaves <<EOL",
      "${data.template_file.slaves.rendered}",
      "EOL",
      "chmod +x /tmp/install-spark.sh",
      "/tmp/install-spark.sh",
      "echo ${cherryservers_ip.floating-ip-master.address} > /opt/spark-2.4.0-bin-without-hadoop/conf/master",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/hadoop-env.sh <<EOL",
      "${data.template_file.sparkenv.rendered}",
      "EOL",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/spark-profile.sh <<EOL",
      "${data.template_file.sparkprofile.rendered}",
      "EOL",
      "sudo chown -R spark /opt/spark-2.4.0-bin-without-hadoop",
      "sudo chown -R hadoop /opt/hadoop-2.8.2",
      "sudo su - hadoop -c '/opt/hadoop-2.8.2/bin/hadoop datanode -format'"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-1.address}"
      private_key = "${file(var.private_key)}"
    }

  }
}
resource "cherryservers_server" "my-node-2-server" {
  project_id = "${cherryservers_project.myproject.id}"
  region = "${var.region}"
  hostname = "${cherryservers_ip.floating-ip-node-2.address}"
  image = "${var.image}"
  plan_id = "${var.plan_id}"
  ssh_keys_ids = [
    "${cherryservers_ssh.mykey.id}"]
  ip_addresses_ids = [
    "${cherryservers_ip.floating-ip-node-2.id}"]


  provisioner "file" {
    source = "install-hadoop.sh"
    destination = "/tmp/install-hadoop.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-2.address}"
      private_key = "${file(var.private_key)}"
      agent = false
    }
  }

  provisioner "file" {
    source = "install-spark.sh"
    destination = "/tmp/install-spark.sh"

    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-2.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -r hadoop",
      "sudo useradd -m -r spark",
      "sudo mkdir -p /home/spark/.ssh /home/hadoop/.ssh"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-2.address}"
      private_key = "${file(var.private_key)}"
    }
  }
  provisioner "local-exec" {
    command = <<EOT
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/hadoop/.ssh/id_rsa';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/authorized_keys';
        cat ${var.hadoop_private_key}.pub | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa.pub';
        cat ${var.hadoop_private_key} | ssh -o StrictHostKeyChecking=no -i ${var.private_key}  root@${self.primary_ip} 'cat >> /home/spark/.ssh/id_rsa';
EOT
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 700 /home/spark/.ssh ; sudo chmod 0600 /home/spark/.ssh/id_rsa ",
      "sudo chmod 700 /home/hadoop/.ssh ; sudo chmod 0600 /home/hadoop/.ssh/id_rsa",
      "chmod +x /tmp/install-hadoop.sh",
      "/tmp/install-hadoop.sh",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/core-site.xml <<EOL",
      "${data.template_file.coresite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hdfs-site.xml <<EOL",
      "${data.template_file.hdfssite.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/hadoop-env.sh <<EOL",
      "${data.template_file.hadoopenv.rendered}",
      "EOL",
      "cat > /opt/hadoop-2.8.2/etc/hadoop/slaves <<EOL",
      "${data.template_file.slaves.rendered}",
      "EOL",
      "chmod +x /tmp/install-spark.sh",
      "/tmp/install-spark.sh",
      "echo ${cherryservers_ip.floating-ip-master.address} > /opt/spark-2.4.0-bin-without-hadoop/conf/master",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/hadoop-env.sh <<EOL",
      "${data.template_file.sparkenv.rendered}",
      "EOL",
      "cat > /opt/spark-2.4.0-bin-without-hadoop/conf/spark-profile.sh <<EOL",
      "${data.template_file.sparkprofile.rendered}",
      "EOL",
      "sudo chown -R spark /opt/spark-2.4.0-bin-without-hadoop",
      "sudo chown -R hadoop /opt/hadoop-2.8.2",
      "sudo su - hadoop -c '/opt/hadoop-2.8.2/bin/hadoop datanode -format'"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = "${cherryservers_ip.floating-ip-node-2.address}"
      private_key = "${file(var.private_key)}"
    }
  }
}
