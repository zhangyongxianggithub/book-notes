# docker pull --platform=linux/arm64/v8 ubuntu:jammy
ARG ARCH=arm64/v8
FROM --platform=linux/${ARCH} ubuntu:jammy
LABEL org.opencontainers.image.authors="zhangyongxiang@baidu.com"
ENV TZ Asia/Shanghai
RUN apt update && apt install -y language-pack-zh-hans python3 python3-pip wget unzip tini curl && apt clean
ENV LC_ALL zh_CN.utf-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
RUN echo 'Asia/Shanghai' > /etc/timezone
COPY Shanghai /usr/share/zoneinfo/Asia/Shanghai
RUN ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENTRYPOINT ["tini", "-v", "-g", "--"]
# docker build --platform=linux/arm64/v8 -t zyxrepo/python:3.9.6 -f Dockerfile . 