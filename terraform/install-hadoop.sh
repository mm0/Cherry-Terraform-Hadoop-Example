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
#sudo apt-get -y install vim
#sudo apt-get -y install python2.7

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

# add hadoop profile to startup

#cd /opt/
#sudo wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz"
#sudo tar xzf jdk-8u131-linux-x64.tar.gz

#cd /opt/jdk1.8.0_131/
#sudo update-alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_131/bin/jar 2
#sudo update-alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_131/bin/javac 2
#sudo update-alternatives --set jar /opt/jdk1.8.0_131/bin/jar
#sudo update-alternatives --set javac /opt/jdk1.8.0_131/bin/javac
#
#echo '
#export JAVA_HOME=/opt/jdk1.8.0_131
#export JRE_HOME=/opt/jdk1.8.0_131/jre
#export PATH=$PATH:/opt/jdk1.8.0_131/bin:/opt/jdk1.8.0_131/jre/bin' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

#cd /opt/
#sudo wget http://apache.mirrors.tds.net/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz
#sudo tar zxvf hadoop-2.7.2.tar.gz
#
#echo '
#export HADOOP_HOME=/opt/hadoop-2.7.2
#export PATH=$PATH:$HADOOP_HOME/bin
#export HADOOP_CONF_DIR=/opt/hadoop-2.7.2/etc/hadoop' | sudo tee --append /home/ubuntu/.bashrc > /dev/null


#echo '
#s01' | sudo tee --append /opt/hadoop-2.7.2/etc/hadoop/masters > /dev/null

#sudo sed -i -e 's/export\ JAVA_HOME=\${JAVA_HOME}/export\ JAVA_HOME=\/opt\/jdk1.8.0_131/g' /opt/hadoop-2.7.2/etc/hadoop/hadoop-env.sh


