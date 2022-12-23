FROM apache/flink:1.13.1-scala_2.12-java8
ENV TZ Asia/Shanghai
COPY flink-shaded-hadoop-2-uber-2.8.3-10.0.jar /opt/flink/lib
COPY flink-s3-fs-presto-1.13.1.jar /opt/flink/plugins/s3-fs-presto/
# docker build -t  iregistry.baidu-int.com/acg-iidp/flink:1.13.1-scala_2.12-java8 .
