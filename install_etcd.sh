#!/bin/bash
IP=`hostname -i`
if [ ! -d /etc/etcd/ssl ]; then
	echo "etcd/ssl文件夹不存在"
	if [ ! -d /etc/etcd ]; then
		echo "创建etcd文件夹及子目录ssl"
		mkdir -pv /etc/etcd/ssl
	fi		
else
	echo "etcd文件夹已存在"
fi
#工具下载
wget -T 15 -c https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sleep 2
wget -T 15 -c https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sleep 2
wget -T 15 -c https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
#授权
chmod +x cfssl*
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
#创建ca-json请求文件文件
cat << EOF > ca-csr.json
{
  "CN": "kubernetes",
  "key": {
      "algo": "rsa",
      "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Hunan",
      "L": "Loudi",
      "O": "k8s",
      "OU": "system"
    }
  ],
  "ca": {
          "expiry": "876000h"
  }
}
EOF
#创建CA证书
/usr/local/bin/cfssl gencert -initca ca-csr.json  | /usr/local/bin/cfssljson -bare ca
if [ -f ca.csr ] && [ -f ca-key.pem ] && [ -f ca.pem ]; then
	echo "ca 3个证书都生成"
else
	echo "证书有问题"
fi
#创建ca证书策略
cat << EOF > ca-config.json
{
  "signing": {
      "default": {
          "expiry": "876000h"
        },
      "profiles": {
          "kubernetes": {
              "usages": [
                  "signing",
                  "key encipherment",
                  "server auth",
                  "client auth"
              ],
              "expiry": "876000h"
          }
      }
  }
}
EOF
#配置etcd请求csr文件
cat << EOF > etcd-csr.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "$IP"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "CN",
    "ST": "Hunan",
    "L": "Loudi",
    "O": "k8s",
    "OU": "system"
  }]
}
EOF
#生成证书
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes etcd-csr.json | /usr/local/bin/cfssljson -bare etcd
if [ -f etcd-key.pem ] && [ -f etcd.pem ]; then
        echo "etcd 2个证书都生成"
else
        echo "证书有问题"
fi
#下载etcd二进制包
wget -T 15 -c https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz
#解压
tar -zxvf etcd-v3.4.15-linux-amd64.tar.gz
cp -p etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/
#创建etcd配置文件
cat << EOF > etcd.conf
#[Member]
ETCD_NAME="default"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://$IP:2380"
ETCD_LISTEN_CLIENT_URLS="https://$IP:2379,http://127.0.0.1:2379"
EOF
#创建etcd服务
cat << EOF > etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
 
[Service]
Type=notify
EnvironmentFile=-/etc/etcd/etcd.conf
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --cert-file=/etc/etcd/ssl/etcd.pem \\
  --key-file=/etc/etcd/ssl/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-client-cert-auth \
  --client-cert-auth
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF
#同步相关文件到各个节点
cp ca*.pem /etc/etcd/ssl/
cp etcd*.pem /etc/etcd/ssl/
cp etcd.conf /etc/etcd/
cp etcd.service /usr/lib/systemd/system/
#启动etcd集群
mkdir -pv /var/lib/etcd/default.etcd
systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service
systemctl status etcd
lsof -i:2379
lsof -i:2380
sleep 6
/usr/local/bin/etcdctl endpoint health
/usr/local/bin/etcdctl endpoint status
