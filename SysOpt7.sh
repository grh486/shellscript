#!/bin/bash
#判断不支持发行版,只支持CentOS 7,RHEL 7
cat /etc/*release | grep -e "Red Hat Enterprise Linux Server 7" -e "CentOS Linux release 7" > /dev/null 2>&1
if [ $? -ne 0 ]
    then
	    echo "$(tput setaf 1) 不支持的发行版! $(tput sgr0)"
	    exit 88
fi

# 判断是否root用户
/usr/bin/id | grep -o "uid=0" > /dev/null 2>&1
if [ $? -ne 0 ]
    then
        echo "$(tput setaf 1)当前用户为普通用户，请使用root运行脚本,命令: su - root $(tput sgr0)"
        exit 88
fi

#设置最大打开文件描述符数
echo "增加文件数量"
echo "ulimit -SHn 102400" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*	soft	nofile	65536
*	hard	nofile	65536
*	soft	nproc	65536
*	hard	nproc	65536
EOF
/bin/cp -p /etc/pam.d/login /etc/pam.d/login.`date +%F_%H-%M-%S`.bak
sed --in-place '/lib64/d' /etc/pam.d/login
echo "session required /lib64/security/pam_limits.so" >> /etc/pam.d/login

# 安装常用软件
echo "安装常用软件"
yum install net-tools vim tree htop iotop iftop iotop lrzsz sl wget unzip telnet nmap nc psmisc dos2unix bash-completion sysstat rsync nfs-utils remi-release epel-release -y
yum clean all
yum makecache

# yum修复系统漏洞
echo "修复系统漏洞"
yum update -yum

# 缩短ssh登录时间
echo "优化ssh登录时间"
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl  restart sshd

# 优化systemd服务
echo "优化systemd服务"
/bin/cp -p /etc/systemd/system.conf /etc/systemd/system.conf.`date +%F_%H-%M-%S`.bak
sed --in-place '/^DefaultLimitCORE/d' /etc/systemd/system.conf
sed --in-place '/^DefaultLimitNOFILE/d' /etc/systemd/system.conf
sed --in-place '/^DefaultLimitNPROC/d' /etc/systemd/system.conf
echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=10240000" >> /etc/systemd/system.conf
echo "DefaultLimitNPROC=10240000" >> /etc/systemd/system.conf
#Reexecute the systemd manager
systemctl daemon-reexec

# 优化内核参数
echo "优化内核"
/bin/cp -p /etc/sysctl.conf /etc/sysctl.conf.`date +%F_%H-%M-%S`.bak
sed --in-place '/^fs.nr_open/d' /etc/sysctl.conf
sed --in-place '/^fs.file-max/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
sed --in-place '/^fs.aio-max-nr/d' /etc/sysctl.conf
sed --in-place '/^net.core.rmem_default/d' /etc/sysctl.conf
sed --in-place '/^net.core.wmem_default/d' /etc/sysctl.conf
sed --in-place '/^net.core.rmem_max/d' /etc/sysctl.conf
sed --in-place '/^net.core.wmem_max/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_rmem/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_wmem/d' /etc/sysctl.conf
sed --in-place '/^net.core.netdev_max_backlog/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_tw_reuse /d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_tw_recycle /d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
sed --in-place '/^net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
sed --in-place '/^net.netfilter.nf_conntrack_max/d' /etc/sysctl.conf
sed --in-place '/^net.netfilter.nf_conntrack_tcp_timeout_established/d' /etc/sysctl.conf
#disable ipv6
sed --in-place '/^net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
sed --in-place '/^net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf

echo "fs.nr_open = 10240000" >> /etc/sysctl.conf
echo "fs.file-max = 10240000" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "net.core.rmem_default = 1048576" >> /etc/sysctl.conf
echo "net.core.wmem_default = 524288" >> /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 2500" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 102400" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 10000" >> /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_max = 4000000" >> /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_tcp_timeout_established = 1200" >> /etc/sysctl.conf
#disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

#effect immediately
/sbin/sysctl -p /etc/sysctl.conf 
