#!/bin/bash
IP=`hostname -i`
wget -T 15 -c https://dl.k8s.io/v1.18.19/kubernetes-server-linux-amd64.tar.gz
tar -zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/
cp kubectl /usr/local/bin/
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
cat << EOF > admin-csr.json
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Hunan",
      "L": "Loudi",
      "O": "system:masters",             
      "OU": "system"
    }
  ]
}
EOF
#生成证书
/usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | /usr/local/bin/cfssljson -bare admin
if [ -f admin-key.pem ] && [ -f admin.pem ]; then
	echo "kubectl 2个证书都生成"
else
	echo  "证书有问题"
fi
#设置集群参数
/usr/local/bin/kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://$IP:6443 --kubeconfig=kube.config
#设置客户端认证参数
/usr/local/bin/kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=kube.config
#设置上下文参数
/usr/local/bin/kubectl config set-context kubernetes --cluster=kubernetes --user=admin --kubeconfig=kube.config
#设置默认上下文
/usr/local/bin/kubectl config use-context kubernetes --kubeconfig=kube.config
mkdir -pv ~/.kube
cp kube.config ~/.kube/config
#授权kubernetes证书访问kubectl api权限
/usr/local/bin/kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes
#查看集群组件状态
/usr/local/bin/kubectl cluster-info
/usr/local/bin/kubectl get componentstatuses
/usr/local/bin/kubectl get all --all-namespaces
#配置kubectl子命令补全
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
/usr/local/bin/kubectl completion bash > ~/.kube/completion.bash.inc
source '/root/.kube/completion.bash.inc'  
source $HOME/.bash_profile

