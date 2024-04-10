FROM iregistry.baidu-int.com/acg-iidp/flink:1.13.1-scala_2.12-java8
RUN rm -rf /opt/flink/lib/log4j-api-2.12.1.jar
RUN rm -rf /opt/flink/lib/log4j-slf4j-impl-2.12.1.jar
RUN rm -rf /opt/flink/lib/log4j-core-2.12.1.jar
RUN rm -rf /opt/flink/lib/log4j-1.2-api-2.12.1.jar
COPY log4j-api-2.16.0.jar /opt/flink/lib
COPY log4j-1.2-api-2.16.0.jar /opt/flink/lib
COPY log4j-core-2.16.0.jar /opt/flink/lib
COPY log4j-slf4j-impl-2.16.0.jar /opt/flink/lib
# docker build -t  iregistry.baidu-int.com/acg-iidp/flink:1.13.1-scala_2.12-java8-log4j_2.16 .
