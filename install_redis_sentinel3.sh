#!/bin/bash
service=redis-sentinel.service
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
cp /opt/redis-4.0.14/sentinel.conf /opt/redis/sentinel.conf
sed -i 's/# protected-mode no/protected-mode no/g' /opt/redis/sentinel.conf
sed -i 's/sentinel monitor mymaster 127.0.0.1 6379 2/sentinel monitor mymaster '$ip' 6379 2/g' /opt/redis/sentinel.conf
sed -i 's/dir \/tmp/dir \/opt\/redis\/data/g' /opt/redis/sentinel.conf
echo "sentinel config-epoch mymaster 1" >> /opt/redis/sentinel.conf
echo "sentinel leader-epoch mymaster 1" >> /opt/redis/sentinel.conf
#输入redis从节点的IP
read -t 60 -p "请输入redis从节点1的IP：" slave_IP1
echo -e "\n"
echo "redis主节点的IP为：$slave_IP1"
read -t 60 -p "请输入redis从节点2的IP：" slave_IP2
echo -e "\n"
echo "redis主节点的IP为：$slave_IP2"
echo "sentinel known-slave mymaster $slave_IP1 6379" >> /opt/redis/sentinel.conf
echo "sentinel known-slave mymaster $slave_IP2 6379" >> /opt/redis/sentinel.conf
#输入redis主节点的IP
read -t 60 -p "请输入redis主节点的IP：" master_IP
echo -e "\n"
echo "redis主节点的IP为：$master_IP"
sentinel announce-ip "$master_IP"
chown -R redis:redis /opt/redis

if [ ! -f "/usr/lib/systemd/system/$service" ]; then
echo "redis服务不存在需创建"
cd /usr/lib/systemd/system
touch $service
cat << EOF > $service
[Unit]
Description=Redis Server Manager
After=syslog.target
After=network.target
 
[Service]
Type=simple
User=redis
Group=redis
ExecStart=/opt/redis/bin/redis-sentinel /opt/redis/sentinel.conf --daemonize no
ExecStop=/opt/redis/bin/redis-cli -p 26379 shutdown
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
else
echo "redis服务已存在"
fi



systemctl daemon-reload && systemctl enable redis-sentinel && systemctl start redis-sentinel && systemctl status redis-sentinel && ps -ef|grep redis-sentinel
