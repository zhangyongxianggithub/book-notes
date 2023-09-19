FROM --platform=linux/amd64 eclipse-temurin:17-jre-centos7
LABEL org.opencontainers.image.authors="zhangyongxiang@baidu.com"
ENV TZ Asia/Shanghai
RUN localedef -c -i zh_CN -f UTF-8 zh_CN.UTF-8
ENV LC_ALL zh_CN.utf8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
RUN echo 'LANG=zh_CN.UTF-8' > /etc/locale.conf
RUN echo 'Asia/Shanghai' > /etc/timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY tini /usr/bin/
RUN chmod a+x /usr/bin/tini
CMD ["java", "-version"]
ENTRYPOINT ["tini", "-v", "-g", "--"]