#!/bin/bash
cd /opt
tar -xvf kafka_2.12-2.3.0.tgz
mv kafka_2.12-2.3.0 kafka 
sed -i 's/broker.id=0/broker.id=1/g' /opt/kafka/config/server.properties
read -t 60 -p "请输入kafka集群节点1的IP：" IP
echo -e "\n"
echo "kafka集群节点1的IP为：$IP"
sed -i "31a listeners=PLAINTEXT://$IP:9092\n" /opt/kafka/config/server.properties
#输入zookeeper的集群IP
read -t 60 -p "请输入zookeeper集群节点1的IP：" cluster_IP1
echo -e "\n"
echo "zookeeper节点1的IP为：$cluster_IP1"
read -t 60 -p "请输入zookeeper集群节点2的IP：" cluster_IP2
echo -e "\n"
echo "zookeeper节点2的IP为：$cluster_IP2"
read -t 60 -p "请输入zookeeper集群节点3的IP：" cluster_IP3
echo -e "\n"
echo "zookeeper节点3的IP为：$cluster_IP3"
sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$cluster_IP1:2181','$cluster_IP2:2181','$cluster_IP3:2181/g'' /opt/kafka/config/server.properties
sed -i 's|log.dirs=/tmp/kafka-logs|log.dirs=/opt/kafka/logs/kafka-logs|' /opt/kafka/config/server.properties
if [ -d "/opt/kafka/logs" ]; then
echo "logs文件夹不存在需创建"
cd /opt/kafka
mkdir logs
else
echo "logs文件夹存在"
fi

if [ ! -f "/usr/lib/systemd/system/kafka.service" ]; then
echo "kafka服务不存在需创建"
cd /usr/lib/systemd/system
touch kafka.service
cat << EOF > kafka.service
[Unit]
Description=Apache Kafka server (broker)
After=network.target zookeeper.service

[Service]
Type=simple
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/jdk1.8.0_221/bin"
User=root
Group=root
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
else
echo "kafka服务已存在"
fi

#启动服务
systemctl daemon-reload && systemctl enable kafka && systemctl start kafka && systemctl status kafka && ps -ef|grep kakfa

