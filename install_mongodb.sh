#!/bin/bash
cd /opt
tar -xvf mongodb-linux-x86_64-rhel70-4.4.6.tgz
mv mongodb-linux-x86_64-rhel70-4.4.6 mongodb

if [ ! -G "mongod" ]; then
echo "mongod用户组已创建"
else
echo "mongod用户组不存在需创建"
groupadd mongod
cat /etc/group|grep mongod
fi

if [ ! -O "mongod" ]; then
echo "mongod用户已创建"
else
echo "mongod用户不存在需创建"
useradd -r -s /sbin/nologin -M mongod -g mongod
id mongod
fi

echo "创建MongoDB日志目录"
if [ ! -d "/opt/mongodb/logs" ]; then
echo "logs文件夹不存在需创建"
mkdir /opt/mongodb/logs
else
echo "logs文件夹存在"
fi

echo "创建MongoDB数据目录"
if [ ! -d "/opt/mongodb/data" ]; then
echo "data文件夹不存在需创建"
mkdir /opt/mongodb/data
else
echo "data文件夹存在"
fi

if [ ! -f "/etc/mongod.conf" ]; then
echo "monngodb配置文件不存在需创建"
cd /etc
touch mongod.conf
cat << EOF > mongod.conf
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /opt/mongodb/logs/mongod.log

# Where and how to store data.
storage:
  dbPath: /opt/mongodb/data
  journal:
    enabled: true
#  engine:
  wiredTiger:
    engineConfig:
      configString : cache_size=2G

# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.


#security:

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options

#auditLog:

#snmp:
EOF
else
echo "mongodb配置文件已存在"
fi

if [ ! -f "/usr/lib/systemd/system/mongod.service" ]; then
echo "mongodb服务不存在需创建"
cd /usr/lib/systemd/system
touch mongod.service
cat << EOF > mongod.service
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=mongod
Group=mongod
Environment="OPTIONS=-f /etc/mongod.conf"
EnvironmentFile=-/etc/sysconfig/mongod
ExecStart=/opt/mongodb/bin/mongod \$OPTIONS
ExecStartPre=/usr/bin/mkdir -p /var/run/mongodb
ExecStartPre=/usr/bin/chown mongod:mongod /var/run/mongodb
ExecStartPre=/usr/bin/chmod 0755 /var/run/mongodb
PermissionsStartOnly=true
PIDFile=/var/run/mongodb/mongod.pid
Type=forking
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for mongod as specified in
# https://docs.mongodb.com/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target
EOF
else
echo "mongodb服务已存在"
fi

/usr/bin/chown -R mongod:mongod /opt/mongodb
systemctl daemon-reload && systemctl enable mongod && systemctl start mongod && systemctl status mongod && ps -ef|grep mongod

lsof -i:27017
