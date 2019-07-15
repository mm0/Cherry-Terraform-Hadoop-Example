#!/usr/bin/env bash

# Disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf
sudo sysctl -p

# Add host keys

sudo apt-get -y install tar unzip

# Install Java
sudo apt install openjdk-11-jdk -y

echo '
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
export PATH=$PATH:/usr/lib/jvm/java-11-openjdk-amd64/bin' | sudo tee --append /etc/profile.d/java_home.sh

# create hadoop data directory
sudo mkdir -p /var/hadoop/data

# create hadoop name directory
sudo mkdir -p /var/hadoop/name

# create hadoop temp directory
sudo mkdir -p /var/hadoop/hdfs/tmp

# create install temp directory
sudo mkdir -p /tmp/temp-install

# create install directory
sudo mkdir -p /opt/hadoop-2.8.2


# download hadoop
cd /opt; sudo wget https://archive.apache.org/dist/hadoop/common/hadoop-2.8.2/hadoop-2.8.2.tar.gz

# unarchive to the install directory
sudo tar zxvf hadoop-2.8.2.tar.gz

sudo chown -R hadoop /var/hadoop/data  /var/hadoop/name /var/hadoop/hdfs/tmp /tmp/temp-install /opt/hadoop-2.8.2


