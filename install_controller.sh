#!/bin/bash
IP=`hostname -i`
#下载kubernetes安装包
#wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
#tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kube-controller-manager /usr/local/bin/
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
#创建csr请求文件 
cat << EOF > kube-controller-manager-csr.json
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "$IP"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "Hunan",
        "L": "Loudi",
        "O": "system:kube-controller-manager",
        "OU": "system"
      }
    ]
}
EOF
#生成证书
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | /usr/local/bin/cfssljson -bare kube-controller-manager
if [ -f kube-controller-manager-key.pem ] && [ -f kube-controller-manager.pem ]; then
	echo "controller-manager 2个证书都生成"
else
	echo "证书有问题"
fi
#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$IP:6443 --kubeconfig=kube-controller-manager.kubeconfig
#设置客户端认证参数
kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-manager.pem --client-key=kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
#设置上下文参数
kubectl config set-context system:kube-controller-manager --cluster=kubernetes --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
#设置默认上下文
kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
#创建controller-manager配置文件
cat << EOF > kube-controller-manager.conf
KUBE_CONTROLLER_MANAGER_OPTS="--port=0 \\
  --secure-port=10252 \\
  --bind-address=127.0.0.1 \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --service-cluster-ip-range=10.255.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.0.0.0/16 \\
  --experimental-cluster-signing-duration=876000h \\
  --root-ca-file=/etc/kubernetes/ssl/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \\
  --kube-api-qps=100 \\
  --kube-api-burst=100 \\
  --leader-elect=true \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --horizontal-pod-autoscaler-use-rest-clients=true \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --tls-cert-file=/etc/kubernetes/ssl/kube-controller-manager.pem \\
  --tls-private-key-file=/etc/kubernetes/ssl/kube-controller-manager-key.pem \\
  --use-service-account-credentials=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2"
EOF
#创建controller-manager服务
cat << EOF > kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/etc/kubernetes/kube-controller-manager.conf
ExecStart=/usr/local/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5
 
[Install]
WantedBy=multi-user.target
EOF
#复制文件
cp kube-controller-manager*.pem /etc/kubernetes/ssl/
cp kube-controller-manager.kubeconfig /etc/kubernetes/
cp kube-controller-manager.conf /etc/kubernetes/
cp kube-controller-manager.service /usr/lib/systemd/system/
#启动服务
systemctl daemon-reload 
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

