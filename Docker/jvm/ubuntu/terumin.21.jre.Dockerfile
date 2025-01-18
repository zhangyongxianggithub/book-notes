from eclipse-temurin:21-jre
label org.opencontainers.image.authors="zhangyongxiang"
env TZ=Asia/Shanghai
run apt update && apt install -y language-pack-zh-hans inetutils-ping telnet tini && apt clean
env LC_ALL=zh_CN.utf-8
env LANG=zh_CN.UTF-8
env LANGUAGE=zh_CN:zh
run echo 'Asia/Shanghai' > /etc/timezone
run unlink /etc/localtime
copy context/Shanghai /usr/share/zoneinfo/Asia/Shanghai
run ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cmd ["java", "-version"]
entrypoint ["tini", "-v", "-g", "--"]