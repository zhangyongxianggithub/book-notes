# 本地模式安装
1. [下载](https://flink.apache.org/zh/downloads.html)flink包，是基于Java 11的；
2. > ./bin/start-cluster.sh 启动集群;
3. > ./bin/flink run examples/streaming/WordCount.jar 提交作业;
4. > tail log/flink-*-taskexecutor-*.out 查看日志
5. > ./bin/stop-cluster.sh 停止集群
# 基于DataStream API实现欺诈检测

# 基于TableAPI实现实时报表
# Flink操作场景