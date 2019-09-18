#!/bin/bash
rpm_name[1]=libevent
rpm_name[2]=libevent-devel
rpm_name[3]=gcc-4.8.5
memcached=memcached-1.5.13.tar.gz
contents=memcached-1.5.13
config="memcached"
service="memcached.service"
group=memcached
user=memcached
log=logs
path=/data/memcached
rpm_num=${#rpm_name[*]}
for ((i=1;i<=$rpm_num;i++))
do
	rpm -qa |grep ${rpm_name[$i]}
	if [ $? -ne 0 ]
		then
			yum install ${rpm_name[$i]} -y
		else
			echo "$(tput setaf 1)${rpm_name[$i]}已安装 $(tput sgr0)"
	fi
done
if [ -f "/data/$memcached" ];then
echo "memcached压缩包不存在，请解压！"
cd /data
tar -zxvf $memcached
else 
echo "memcached压缩包已存在"
fi
cd /data/$contents
./configure --prefix=/data/memcached && make && make install
if [ -G "$group" ]; then
echo "memcached用户组不存在需创建"
groupadd $group
cat /etc/group|grep $group
else
echo "memcached用户组已创建"
fi

if [ -O "$user" ]; then
echo "memcached用户不存在需创建"
useradd $user -g $group
id $user
else
echo "memcached用户已创建"
fi

if [ ! -f "/etc/sysconfig/$config" ]; then
echo "memcached配置文件不存在需创建"
cd /etc/sysconfig
touch $config
cat << EOF > $config
PORT="20199"
USER="memcached"
MAXCONN="1024"
CACHESIZE="2048"
#OPTIONS=""
PID="/data/memcached/memcached.pid"
EOF
else
echo "memcached配置文件已存在"
fi

if [ ! -f "/usr/lib/systemd/system/$service" ]; then
echo "memcached服务不存在需创建"
cd /usr/lib/systemd/system
touch $service
cat << EOF > $service
[Unit]
Description=Memcached 
Before=httpd.service
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/memcached
ExecStart=/data/memcached/bin/memcached -u \$USER -p \$PORT -m \$CACHESIZE -c \$MAXCONN -P \$PID -vv >> /data/memcached/logs/memcached.log 2>&1

[Install]
WantedBy=multi-user.target
EOF
else
echo "memcached服务已存在"
fi

if [ ! -d "/data/memcached/$log" ]; then
echo "日志文件夹不存在需创建"
cd /data/memcached
mkdir $log
else
echo "日志文件夹已创建"
fi

q=$(ls -l ${path}|sed -n '2p' |awk -F " " '{print $3}')
if [ "$q" = "memcached" ]; then
    echo 'ok'
else
    chown memcached:memcached ${path} -R
    echo 'memcached所属用户组更改完成'
    ls -l --color=auto -d $path
fi
systemctl daemon-reload && systemctl enable memcached && systemctl start memcached && systemctl status memcached && ps -ef|grep memcached

