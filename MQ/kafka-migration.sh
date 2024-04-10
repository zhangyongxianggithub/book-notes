#!/bin/bash
declare kafka_home
if [[ -d ${KAFKA_HOME} ]];then
   echo "kafka home dir: ${KAKFA_HOME}"
   kafka_home=${KAFKA_HOME}
else
   echo -e "输入kafka home路径: "
   read kafka_home
fi
if [[ ! -d ${kafka_home} ]];then
   echo "kafka home不存在"
fi
echo -e "输入源bootstrap-server(server:port[,server:port]): "
read source_bootrstrap_server
# source_bootrstrap_server=szth-inf-bce0979b86a.szth.baidu.com:8093
echo -e "输入源ssl properties文件地址: "
read ssl_config_path
# source_ssl_config_path=/Users/zhangyongxiang/Documents/book-notes/kafka/source.properties
echo -e "输入目的bootstrap-server(server:port[,server:port]): "
read target_bootrstrap_server
# target_bootrstrap_server=10.68.114.166:8183,10.68.115.13:8182,10.168.115.13:8184
echo -e "输入目的ssl properties文件地址: "
read target_ssl_config_path
# target_ssl_config_path=/Users/zhangyongxiang/Documents/book-notes/kafka/source.properties
topics=$(${kafka_home}/bin/kafka-topics.sh --list \
       --bootstrap-server ${source_bootrstrap_server} \
       --command-config ${source_ssl_config_path})
echo ${topics}
declare -i topic_count=0
for topic in ${topics}
do
    topic_detail=$(${kafka_home}/bin/kafka-topics.sh \
      --describe --topic ${topic} \
      --bootstrap-server ${source_bootrstrap_server} \
      --command-config ${source_ssl_config_path})
    partition_count=$(echo ${topic_detail} | awk '{print $4}')
    replication_factor=$(echo ${topic_detail} | awk '{print $6}')
    echo "source topic detail: ${topic}, ${partition_count}, ${replication_factor}"
    result=$(${kafka_home}/bin/kafka-topics.sh \
      --create --topic ${topic} \
      --partitions ${partition_count} --replication-factor ${replication_factor} \
      --bootstrap-server ${target_bootrstrap_server} \
      --command-config ${target_ssl_config_path})
    echo "topic: ${topic}, result: ${result}"
    topic_count=topic_count+1
done
echo "total migratied topic count: ${topic_count}"
