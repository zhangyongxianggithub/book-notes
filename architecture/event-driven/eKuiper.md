ekuiper，超轻量物联网的边缘数据分析软件。它是一款可以运行在各类资源受限硬件上的轻量级物联网边缘分析、流式处理开源软件。ekuiper的一个主要目标在边缘端提供一个实时流式计算框架，与Flink类似，eKuiper的规则引擎允许用户使用基于SQL方式，或者Graph方式的规则，快速创建边缘端的分析应用。
```shell
docker run -p 9082:9082 -d --name ekuiper-manager -e DEFAULT_EKUIPER_ENDPOINT="http://172.25.104.177:9081" emqx/ekuiper-manager:latest
```
```shell
docker run -p 9081:9081 -d --name kuiper -e MQTT_SOURCE__DEFAULT__SERVER="tcp://broker.emqx.io:1883" lfedge/ekuiper:1.8-alpine
```