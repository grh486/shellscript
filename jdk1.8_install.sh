#!/bin/bash
jdk=jdk-8u231-linux-x64.tar.gz
if [ -f "/opt/$jdk" ];then
cd /opt
tar -zxvf $jdk
else 
echo "jdk压缩包不存在"
fi
mv /opt/jdk1.8.0_231 /usr/local
echo "export JAVA_HOME=/usr/local/jdk1.8.0_231" >> /etc/profile
echo "export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH:\$HOMR/bin" >> /etc/profile
source /etc/profile
java -version
