#!/bin/bash
zookeeper=zookeeper-3.4.14.tar.gz
content=zookeeper-3.4.14
group=zookeeper
user=zookeeper
java=java.env
zoo=zoo.cfg
service=zookeeper.service
path=/opt/zookeeper
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
if [ -f /opt/$zookeeper ]; then
echo "zookeeper压缩包不存在，请解压！"
cd /opt
tar -zxvf $zookeeper
else
echo "zookeeper压缩包已存在"
fi

mv $content zookeeper
if [ ! -G "$group" ]; then
echo "zookeeper用户组不存在需创建"
groupadd $group
cat /etc/group|grep $group
else
echo "zookeeper用户组已创建"
fi

if [ ! -O "$user" ]; then
echo "zookeeper用户不存在需创建"
useradd $user -g $group
id $user
else
echo "zookeeper用户已创建"
fi

if [ -f "/opt/zookeeper/conf/$java" ]; then
echo "$java配置文件已存在"
else
echo "$java配置文件不存在需创建"
cd /opt/zookeeper/conf
touch $java
cat << EOF > $java
export JAVA_HOME=/root/jdk
# heap size MUST be modified according to cluster environment
export JVMFLAGS="-Xms512m -Xmx1024m \$JVMFLAGS"
EOF
fi

#输入要加入的集群IP
read -t 60 -p "请输入要加入zookeeper集群节点1的IP：" cluster_IP1
echo -e "\n"
echo "节点2的IP为：$cluster_IP1"
read -t 60 -p "请输入要加入zookeeper集群节点2的IP：" cluster_IP2
echo -e "\n"
echo "节点3的IP为：$cluster_IP2"
if [ -f "/opt/zookeeper/conf/$zoo" ]; then
echo "$zoo配置文件已存在"
else
echo "$zoo配置文件不存在需创建"
cd /opt/zookeeper/conf
touch $zoo
cat << EOF > $zoo
tickTime=2000
dataDir=/opt/zookeeper/data
clientPort=1888
initLimit=5
syncLimit=2
server.1=$cluster_IP1:2888:3888
server.2=$cluster_IP2:2888:3888
server.3=$ip:2888:3888
dataLogDir=/opt/zookeeper/logs
EOF
fi

if [ -d "/opt/zookeeper/data" ]; then
echo "data文件夹已存在"
elif [ -f "/opt/zookeeper/data/myid" ]; then
echo "myid文件已存在"
else
echo "data文件夹不存在需创建"
mkdir /opt/zookeeper/data
echo "myid文件不存在需创建"
cd /opt/zookeeper/data
echo "3" > myid
fi

if [ -d "/opt/zookeeper/logs" ]; then
echo "logs文件夹已存在"
else
echo "logs文件夹不存在需创建"
cd /opt/zookeeper
mkdir logs
fi

if [ -f "/usr/lib/systemd/system/$service" ]; then
echo "zookeeper服务已存在"
else
echo "zookeeper服务不存在需创建"
cd /usr/lib/systemd/system
touch $service
cat << EOF > $service
[Unit]
Description=zookeeper
After=syslog.target network.target

[Service]
Type=forking
Environment=ZOO_LOG_DIR=/opt/zookeeper/bin
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
Restart=always
User=zookeeper
Group=zookeeper

[Install]
WantedBy=multi-user.target
EOF
fi

q=$(ls -l ${path}|sed -n '2p' |awk -F " " '{print $3}')
if [ "$q" = "zookeeper" ]; then
    echo 'ok'
else
    chown zookeeper:zookeeper ${path} -R
    echo 'zookeeper所属用户组更改完成'
    ls -l --color=auto -d $path
fi

systemctl daemon-reload && systemctl enable zookeeper && systemctl start zookeeper && systemctl status zookeeper && ps -ef|grep zookeeper

