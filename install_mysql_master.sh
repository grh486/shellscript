#!/bin/bash
rpm_name[1]=mariadb
rpm_name[2]=mariadb-server
rpm_name[3]=mariadb-libs
mysql=mysql-5.7.27-linux-glibc2.12-x86_64.tar.gz
contents=mysql-5.7.27-linux-glibc2.12-x86_64
group=mysql
user=mysql
conf=my.cnf
path=/opt/mysql
service="mysqld.service"
ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
#old_pass=`cat /opt/mysql/logs/mysqld.log |grep "root@localhost:"|cut -d " " -f 11`
new_pass=jianxinzhuhe
host="localhost"
port="3306"
#alter_pass_sql="ALTER USER 'root'@'localhost' IDENTIFIED BY '$new_password';"
flush_sql="flush privileges;"

rpm_num=${#rpm_name[*]}
for ((i=1;i<=$rpm_num;i++))
do
        rpm -qa |grep ${rpm_name[$i]}
        if [ $? -ne 0 ]
                then
                        yum remove ${rpm_name[$i]} -y
                else
                        echo "$(tput setaf 1)${rpm_name[$i]}已删除 $(tput sgr0)"
        fi
done

if [  -f /opt/$mysql ]; then
echo "mysql文件夹不存在，请解压！"
cd /opt
tar -zxvf $mysql
else
echo "mysql文件夹已存在"
fi

mv /opt/$contents /opt/mysql

if [ -G "$group" ]; then
echo "mysql用户组不存在需创建"
groupadd $group
cat /etc/group|grep $group
else
echo "mysql用户组已创建"
fi

if [ -O "$user" ]; then
echo "mysql用户不存在需创建"
useradd $user -g $group -s /sbin/nologin
id $user
else
echo "mysql用户已创建"
fi

if [ -f "/etc/$conf" ]; then
echo "$conf配置文件已存在"
else
echo "$conf配置文件不存在需创建"
cd /etc
touch $conf
cat << EOF > $conf
[mysqld]
basedir=/opt/mysql
datadir=/opt/mysql/data
port = 3306
socket=/tmp/mysql.sock
character-set-server=utf8
symbolic-links=0
log-error=/opt/mysql/logs/mysqld.log
pid-file=/opt/mysql/mysqld.pid
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'
[client]
#character-set-server=utf8
default-character-set=utf8
socket=/tmp/mysql.sock
[mysql]
socket=/tmp/mysql.sock
EOF
fi

#if [ ! -d "/opt/mysql/logs" ]; then
if [ ! -d "/opt/mysql/logs" ]; then
echo "日志文件夹不存在需创建"
cd /opt/mysql
mkdir logs
else
echo "日志文件夹已创建"
fi

if [ ! -d "/opt/mysql/data" ]; then
echo "数据文件夹不存在需创建"
cd /opt/mysql
mkdir data
else
echo "数据文件夹已创建"
fi

q=$(ls -l ${path}|sed -n '2p' |awk -F " " '{print $3}')
if [ "$q" = "mysql" ]; then
    echo 'ok'
else
    chown mysql:mysql ${path} -R
    echo 'mysql所属用户组更改完成'
    ls -l --color=auto -d $path
fi

/opt/mysql/bin/mysqld --initialize --user=mysql --basedir=/opt/mysql --datadir=/opt/mysql/data

echo "export PATH=/opt/mysql/bin:\$PATH" >> /etc/profile
source /etc/profile
source /etc/profile

if [ ! -f "/usr/lib/systemd/system/$service" ]; then
echo "mysql服务不存在需创建"
cd /usr/lib/systemd/system
touch $service
cat << EOF > $service
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# systemd service file for MySQL forking server
#

[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql
ExecStart=/opt/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
EOF
else
echo "mysql服务已存在"
fi

systemctl daemon-reload && systemctl enable mysqld && systemctl start mysqld && systemctl status mysqld && ps -ef|grep mysqld
sleep 1
old_pass=`grep 'A temporary password' /opt/mysql/logs/mysqld.log | awk -F "root@localhost: " '{ print $2}' `
echo $old_pass
mysql -uroot -p$old_pass --connect-expired-password -e"alter  user 'root'@'localhost' identified by '$new_pass';"
mysql -uroot -p$new_pass --connect-expired-password -e"grant ALL on *.* TO root@'localhost' IDENTIFIED by '$new_pass' WITH GRANT OPTION;"
mysql -uroot -p$new_pass --connect-expired-password -e"grant ALL on *.* TO root@'127.0.0.1' IDENTIFIED by '$new_pass' WITH GRANT OPTION;"
mysql -uroot -p$new_pass --connect-expired-password -e"grant ALL on *.* TO root@'%' IDENTIFIED by '$new_pass' WITH GRANT OPTION;"
mysql -uroot -p$new_pass -e"flush privileges"
echo "修改主节点配置"
sed -i "10a server-id=1" /etc/my.cnf
sed -i "11a log-bin=MySQL-bin" /etc/my.cnf
sed -i "12a binlog_format=mixed" /etc/my.cnf
sed -i "13a expire_logs_days=30" /etc/my.cnf
sed -i "14a max_binlog_size=1G" /etc/my.cnf
sed -i "15a binlog_cache_size = 8m" /etc/my.cnf
sed -i "16a max_binlog_cache_size = 1G" /etc/my.cnf
sed -i "17a sync_binlog=1" /etc/my.cnf
sed -i "18a innodb_flush_log_at_trx_commit=1" /etc/my.cnf
sed -i "19a log-bin = /opt/mysql/logs/mysql-bin" /etc/my.cnf
echo "重启MySQL服务"
systemctl restart mysqld;systemctl status mysqld;ps -ef|grep mysqld
sleep 1
mysql -uroot -p$new_pass -e"show master status;"
mysql -uroot -p$new_pass --connect-expired-password -e"grant replication slave on *.* to 'root'@'$ip' identified by '$new_pass';"
mysql -uroot -p$new_pass -e"show master status;"
