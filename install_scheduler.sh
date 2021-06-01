#!/bin/bash
IP=`hostname -i`
#下载kubernetes安装包
#wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
#tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kube-scheduler /usr/local/bin/
cd ../../../
#创建工作目录
if [ ! -d /etc/kubernetes/ssl ]; then
	echo "kubernetes/ssl文件夹不存在"
	if [ ! -f /etc/kubernetes/ssl ]; then
		echo "创建kubernetes文件夹及子目录ssl"
		mkdir -pv /etc/kubernetes/ssl
	fi		
else
	echo "kubernetes文件夹已存在"
fi
if [ ! -d /var/log/kubernetes ]; then
	echo "kubernetes日志文件夹不存在，需创建"
	mkdir -pv /var/log/kubernetes
else
	echo "kubernetes日志文件夹已存在"
fi
cat << EOF > kube-scheduler-csr.json
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "$IP"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "Hunan",
        "L": "Loudi",
        "O": "system:kube-scheduler",
        "OU": "system"
      }
    ]
}
EOF
#生成证书
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | /usr/local/bin/cfssljson -bare kube-scheduler
if [ -f kube-scheduler-key.pem ] && [ -f kube-scheduler.pem ]; then
	echo "scheduler 2个证书都生成"
else
	echo "证书有问题"
fi
#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$IP:6443 --kubeconfig=kube-scheduler.kubeconfig
#设置客户端认证参数
kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
#设置上下文参数
kubectl config set-context system:kube-scheduler --cluster=kubernetes --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
#设置默认上下文
kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
#创建scheduler配置文件
cat << EOF > kube-scheduler.conf
KUBE_SCHEDULER_OPTS="--address=127.0.0.1 \\
--kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
--leader-elect=true \\
--alsologtostderr=true \\
--kube-api-qps=100 \\
--logtostderr=false \\
--log-dir=/var/log/kubernetes \\
--v=2"
EOF
#创建scheduler服务
cat << EOF > kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/etc/kubernetes/kube-scheduler.conf
ExecStart=/usr/local/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5
 
[Install]
WantedBy=multi-user.target
EOF
cp kube-scheduler*.pem /etc/kubernetes/ssl/
cp kube-scheduler.kubeconfig /etc/kubernetes/
cp kube-scheduler.conf /etc/kubernetes/
cp kube-scheduler.service /usr/lib/systemd/system/
#启动服务
systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler

