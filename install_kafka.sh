#!/bin/bash
cd /opt
tar -xvf kafka_2.12-2.7.0.tgz
mv kafka_2.12-2.7.0 kafka 
sed -i 's/broker.id=0/broker.id=1/g' /opt/kafka/config/server.properties
read -t 60 -p "请输入kafka的IP：" kafka_IP
echo -e "\n"
echo "kakfa的IP为：$kakfa_IP"
sed -i 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/'$kafka_IP':9092/g' /opt/kafka/config/server.properties
read -t 60 -p "请输入zookeeper的IP：" zookeeper_IP
echo -e "\n"
echo "zookeeper的IP为：$zookeeper_IP"
sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$zookeeper_IP':2181/g' /opt/kafka/config/server.properties
sed -i 's/log.dirs=\/tmp\/kafka-logs/log.dirs=\/opt\/kafka\/logs\/kafka-logs/g' /opt/kafka/config/server.properties
sed -i 's/#log.retention.bytes=1073741824/log.retention.bytes=-1/g' /opt/kafka/config/server.properties
echo "message.max.bytes=6525000" >> /opt/kafka/config/server.properties
echo "background.threads=4" >> /opt/kafka/config/server.properties
echo "queued.max.requests=500" >> /opt/kafka/config/server.properties
echo "log.roll.hours =168" >> /opt/kafka/config/server.properties
echo "log.cleanup.policy = delete" >> /opt/kafka/config/server.properties
echo "log.retention.minutes=4320" >> /opt/kafka/config/server.properties
echo "log.cleaner.enable=false" >> /opt/kafka/config/server.properties
echo "log.cleaner.threads=2" >> /opt/kafka/config/server.properties
echo "log.cleaner.io.buffer.size=524288" >> /opt/kafka/config/server.properties
echo "log.cleaner.io.buffer.load.factor=0.9" >> /opt/kafka/config/server.properties
echo "log.cleaner.backoff.ms=15000" >> /opt/kafka/config/server.properties
echo "log.cleaner.min.cleanable.ratio=0.5" >> /opt/kafka/config/server.properties
echo "log.cleaner.delete.retention.ms =86400000" >> /opt/kafka/config/server.properties
echo "log.index.size.max.bytes =10485760" >> /opt/kafka/config/server.properties
echo "log.index.interval.bytes =4096" >> /opt/kafka/config/server.properties
echo "log.flush.scheduler.interval.ms =3000" >> /opt/kafka/config/server.properties
echo "log.delete.delay.ms =60000" >> /opt/kafka/config/server.properties
echo "log.flush.offset.checkpoint.interval.ms =60000" >> /opt/kafka/config/server.properties
echo "auto.create.topics.enable =true" >> /opt/kafka/config/server.properties
echo "default.replication.factor =1" >> /opt/kafka/config/server.properties
echo "controller.socket.timeout.ms =30000" >> /opt/kafka/config/server.properties
echo "controller.message.queue.size=10" >> /opt/kafka/config/server.properties
echo "replica.lag.time.max.ms =10000" >> /opt/kafka/config/server.properties
echo "replica.lag.max.messages =4000" >> /opt/kafka/config/server.properties
echo "replica.socket.timeout.ms=30000" >> /opt/kafka/config/server.properties
echo "replica.socket.receive.buffer.bytes=65536" >> /opt/kafka/config/server.properties
echo "replica.fetch.max.bytes =1048576" >> /opt/kafka/config/server.properties
echo "replica.fetch.wait.max.ms =500" >> /opt/kafka/config/server.properties
echo "replica.fetch.min.bytes =1" >> /opt/kafka/config/server.properties
echo "num.replica.fetchers=1" >> /opt/kafka/config/server.properties
echo "replica.high.watermark.checkpoint.interval.ms =5000" >> /opt/kafka/config/server.properties
echo "controlled.shutdown.enable=false" >> /opt/kafka/config/server.properties
echo "controlled.shutdown.max.retries=3" >> /opt/kafka/config/server.properties
echo "controlled.shutdown.retry.backoff.ms=5000" >> /opt/kafka/config/server.properties
echo "leader.imbalance.per.broker.percentage=10" >> /opt/kafka/config/server.properties
echo "leader.imbalance.check.interval.seconds=300" >> /opt/kafka/config/server.properties
echo "zookeeper.connect = 192.168.1.2:2181?backup=192.168.1.4:2182,192.168.1.6:2183" >> /opt/kafka/config/server.properties
echo "zookeeper.session.timeout.ms=6000" >> /opt/kafka/config/server.properties
echo "zookeeper.sync.time.ms=2000" >> /opt/kafka/config/server.properties

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
