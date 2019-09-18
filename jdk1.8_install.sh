#!/bin/bash
jdk=jdk-8u144-linux-x64.tar.gz
if [ -f "/data/$jdk" ];then
cd /data
tar -zxvf $jdk
else 
echo "jdk压缩包不存在"
fi
mv /data/jdk1.8.0_144 /usr/local
echo "export JAVA_HOME=/usr/local/jdk1.8.0_144" >> /etc/profile
echo "export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH:\$HOMR/bin" >> /etc/profile
source /etc/profile
java -version
