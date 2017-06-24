!#/bin/bash

sudo apt-get -y install git
sudo apt-get -y install vim
sudo apt-get -y install python2.7

echo '
172.31.32.101 s01
172.31.32.102 s02
172.31.32.103 s03
172.31.32.104 s04
172.31.32.105 s05
172.31.32.106 s06
172.31.32.107 s07
172.31.32.108 s08
172.31.32.109 s09
172.31.32.110 s10
172.31.32.111 s11
172.31.32.112 s12
172.31.32.112 s13
172.31.32.113 s14
172.31.32.114 s15
172.31.32.115 s16
172.31.32.116 s17
172.31.32.117 s18' | sudo tee --append /etc/hosts > /dev/null

sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/id_rsa

cd /opt/
sudo wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz"
sudo tar xzf jdk-8u131-linux-x64.tar.gz

cd /opt/jdk1.8.0_131/
sudo update-alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_131/bin/jar 2
sudo update-alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_131/bin/javac 2
sudo update-alternatives --set jar /opt/jdk1.8.0_131/bin/jar
sudo update-alternatives --set javac /opt/jdk1.8.0_131/bin/javac

echo '
export JAVA_HOME=/opt/jdk1.8.0_131
export JRE_HOME=/opt/jdk1.8.0_131/jre
export PATH=$PATH:/opt/jdk1.8.0_131/bin:/opt/jdk1.8.0_131/jre/bin' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

cd /opt/
sudo wget http://apache.mirrors.tds.net/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz
sudo tar zxvf hadoop-2.7.2.tar.gz

echo '
export HADOOP_HOME=/opt/hadoop-2.7.2
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_CONF_DIR=/opt/hadoop-2.7.2/etc/hadoop' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://s01:9000</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.2/etc/hadoop/core-site.xml > /dev/null

echo '<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>s01</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.2/etc/hadoop/yarn-site.xml > /dev/null

sudo cp /opt/hadoop-2.7.2/etc/hadoop/mapred-site.xml.template /opt/hadoop-2.7.2/etc/hadoop/mapred-site.xml

echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>mapreduce.jobtracker.address</name>
    <value>s01:54311</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.2/etc/hadoop/mapred-site.xml > /dev/null

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///opt/hadoop-2.7.2/hadoop_data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///opt/hadoop-2.7.2/hadoop_data/hdfs/datanode</value>
  </property>
</configuration>' | sudo tee /opt/hadoop-2.7.2/etc/hadoop/hdfs-site.xml > /dev/null

echo '
s01' | sudo tee --append /opt/hadoop-2.7.2/etc/hadoop/masters > /dev/null

echo '
s02
s03' | sudo tee /opt/hadoop-2.7.2/etc/hadoop/slaves > /dev/null

sudo sed -i -e 's/export\ JAVA_HOME=\${JAVA_HOME}/export\ JAVA_HOME=\/opt\/jdk1.8.0_131/g' /opt/hadoop-2.7.2/etc/hadoop/hadoop-env.sh

sudo mkdir -p /opt/hadoop-2.7.2/hadoop_data/hdfs/namenode
sudo mkdir -p /opt/hadoop-2.7.2/hadoop_data/hdfs/datanode

sudo chown -R ubuntu /opt/hadoop-2.7.2

cd /opt/
sudo wget http://apache.mirrors.tds.net/spark/spark-2.1.1/spark-2.1.1-bin-hadoop2.7.tgz
sudo tar -xvzf spark-2.1.1-bin-hadoop2.7.tgz

echo '
export SPARK_HOME=/opt/spark-2.1.1-bin-hadoop2.7
export PATH=$PATH:$SPARK_HOME/bin' | sudo tee --append /home/ubuntu/.bashrc > /dev/null

sudo chown -R ubuntu /opt/spark-2.1.1-bin-hadoop2.7

cd spark-2.1.1-bin-hadoop2.7

cp conf/spark-env.sh.template conf/spark-env.sh  

echo '
export JAVA_HOME=/opt/jdk1.8.0_131
export SPARK_MASTER_HOST=s01
export HADOOP_CONF_DIR=/opt/hadoop-2.7.3/etc/hadoop
export HADOOP_HOME=/opt/hadoop-2.7.3
export SPARK_WORKER_CORES=1 ' | sudo tee --append conf/spark-env.sh > /dev/null

echo '
s02
s03' | sudo tee --append conf/slaves > /dev/null

cp conf/spark-defaults.conf.template conf/spark-defaults.conf
