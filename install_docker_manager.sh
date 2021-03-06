#!/bin/bash
#卸载旧版本docker
yum remove docker docker-common docker-selinux -y
#使用仓库安装
#安装需要的依赖包
yum install -y yum-utils device-mapper-persistent-data
#配置稳定仓库
#yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce -y
#启动docker服务
systemctl enable docker;systemctl start docker;systemctl status docker

if [ ! -d "/etc/docker" ]; then
echo "docker文件夹不存在需创建"
cd /etc
mkdir docker
else
echo "docker文件夹已创建"
fi

if [ ! -f "/etc/docker/daemon.json" ]; then
echo "docker配置文件不存在需创建"
cd /etc/docker
touch daemon.json
cat << EOF > daemon.json
{
"registry-mirrors": ["http://hub-mirror.c.163.com"],
"insecure-registries":["47.106.8.39:81"]
}
EOF
else
echo "docker配置文件已存在"
fi
systemctl restart docker;systemctl status docker
sleep 1
docker pull swarm
read -t 60 -p "请输入本机的IP：" ip
echo -e "\n"
docker swarm init --advertise-addr $ip
docker swarm join-token manager
#docker login 47.106.8.39:81
 
