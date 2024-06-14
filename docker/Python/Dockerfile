# docker pull --platform=linux/arm64/v8 ubuntu:jammy
FROM --platform=linux/arm64/v8 ubuntu:jammy
LABEL org.opencontainers.image.authors="zhangyongxiang@baidu.com"
ENV TZ Asia/Shanghai
RUN apt update && apt install -y language-pack-zh-hans python3 python3-pip wget unzip && apt clean
ENV LC_ALL zh_CN.utf-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
RUN echo 'Asia/Shanghai' > /etc/timezone
COPY Shanghai /usr/share/zoneinfo/Asia/Shanghai
RUN ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 设置环境变量
ENV MODEL_ROOT_PATH /home/work/server
# 创建目录及设置权限
RUN mkdir -p /home/work/log
# RUN apt-get install -y libpython3.9-dev
# RUN pip install -i http://pip.baidu.com/root/baidu/+simple/ --trusted-host=pip.baidu.com --upgrade pip
RUN pip install -i http://pip.baidu.com/root/baidu/+simple/ --trusted-host=pip.baidu.com -U FlagEmbedding
RUN pip install -i http://pip.baidu.com/root/baidu/+simple/ --trusted-host=pip.baidu.com -U optimum
RUN pip install -i http://pip.baidu.com/root/baidu/+simple/ --trusted-host=pip.baidu.com -U onnx
WORKDIR /home/work/
# 下载安全加固后的embedding
RUN wget -O /home/work/jinaembedding.zip https://baidu-ide.bj.bcebos.com/bugbye/embedding-jina-poc/jinaembedding.zip --no-check-certificate
RUN unzip /home/work/jinaembedding.zip
#运行
WORKDIR /home/work/server/bge_embedding
ENTRYPOINT ["sh", "-c", "/home/work/new_secpy/arm64/pyenc /home/work/server/bge_embedding/jina_main.pyxes"]
# docker build --platform=linux/arm64 -t iregistry.baidu-int.com/comate/jina-embedding:arm64-20240614 .