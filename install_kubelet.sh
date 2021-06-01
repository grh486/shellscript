#!/bin/bash
IP=`hostname -i`
#下载kubernetes安装包
#wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
#tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kubelet /usr/local/bin/
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
#创建kubelet-bootstrap.kubeconfig
BOOTSTRAP_TOKEN=$(awk -F "," '{print $1}' /etc/kubernetes/token.csv)
#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$IP:6443 --kubeconfig=kubelet-bootstrap.kubeconfig
#设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=kubelet-bootstrap.kubeconfig
#设置上下文参数
kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=kubelet-bootstrap.kubeconfig
#设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig
#创建角色绑定
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
#创建kubelet配置文件
cat << EOF > kubelet.json
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": "/etc/kubernetes/ssl/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "address": "$IP",
  "port": 10250,
  "readOnlyPort": 10255,
  "cgroupDriver": "cgroupfs",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "cluster.local.",
  "clusterDNS": ["10.255.0.2"]
}
EOF
#创建kubelet服务
cat << EOF > kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service
 
[Service]
WorkingDirectory=/var/lib/kubelet
[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \\
  --hostname-override=k8s-master \\
  --cert-dir=/etc/kubernetes/ssl \\
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
  --config=/etc/kubernetes/kubelet.json \\
  --network-plugin=cni \\
  --cni-bin-dir=/opt/cni/bin \\
  --cni-conf-dir=/etc/cni/net.d \\
  --pod-infra-container-image=k8s.gcr.io/pause:3.2 \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --max-pods=1500 \\
  --image-pull-progress-deadline=2m \\
  --runtime-request-timeout=4m \\
  --housekeeping-interval=30s \\
  --v=2
Restart=on-failure
RestartSec=5
 
[Install]
WantedBy=multi-user.target
EOF
#复制文件
cp kubelet-bootstrap.kubeconfig /etc/kubernetes/
cp kubelet.json /etc/kubernetes/
cp kubelet.service /usr/lib/systemd/system/
#启动服务
if [ ! -d "/var/lib/kubelet" ]; then
	echo "kubelet文件夹不存在，需创建"
	mkdir /var/lib/kubelet
else
	echo "kubelet文件夹存在，无需创建"
fi
if [ ! -d "/var/log/kubernetes" ]; then
	echo "kubernetes日志文件夹不存在，需创建"
	mkdir /var/log/kubernetes
else
	echo "kubernetes日志文件夹已存在，无需创建"
fi
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet
/usr/local/bin/kubectl get csr
/usr/local/bin/kubectl certificate approve $(/usr/local/bin/kubectl get csr|sed -n '2p'|awk '{print $1}')
/usr/local/bin/kubectl get csr
/usr/local/bin/kubectl get nodes
