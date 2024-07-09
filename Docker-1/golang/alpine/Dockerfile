from --platform=linux/amd64 jeanblanchard/alpine-glibc:3.19
label org.opencontainers.image.authors="zhangyongxiang@baidu.com"
run apk update --no-cache && apk add --no-cache bash tzdata inetutils-telnet tini build-base
env TZ Asia/Shanghai
run echo 'Asia/Shanghai' > /etc/timezone
run ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
entrypoint ["tini", "-v", "-g", "--"]
cmd [ "echo", "this is a base image for golang executable file" ]