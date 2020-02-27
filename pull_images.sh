#!/bin/bash
version=24.0
docker pull swarm
read -t 60 -p "请输入本机的IP：" ip
echo -e "\n"
docker swarm init --advertise-addr $ip
docker swarm join-token manager
# 登录docker镜像仓库拉取伊OS镜像
docker login registry.cn-shenzhen.aliyuncs.com --username=深圳市建科院 --password='Qwertyuiop!@#'
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/activiti:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/bigscreen:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/common:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/company:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/config:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/coordinatecompany:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/dictionary:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/eureka:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/file:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/gateway:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/id:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/ireport:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/menuoperaterole:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/project:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/quartz:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/repacket:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/sign:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/team:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/user:$version
docker pull registry.cn-shenzhen.aliyuncs.com/pro-external/workcircle:$version

if [ ! -d "/usr/local/docker-service-file" ]; then
echo "伊OS启动文件夹不存在需创建"
cd /usr/local/
mkdir -pv /usr/local/docker-service-file
else
echo "伊OS启动文件夹已创建"
fi

if [ ! -f "/usr/local/docker-service-file/config_local.sh" ]; then
echo "配置中心服务不存在需创建"
cd /usr/local/docker-service-file/
touch config_local.sh
#输入要配置的项目名称
read -t 60 -p "请输入要配置的项目名称：" project_name
echo -e "\n"
read -t 60 -p "请输入要连接kafka的IP：" kafka_ip
echo -e "\n"
read -t 60 -p "请输入要连接kafka的端口：" kafka_port
echo -e "\n"
read -t 60 -p "请输入要连接zookeeper的IP：" zookeeper_ip
echo -e "\n"
read -t 60 -p "请输入要连接zookeeper的端口：" zookeeper_port
echo -e "\n"
echo '#!/bin/bash' > /usr/local/docker-service-file/config_local.sh
echo 'count=`docker service ls|grep config|wc -l`
if [ 0 == $count ];then
        echo "创建config服务"
        sudo docker service create --with-registry-auth \
                --publish published=10003,target=10003,mode=host \
                --name config   \
                --replicas 1  \
                --network app_net \
                --env server_port=10003  \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/ \
                --env spring_cloud_config_server_git_url=http://admin@xcx.tgct.com.cn:5555/r/eosconfigcenter.git \
                --env spring_cloud_config_server_git_search-paths=/'$project_name' \
                --env spring_cloud_config_server_git_username=admin \
                --env spring_cloud_config_server_git_password=Qwertyuiop \
                --env spring_cloud_config_server_native_search-locations=/etc/config \
                --env spring_profiles_active=native \
                --env spring_cloud_stream_kafka_binder_brokers='$kafka_ip':'$kafka_port'   \
                --env spring_cloud_stream_kafka_binder_zk-nodes='$zookeeper_ip':'$zookeeper_port'  \
                --env JAVA_ENV='\'-Xmx128m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                --mount type=bind,source=/usr/local/docker-service-file/config,destination=/etc/config \
                registry.cn-shenzhen.aliyuncs.com/pro-external/config:'$version'
        else
        echo "更新config服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/config:'$version' \
        --force \
        config
fi' >> /usr/local/docker-service-file/config_local.sh
else
	echo "配置中心服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/eureka.sh" ]; then
echo "注册中心服务不存在需创建"
cd /usr/local/docker-service-file/
touch eureka.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/eureka.sh
echo 'count1=`docker service ls|grep eureka1|wc -l`
if [ 0 == $count1 ];then
        echo "创建eureka1服务"
        sudo docker service create --with-registry-auth \
                --publish published=10001,target=10001,mode=host \
                --name eureka1   \
                --hostname eureka1 \
                --replicas 1  \
                --network app_net \
                --env server_port=10001 \
                --env eureka_instance_hostname=eureka1 \
                --env eureka_client_register-with-eureka=true \
                --env eureka_client_fetch-registry=true \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/ \
                --env eureka_server_enable-self-preservation=false \
                --env JAVA_ENV='\'-Xmx128m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/eureka:'$version'
        else
        echo "更新eureka1服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/eureka:'$version' \
        --force \
        eureka1
fi

count2=`docker service ls|grep eureka2|wc -l`
if [ 0 == $count2 ];then
        echo "创建eureka2服务"
        sudo docker service create --with-registry-auth \
                --publish published=10002,target=10002,mode=host \
                --name eureka2   \
                --hostname eureka2 \
                --replicas 1  \
                --network app_net \
                --env server_port=10002 \
                --env eureka_instance_hostname=eureka2 \
                --env eureka_client_register-with-eureka=true \
                --env eureka_client_fetch-registry=true \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/ \
                --env eureka_server_enable-self-preservation=false \
                --env JAVA_ENV='\'-Xmx128m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/eureka:'$version'
        else
        echo "更新eureka2服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/eureka:'$version' \
        --force \
        eureka2
fi' >> /usr/local/docker-service-file/eureka.sh
else
        echo "注册中心服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/activiti.sh" ]; then
echo "工作流服务不存在需创建"
cd /usr/local/docker-service-file/
touch activiti.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/activiti.sh
echo 'count=`docker service ls|grep activiti|wc -l`
if [ 0 == $count ];then
        echo "创建activiti服务"
        sudo docker service create --with-registry-auth \
        --publish published=10027,target=10027,mode=host \
        --name activiti   \
        --replicas 1  \
        --network app_net \
        --env server_port=10027 \
        --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
        --env spring_cloud_config_profile='$project_name' \
        --env spring_cloud_config_label=master \
        --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
        --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
        --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
        --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
        registry.cn-shenzhen.aliyuncs.com/pro-external/activiti:'$version'
        else
        echo "更新activiti服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/activiti:'$version' \
        --force \
        activiti
fi' >> /usr/local/docker-service-file/activiti.sh
else
        echo "工作流服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/bigscreen.sh" ]; then
echo "大屏服务不存在需创建"
cd /usr/local/docker-service-file/
touch bigscreen.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/bigscreen.sh
echo 'count=`docker service ls|grep bigscreenservice|wc -l`
if [ 0 == $count ];then
        echo "创建bigscreen服务"
        sudo docker service create --with-registry-auth  \
                --publish published=10031,target=10031,mode=host \
                --name bigscreenservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10031 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx512m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/bigscreen:'$version'
        else
        echo "更新bigscreen服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/bigscreen:'$version' \
        --force \
        bigscreenservice
fi' >> /usr/local/docker-service-file/bigscreen.sh
else
        echo "大屏服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/common.sh" ]; then
echo "公共服务不存在需创建"
cd /usr/local/docker-service-file/
touch common.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/common.sh
echo 'count=`docker service ls|grep commonservice|wc -l`
if [ 0 == $count ];then
        echo "创建common服务"
        sudo docker service create  --with-registry-auth \
        --publish published=10022,target=10022,mode=host \
        --name commonservice   \
        --replicas 1  \
        --network app_net \
        --env server_port=10022 \
        --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
        --env spring_cloud_config_profile='$project_name' \
        --env spring_cloud_config_label=master \
        --env wx_mch_spbill_create_ip=47.106.173.202 \
        --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
        --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
        --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
        --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
        --mount type=bind,source=/var/eoscerts,destination=/var/eoscerts \
        --mount type=bind,source=/var/eoscerts/jssecacerts,destination=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/jssecacerts \
        registry.cn-shenzhen.aliyuncs.com/pro-external/common:'$version'
else
        echo "更新common服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/common:'$version' \
        --force \
        commonservice
fi' >> /usr/local/docker-service-file/common.sh
else
        echo "公共服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/company.sh" ]; then
echo "公司服务不存在需创建"
cd /usr/local/docker-service-file/
touch company.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/company.sh
echo 'count=`docker service ls|grep -w companyservice|wc -l`
if [ 0 == $count ];then
        echo "创建company服务"
        sudo docker service create --with-registry-auth \
                --publish published=10008,target=10008,mode=host \
                --name companyservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10008 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                --mount type=bind,source=/var/eoscerts,destination=/var/eoscerts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/company:'$version'
        else
        echo "更新company服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/company:'$version' \
        --force \
        companyservice
fi' >> /usr/local/docker-service-file/company.sh
else
        echo "公司服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/coordinatecompany.sh" ]; then
echo "协同公司服务不存在需创建"
cd /usr/local/docker-service-file/
touch coordinatecompany.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/coordinatecompany.sh
echo 'count=`docker service ls|grep coordinatecompanyservice|wc -l`
if [ 0 == $count ];then
        echo "创建coordinatecompany服务"
        sudo docker service create --with-registry-auth \
                --publish published=10009,target=10009,mode=host \
                --name coordinatecompanyservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10009 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/coordinatecompany:'$version'
        else
        echo "更新coordinatecompany服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/coordinatecompany:'$version' \
        --force \
        coordinatecompanyservice
fi' >> /usr/local/docker-service-file/coordinatecompany.sh
else
        echo "协同公司服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/dictionary.sh" ]; then
echo "字典服务不存在需创建"
cd /usr/local/docker-service-file/
touch dictionary.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/dictionary.sh
echo 'count=`docker service ls|grep dictionaryservice|wc -l`
if [ 0 == $count ];then
        echo "创建dictionary服务"
        sudo docker service create --with-registry-auth \
                --publish published=10007,target=10007,mode=host \
                --name dictionaryservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10007 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/dictionary:'$version'
        else
        echo "更新dictionary服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/dictionary:'$version' \
        --force \
        dictionaryservice
fi' >> /usr/local/docker-service-file/dictionary.sh
else
        echo "字典公司服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/file.sh" ]; then
echo "文件服务不存在需创建"
cd /usr/local/docker-service-file/
touch file.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/file.sh
echo 'count=`docker service ls|grep fileservice|wc -l`
if [ 0 == $count ];then
        echo "创建file服务"
        sudo docker service create --with-registry-auth \
                --publish published=10011,target=10011,mode=host \
                --name fileservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10011 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/file:'$version'
        else
        echo "更新file服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/file:'$version' \
        --force \
        fileservice
fi' >> /usr/local/docker-service-file/file.sh
else
        echo "文件公司服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/gateway.sh" ]; then
echo "网关服务不存在需创建"
cd /usr/local/docker-service-file/
touch gateway.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/gateway.sh
echo 'count=`docker service ls|grep gatewayservice|wc -l`
if [ 0 == $count ];then
        echo "创建gateway服务"
        sudo docker service create --with-registry-auth \
                --publish published=10000,target=10000,mode=host \
                --name gatewayservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10000 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/gateway:'$version'
        else
        echo "更新gateway服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/gateway:'$version' \
        --force \
        gatewayservice
fi' >> /usr/local/docker-service-file/gateway.sh
else
        echo "网关服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/id.sh" ]; then
echo "id服务不存在需创建"
cd /usr/local/docker-service-file/
touch id.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/id.sh
echo 'count=`docker service ls|grep idservice|wc -l`
if [ 0 == $count ];then
        echo "创建id服务"
        sudo docker service create --with-registry-auth \
                --publish published=10004,target=10004,mode=host \
                --name idservice --with-registry-auth \
                --replicas 1  \
                --network app_net \
                --env server_port=10004 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx128m -Djava.security.egd=file:/dev/./urandom\'' \
                --env worker.id=1 \
                --env worker.datacenterId=0 \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/id:'$version'
        else
        echo "更新id服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/id:'$version' \
        --force \
        idservice
fi' >> /usr/local/docker-service-file/id.sh
else
        echo "id服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/ireport.sh" ]; then
echo "报表服务不存在需创建"
cd /usr/local/docker-service-file/
touch ireport.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/ireport.sh
echo 'count=`docker service ls|grep ireportservice|wc -l`
if [ 0 == $count ];then
        echo "创建ireport服务"
        sudo docker service create --with-registry-auth \
                --publish published=10032,target=10032,mode=host \
                --name ireportservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10032 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/ireport:'$version'
        else
        echo "更新ireport服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/ireport:'$version' \
        --force \
        ireportservice
fi' >> /usr/local/docker-service-file/ireport.sh
else
        echo "报表服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/menuoperaterole.sh" ]; then
echo "菜单服务不存在需创建"
cd /usr/local/docker-service-file/
touch menuoperaterole.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/menuoperaterole.sh
echo 'count=`docker service ls|grep ireportservice|wc -l`
count=`docker service ls|grep menuoperateroleservice|wc -l`
if [ 0 == $count ];then
        echo "创建menuoperaterole服务"
        sudo docker service create --with-registry-auth \
                --publish published=10005,target=10005,mode=host \
                --name menuoperateroleservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10005 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/menuoperaterole:'$version'
        else
        echo "更新menuoperaterole服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/menuoperaterole:'$version' \
        --force \
        menuoperateroleservice
fi' >> /usr/local/docker-service-file/menuoperaterole.sh
else
        echo "菜单服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/project.sh" ]; then
echo "项目服务不存在需创建"
cd /usr/local/docker-service-file/
touch project.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/project.sh
echo 'count=`docker service ls|grep projectservice|wc -l`
if [ 0 == $count ];then
        echo "创建project服务"
        sudo docker service create --with-registry-auth \
                --publish published=10010,target=10010,mode=host \
                --name projectservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10010 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/project:'$version'
        else
        echo "更新project服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/project:'$version' \
        --force \
        projectservice
fi' >> /usr/local/docker-service-file/project.sh
else
        echo "项目服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/quartz.sh" ]; then
echo "定时器服务不存在需创建"
cd /usr/local/docker-service-file/
touch quartz.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/quartz.sh
echo 'count=`docker service ls|grep quartz|wc -l`
if [ 0 == $count ];then
        echo "创建quartz服务"
        sudo docker service create --with-registry-auth  \
                --publish published=10015,target=10015,mode=host \
                --name quartz   \
                --replicas 1  \
                --network app_net \
                --env server_port=10015 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/quartz:'$version'
        else
        echo "更新quartz服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/quartz:'$version' \
        --force \
        quartz
fi' >> /usr/local/docker-service-file/quartz.sh
else
        echo "定时器服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/sign.sh" ]; then
echo "签章服务不存在需创建"
cd /usr/local/docker-service-file/
touch sign.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/sign.sh
echo 'count=`docker service ls|grep signservice|wc -l`
if [ 0 == $count ];then
        echo "创建sign服务"
        sudo docker service create --with-registry-auth \
                --publish published=10025,target=10025,mode=host \
                --name signservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10025 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/sign:'$version'
        else
        echo "更新sign服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/sign:'$version' \
        --force \
        signservice
fi' >> /usr/local/docker-service-file/sign.sh
else
        echo "签章服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/team.sh" ]; then
echo "小组服务不存在需创建"
cd /usr/local/docker-service-file/
touch team.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/team.sh
echo 'count=`docker service ls|grep teamservice|wc -l`
if [ 0 == $count ];then
        echo "创建team服务"
        sudo docker service create --with-registry-auth \
                --publish published=10020,target=10020,mode=host \
                --name teamservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10020 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/team:'$version'
        else
        echo "更新team服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/team:'$version' \
        --force \
        teamservice
fi' >> /usr/local/docker-service-file/team.sh
else
        echo "小组服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/user.sh" ]; then
echo "用户服务不存在需创建"
cd /usr/local/docker-service-file/
touch user.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/user.sh
echo 'count=`docker service ls|grep -w userservice|wc -l`
if [ 0 == $count ];then
        echo "创建user服务"
        sudo docker service create --with-registry-auth \
                --publish published=10006,target=10006,mode=host \
                --name userservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10006 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx256m -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/user:'$version'
        else
        echo "更新user服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/user:'$version' \
        --force \
        userservice
fi' >> /usr/local/docker-service-file/user.sh
else
        echo "用户服务脚本已存在"
fi

if [ ! -f "/usr/local/docker-service-file/workcircle.sh" ]; then
echo "动态服务不存在需创建"
cd /usr/local/docker-service-file/
touch workcircle.sh
echo '#!/bin/bash' > /usr/local/docker-service-file/workcircle.sh
echo 'count=`docker service ls|grep workcircleservice|wc -l`
if [ 0 == $count ];then
        echo "创建workcircle服务"
        sudo docker service create --with-registry-auth \
                --publish published=10016,target=10016,mode=host \
                --name workcircleservice   \
                --replicas 1  \
                --network app_net \
                --env server_port=10016 \
                --env eureka_client_service-url_defaultZone=http://eureka1:10001/eureka/,http://eureka2:10002/eureka/  \
                --env spring_cloud_config_profile='$project_name' \
                --env spring_cloud_config_label=master \
                --env JAVA_ENV='\'-Xmx1G -Djava.security.egd=file:/dev/./urandom\'' \
                --mount type=bind,source=/etc/localtime,destination=/etc/localtime  \
                --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
                --mount type=bind,source=/usr/share/fonts,destination=/usr/share/fonts \
                registry.cn-shenzhen.aliyuncs.com/pro-external/workcircle:'$version'
        else
        echo "更新workcircle服务"
        sudo docker service update --with-registry-auth \
        --image registry.cn-shenzhen.aliyuncs.com/pro-external/workcircle:'$version' \
        --force \
        workcircleservice
fi' >> /usr/local/docker-service-file/workcircle.sh
else
        echo "动态服务脚本已存在"
fi

/usr/bin/chmod a+x /usr/local/docker-service-file/*.sh

if [ ! -d "/usr/local/docker-service-file/config" ]; then
echo "config文件夹不存在需创建"
unzip config.zip -d /usr/local/docker-service-file
else
echo "config文件夹已创建"
fi

docker network create --driver overlay app_net

if [ ! -f "/etc/localtime" ]; then
echo "redis服务不存在需创建"
cp /opt/localtime /etc
else
echo "localtime文件已存在"
fi

if [ ! -f "/etc/timezone" ]; then
echo "redis服务不存在需创建"
cp /opt/timezone /etc
else
echo "timezone文件已存在"
fi

if [ ! -d "/var/eoscerts" ]; then
echo "eoscerts文件夹不存在需创建"
unzip eoscerts.zip -d /var
else
echo "eoscerts文件夹已创建"
fi

