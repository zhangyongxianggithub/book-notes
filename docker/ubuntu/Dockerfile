from zyxrepo/ubuntu:22.04
label org.opencontainers.image.authors="zhangyongxiang@baidu.com"
env TZ Asia/Shanghai
run apt update && apt install -y language-pack-zh-hans
env LC_ALL zh_CN.utf8
env LANG zh_CN.UTF-8
env LANGUAGE zh_CN:zh
run echo 'Asia/Shanghai' > /etc/timezone
copy Shanghai /usr/share/zoneinfo/Asia/Shanghai
run ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
run apt update && apt install -y tini
cmd ["bash"]
entrypoint ["tini", "-v", "-g", "--"]