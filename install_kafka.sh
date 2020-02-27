#!/bin/bash
cd /opt
tar -xvf kafka_2.12-2.3.0.tgz
mv kafka_2.12-2.3.0 kafka 
sed -i 's/broker.id=0/broker.id=1/g' /opt/kafka/config/server.properties
read -t 60 -p "请输入kafka的IP：" kafka_IP
echo -e "\n"
echo "kakfa的IP为：$kakfa_IP"
sed -i 's/listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/'$kafka_IP':9092/g' /opt/kafka/config/server.properties
read -t 60 -p "请输入zookeeper的IP：" zookeeper_IP
echo -e "\n"
echo "zookeeper的IP为：$zookeeper_IP"
sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$zookeeper_IP':2181/g' /opt/kafka/config/server.properties
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
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/jdk1.8.0_231/bin"
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
systemctl daemon-reload && systemctl enable kafka && systemctl start kafka && systemctl status kafka && ps -ef|grep kafka
