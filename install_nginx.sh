#!/bin/bash
yum -y install zlib zlib-devel openssl openssl-devel pcre pcre-devel ncurses-devel gcc gcc-c++
nginx="nginx-1.20.0.tar.gz"
if [  -f /opt/$nginx ]; then
echo "nginx文件夹不存在，请解压！"
cd /opt
tar -zxvf $nginx
else
echo "nginx文件夹已存在"
fi

if [ -G "nginx" ]; then
echo "nginx用户组已创建"
else
echo "nginx用户组不存在需创建"
groupadd nginx
cat /etc/group|grep nginx
fi

if [  -O "nginx" ]; then
echo "nginx用户已创建"
else
echo "nginx用户不存在需创建"
useradd -r -s /sbin/nologin -M nginx -g nginx
id nginx
fi

cd /opt/nginx-1.20.0
./configure --user=nginx --group=nginx --prefix=/opt/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module
make
make install

#配置环境变量
echo "export PATH=/opt/nginx/sbin:\$PATH" >> /etc/profile
source /etc/profile
source /etc/profile

if [ ! -f "/usr/lib/systemd/system/nginx.service" ]; then
echo "nginx服务不存在需创建"
cd /usr/lib/systemd/system
touch nginx.service
cat << EOF > nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/opt/nginx/logs/nginx.pid
ExecStart=/opt/nginx/sbin/nginx -c /opt/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
user=nginx
group=nginx

[Install]
WantedBy=multi-user.target
EOF
else
echo "nginx服务已存在"
fi

if [ ! -f "/etc/logrotate.d/nginx" ]; then
echo "nginx日志切分文件不存在需创建"
cd /etc/logrotate.d/
touch nginx
cat << EOF > nginx
/opt/nginx/logs/*log {
    create 0664 nginx root
    daily
    rotate 10
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /bin/kill -USR1 `cat /run/nginx.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF
else
echo "nginx日志切分文件已存在"
fi
#启动服务
systemctl daemon-reload && systemctl enable nginx && systemctl start nginx && systemctl status nginx && ps -ef|grep nginx
