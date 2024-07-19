FROM --platform=linux/amd64 alpine:3.20
LABEL org.opencontainers.image.authors="zhangyongxiang@baidu.com"
RUN apk update --no-cache && apk add --no-cache bash tzdata inetutils-telnet tini curl
ENV TZ Asia/Shanghai
RUN echo 'Asia/Shanghai' > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENTRYPOINT ["tini", "-v", "-g", "--"]

# docker build --platform=linux/amd64 -t iregistry.baidu-int.com/comate/alpine:3.20 .