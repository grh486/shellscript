#!/bin/bash
IP=`hostname -i`
#下载kubernetes安装包
wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kube-apiserver /usr/local/bin/
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
cat << EOF > kube-apiserver-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "$IP",
    "10.255.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
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
      "O": "k8s",
      "OU": "system"
    }
  ]
}
EOF
#生成apiserver证书
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-apiserver-csr.json | /usr/local/bin/cfssljson -bare kube-apiserver
if [ -f kube-apiserver.csr ] && [ -f kube-apiserver-key.pem ] && [ kube-apiserver.pem ]; then
	echo "apiserver 3个这证书都生成"
else
	echo "证书有问题"
fi
#生成token文件
cat > token.csv << EOF
$(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
#创建apiserver配置文件
cat << EOF > kube-apiserver.conf
KUBE_APISERVER_OPTS="--enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota --anonymous-auth=false --bind-address=$IP --secure-port=6443 --advertise-address=$IP --insecure-port=0 --authorization-mode=Node,RBAC --runtime-config=api/all=true --enable-bootstrap-token-auth --service-cluster-ip-range=10.255.0.0/16 --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=28000-50000 --tls-cert-file=/etc/kubernetes/ssl/kube-apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/kube-apiserver-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --kubelet-client-certificate=/etc/kubernetes/ssl/kube-apiserver.pem --kubelet-client-key=/etc/kubernetes/ssl/kube-apiserver-key.pem --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem --service-account-signing-key-file=/etc/kubernetes/ssl/ca-key.pem --service-account-issuer=https://kubernetes.default.svc.cluster.local --max-mutating-requests-inflight=3000 --max-requests-inflight=1000 --watch-cache-sizes=node#1000,pod#5000 --etcd-cafile=/etc/etcd/ssl/ca.pem --etcd-certfile=/etc/etcd/ssl/etcd.pem --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem --etcd-servers=https://$IP:2379 --enable-swagger-ui=true --allow-privileged=true --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/log/kube-apiserver-audit.log --event-ttl=1h --alsologtostderr=true --logtostderr=false --log-dir=/var/log/kubernetes --v=4"
EOF
#创建apiserver服务
cat << EOF > kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=etcd.service
Wants=etcd.service
 
[Service]
EnvironmentFile=-/etc/kubernetes/kube-apiserver.conf
ExecStart=/usr/local/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF
#复制文件到对应目录
cp ca*.pem /etc/kubernetes/ssl/
cp kube-apiserver*.pem /etc/kubernetes/ssl/
cp token.csv /etc/kubernetes/
cp kube-apiserver.conf /etc/kubernetes/        
cp kube-apiserver.service /usr/lib/systemd/system/
#启动服务
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver
curl --insecure https://$IP:6443/
