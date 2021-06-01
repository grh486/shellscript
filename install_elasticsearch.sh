#!/bin/bash
group=elasticsearch
user=elasticsearch
conf=elasticsearch
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
service=elasticsearch.service
# 判断是否安装JDK
java -version
if [ $? -ne 0 ]
    then
        echo "$(tput setaf 1) 当前系统没有安装JDK,请先安装Oracle JDK$(tput sgr0)"
        exit 88
fi
# 判断是否安装Oracle JDK
java -version > /tmp/java.tmp 2>&1 && cat /tmp/java.tmp | grep -o OpenJDK
if [ $? -eq 0 ]
    then
        echo "$(tput setaf 1)当前使用系统自带OpenJDK,请先安装Oracle JDK$(tput sgr0)"
        exit 88
fi

if [ -f /opt/elasticsearch-5.6.9.tar.gz ]; then
echo "elasticsearch压缩包不存在，请解压！"
cd /opt
tar -zxvf elasticsearch-5.6.9.tar.gz
mv elasticsearch-5.6.9 elasticsearch
else
echo "elasticsearch压缩包已存在"
fi

if [  -G "$group" ]; then
echo "elasticsearch用户组不存在需创建"
groupadd $group
cat /etc/group|grep $group
else
echo "elasticsearch用户组已创建"
fi

if [  -O "$user" ]; then
echo "elasticsearch用户不存在需创建"
useradd -r $user -g $group -s /sbin/nologin
id $user
else
echo "elasticsearch用户已创建"
fi

if [ -f "/etc/sysconfig/elasticsearch" ]; then
echo "$conf配置文件已存在"
else
echo "$conf配置文件不存在需创建"
cd /etc/sysconfig
touch $conf
cat << EOF > $conf
################################
# Elasticsearch
################################

# Elasticsearch home directory
ES_HOME=/opt/elasticsearch

# Elasticsearch Java path
JAVA_HOME=/usr/local/jdk1.8.0_231

# Elasticsearch configuration directory
CONF_DIR=/opt/elasticsearch/config

# Elasticsearch data directory
DATA_DIR=/opt/elasticsearch/data

# Elasticsearch logs directory
LOG_DIR=/opt/elasticsearch/logs

# Elasticsearch PID directory
PID_DIR=/opt/elasticsearch

# Additional Java OPTS
#ES_JAVA_OPTS=

# Configure restart on package upgrade (true, every other setting will lead to not restarting)
#RESTART_ON_UPGRADE=true

################################
# Elasticsearch service
################################

# SysV init.d
#
# When executing the init script, this user will be used to run the elasticsearch service.
# The default value is 'elasticsearch' and is declared in the init.d file.
# Note that this setting is only used by the init script. If changed, make sure that
# the configured user can read and write into the data, work, plugins and log directories.
# For systemd service, the user is usually configured in file /usr/lib/systemd/system/elasticsearch.service
ES_USER=elasticsearch
ES_GROUP=elasticsearch

# The number of seconds to wait before checking if Elasticsearch started successfully as a daemon process
ES_STARTUP_SLEEP_TIME=5

################################
# System properties
################################

# Specifies the maximum file descriptor number that can be opened by this process
# When using Systemd, this setting is ignored and the LimitNOFILE defined in
# /usr/lib/systemd/system/elasticsearch.service takes precedence
MAX_OPEN_FILES=65536

# The maximum number of bytes of memory that may be locked into RAM
# Set to "unlimited" if you use the 'bootstrap.memory_lock: true' option
# in elasticsearch.yml.
# When using systemd, LimitMEMLOCK must be set in a unit file such as
# /etc/systemd/system/elasticsearch.service.d/override.conf.
MAX_LOCKED_MEMORY=unlimited

# Maximum number of VMA (Virtual Memory Areas) a process can own
# When using Systemd, this setting is ignored and the 'vm.max_map_count'
# property is set at boot time in /usr/lib/sysctl.d/elasticsearch.conf
MAX_MAP_COUNT=262144
EOF
fi

if [ ! -d "/opt/elasticsearch/logs" ]; then
echo "日志文件夹不存在需创建"
cd /opt/elasticsearch
mkdir logs
else
echo "日志文件夹已创建"
fi

if [ ! -d "/opt/elasticsearch/data" ]; then
echo "数据文件夹不存在需创建"
cd /opt/elasticsearch
mkdir data
else
echo "数据文件夹已创建"
fi

#修改elasticsearch配置文件
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/g' /opt/elasticsearch/config/elasticsearch.yml
/usr/bin/chown -R elasticsearch:elasticsearch /opt/elasticsearch

if [ ! -f "/usr/lib/systemd/system/$service" ]; then
echo "elasticsearch服务不存在需创建"
cd /usr/lib/systemd/system
touch $service
cat << EOF > $service
[Unit]
Description=Elasticsearch
Documentation=http://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
Environment=ES_HOME=/opt/elasticsearch
Environment=CONF_DIR=/opt/elasticsearch/config
Environment=DATA_DIR=/opt/elasticsearch/data
Environment=LOG_DIR=/opt/elasticsearch/logs
Environment=PID_DIR=/opt/elasticsearch
EnvironmentFile=-/etc/sysconfig/elasticsearch

WorkingDirectory=/opt/elasticsearch

User=elasticsearch
Group=elasticsearch

ExecStartPre=/opt/elasticsearch/bin/elasticsearch-systemd-pre-exec

ExecStart=/opt/elasticsearch/bin/elasticsearch \\
                                                -p \${PID_DIR}/elasticsearch.pid \\
                                                --quiet \\
                                                -Edefault.path.logs=\${LOG_DIR} \\
                                                -Edefault.path.data=\${DATA_DIR} \\
                                                -Edefault.path.conf=\${CONF_DIR}

# StandardOutput is configured to redirect to journalctl since
# some error messages may be logged in standard output before
# elasticsearch logging system is initialized. Elasticsearch
# stores its logs in /var/log/elasticsearch and does not use
# journalctl by default. If you also want to enable journalctl
# logging, you can simply remove the "quiet" option from ExecStart.
StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of processes
LimitNPROC=2048

# Specifies the maximum size of virtual memory
LimitAS=infinity

# Specifies the maximum file size
LimitFSIZE=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM

# Send the signal only to the JVM rather than its control group
KillMode=process

# Java process is never killed
SendSIGKILL=no

# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target

# Built for distribution-5.6.9 (distribution)

EOF
else
echo "elasticsearch服务已存在"
fi



systemctl daemon-reload && systemctl enable elasticsearch && systemctl start elasticsearch && systemctl status elasticsearch && ps -ef|grep elasticsearch
