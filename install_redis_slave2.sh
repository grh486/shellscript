#!/bin/bash
group=redis
user=redis
conf=redis
#ip="ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:""
service=redis.service

if [ -f /opt/redis-4.0.14.tar.gz ]; then
echo "redis压缩包不存在，请解压！"
cd /opt
tar -zxvf redis-4.0.14.tar.gz
#mv redis-4.0.14 redis
else
echo "redis压缩包已存在"
fi

if [  -G "$group" ]; then
echo "redis用户组已创建"
else
echo "redis用户组不存在需创建"
groupadd $group
cat /etc/group|grep $group
fi

if [  -O "$user" ]; then
echo "redis用户已创建"
else
echo "redis用户不存在需创建"
useradd $user -g $group -s /sbin/nologin
id $user
fi

echo "解决redis依赖"
yum install -y gcc

echo "准备编译安装"
#cd /opt/redis
cd /opt/redis-4.0.14
make MALLOC=libc;make test;make PREFIX=/opt/redis install
#make MALLOC=libc;make install

if [ ! -d "/opt/redis/logs" ]; then
echo "日志文件夹不存在需创建"
cd /opt/redis
mkdir logs
else
echo "日志文件夹已创建"
fi

if [ ! -d "/opt/redis/data" ]; then
echo "数据文件夹不存在需创建"
cd /opt/redis
mkdir data
else
echo "数据文件夹已创建"
fi

cp /opt/redis-4.0.14/redis.conf /opt/redis/redis.conf
#输入redis主节点的IP
read -t 60 -p "请输入redis主节点的IP：" master_IP
echo -e "\n"
echo "redis主节点的IP为：$master_IP"
#修改redis配置文件
#sed -i 's/bind 127.0.0.1/bind $ip 127.0.0.1/g' /opt/redis/redis.conf
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /opt/redis/redis.conf
sed -i 's/daemonize no/daemonize yes/g' /opt/redis/redis.conf
sed -i "s#^logfile.*#logfile /opt/redis/logs/redis.log#" /opt/redis/redis.conf
sed -i "s#^dir ./#dir /opt/redis/data#" /opt/redis/redis.conf
sed -i "281a slaveof $master_IP 6379\n" /opt/redis/redis.conf
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
PIDFile=/var/run/redis_6379.pid
ExecStart=/opt/redis/bin/redis-server /opt/redis/redis.conf --daemonize no
ExecStop=/opt/redis/bin/redis-cli shutdown
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
else
echo "redis服务已存在"
fi



systemctl daemon-reload && systemctl enable redis && systemctl start redis && systemctl status redis && ps -ef|grep redis

