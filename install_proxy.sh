#!/bin/bash
IP=`hostname -i`
#下载kubernetes安装包
#wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
#tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kube-proxy /usr/local/bin/
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
cat << EOF > kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
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
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | /usr/local/bin/cfssljson -bare kube-proxy
if [ -f kube-proxy-key.pem ] && [ -f kube-proxy.pem ]; then
	echo "proxy 2个证书都生成"
else
	echo "证书有问题"
fi
#创建kubeconfig文件
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$IP:6443 --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
#创建proxy配置文件
cat << EOF > kube-proxy.yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: $IP
clientConnection:
  kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
clusterCIDR: 10.0.0.0/16
healthzBindAddress: $IP:10256
kind: KubeProxyConfiguration
metricsBindAddress: $IP:10249
mode: "ipvs"
EOF
#创建proxy服务
cat << EOF > kube-proxy.service
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
 
[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/etc/kubernetes/kube-proxy.yaml \\
  --alsologtostderr=true \\
  #--hostname-override=k8s-master \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF
cp kube-proxy*.pem /etc/kubernetes/ssl/
cp kube-proxy.kubeconfig kube-proxy.yaml /etc/kubernetes/
cp kube-proxy.service /usr/lib/systemd/system/
if [ ! -d "/var/lib/kube-proxy" ]; then
	echo "proxy文件夹不存在，需创建"
	mkdir /var/lib/kube-proxy
else
	echo "proxy文件夹存在，无需创建"
fi
systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
systemctl status kube-proxy

