from azul/zulu-openjdk:8u322
env TZ Asia/Shanghai
env LC_ALL C.UTF-8
env LANG zh_CN.UTF-8
env LANGUAGE zh_CN.UTF-8
run echo 'Asia/Shanghai' > /etc/timezone
run unlink /etc/localtime
copy Shanghai /usr/share/zoneinfo/Asia/Shanghai
run ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


