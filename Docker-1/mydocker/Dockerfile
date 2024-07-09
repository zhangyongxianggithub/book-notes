from busybox
label org.opencontainers.image.authors="zhangyongxiang@baidu.com"
workdir /testdir
run touch tmpfile1
copy ["tmpfile2", "."]
add ["bunch.tar.gz","."]
env welcome "you are in my container, welcome"
