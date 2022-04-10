from azul/zulu-openjdk-centos:11
label org.opencontainers.image.authors="zhangyongxiang@baidu.com"
env TZ Asia/Shanghai
run localedef -c -i zh_CN -f UTF-8 zh_CN.UTF-8
env LC_ALL zh_CN.utf8
env LANG zh_CN.UTF-8
env LANGUAGE zh_CN:zh
run echo 'LANG=zh_CN.UTF-8' > /etc/locale.conf
run echo 'Asia/Shanghai' > /etc/timezone
run ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cmd ["java", "-version"]