#!/bin/bash
cd /opt
unzip rocketmq-all-4.8.0-bin-release.zip
mv rocketmq-all-4.8.0-bin-release rocketmq
read -t 60 -p "请输入rocketmq的IP：" rocketmq_IP
echo -e "\n"
echo "rocketmq的IP为：$rocketmq_IP"
echo "brokerIP=$rocketmq_IP" >> /opt/rocketmq/conf/broker.conf

if [ ! -f "/usr/lib/systemd/system/rocketmq-broker.service" ]; then
echo "rocketmq-broker服务不存在需创建"
cd /usr/lib/systemd/system
touch rocketmq-broker.service
cat << EOF > rocketmq-broker.service
[Unit]
Description=rocketmq - broker-master-2
Documentation=http://mirror.bit.edu.cn/apache/rocketmq/
After=network.target rocketmq-namesrv.service

[Service]
Type=sample
User=root
ExecStart=/data/rocketmq/bin/mqbroker -n $rocketmq_IP:9876 -c /data/rocketmq/conf/broker.conf autoCreateTopicEnable=true
ExecReload=/usr/bin/kill -s HUP $MAINPID
ExecStop=/usr/bin/kill -s QUIT $MAINPID
Restart=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
else
echo "rocketmq-broker服务已存在"
fi

if [ ! -f "/usr/lib/systemd/system/rocketmq-namesrv.service" ]; then
echo "rocketmq-namesrv服务不存在需创建"
cd /usr/lib/systemd/system
touch rocketmq-namesrv.service
cat << EOF > rocketmq-namesrv.service
[Unit]
Description=rocketmq - nameserver
Documentation=http://mirror.bit.edu.cn/apache/rocketmq/
After=network.target

[Service]
Type=sample
User=root
ExecStart=/opt/rocketmq/bin/mqnamesrv
ExecReload=/usr/bin/kill -s HUP $MAINPID
ExecStop=/usr/bin/kill -s QUIT $MAINPID
Restart=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
else
echo "rocketmq-namesrv服务已存在"
fi

#启动服务
systemctl daemon-reload && systemctl enable rocketmq-broker rocketmq-namesrv && systemctl start rocketmq-broker rocketmq-namesrv && systemctl status rocketmq-broker rocketmq-namesrv && ps -ef|grep rocketmq-broker && ps -ef|grep rocketmq-namesrv

#查看端口
lsof -i:9876
lsof -i:10911

#配置环境变量
echo "export PATH=/opt/rocketmq/bin:\$PATH" >> /etc/profile
source /etc/profile

#导入主题
if [ ! -f "/opt/topiclist" ]; then
echo "topiclist文件不存在需创建"
cd /opt
touch topiclist
cat << EOF > topiclist
receivable_financing-sas
receivable_invoice-sas
receivable_issue-sas
receivable_repurchase-sas
receivable_signin-sas
receivable_tokensource-sas
receivable_userInfo-sas
recmsg-sas
recsms-sas
rec_email-sas
rec_simple_email-sas
receivable-business-log-sas
receivable_assign-sas
receivable_assign_signin-sas
receivable_basicinfo-sas
receivable_credit-sas
receivable_document-sas
receivable_invoke-sas
receivable_repayment-sas
EOF
else
echo "topiclist文件已存在"
fi

echo "导入rocketmq topic"
for i in `cat /opt/topiclist`
do
/opt/rocketmq/bin/mqadmin updateTopic -n 127.0.0.1:9876 -b 127.0.0.1:10911 -t $i
done
echo "#################################topic创建完成#################################"
