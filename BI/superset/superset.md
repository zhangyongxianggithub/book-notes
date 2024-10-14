# overview
Superset是一个现代的、面向企业BI的web应用，快速、轻量、简单，任何人都可以方便的用它来探索与虚拟化数据，可以生成从简单饼状图到复杂的地理空间图等
features:
- Superset提供了虚拟化数据集与制作交互式仪表板的简单图形接口
- 大量的可视化视图来展示你的数据
- 不需要写代码就可以生成数据的可视化视图
- 世界级的SQL IDE可以为数据的可视化提供SQL数据
- 一个轻量化的语义层来帮助做数据分析
- 支持标准SQL
- 无缝的内存异步缓存和查询
- 可扩展的安全模型，允许配置非常复杂的规则，规定谁可以访问哪些产品功能和数据集
- 与主要身份验证后端集成（数据库、OpenID、LDAP、OAuth、REMOTE_USER 等）
- 添加自定义可视化插件的能力
- 用于编程定制的API
- 为扩展而从头开始设计的云原生架构
# get started
1. 拉取镜像
    ```shell
    docker pull --platform=linux/amd64  apache/superset:master
    ```
2. 部署superset
    ```shell
    docker run --platform=linux/amd64 -d -p 8080:8088 \
        -e SUPERSET_SECRET_KEY=123456 \
        -e TALISMAN_ENABLED=False \
        --name superset apache/superset:master
    ```
3. 创建用户
    ```shell
    docker exec -it superset superset fab create-admin \
                --username admin \
                --firstname Admin \
                --lastname Admin \
                --email admin@localhost \
                --password admin
    ```
4. 初始化
    ```shell
    docker exec -it superset superset db upgrade &&
            docker exec -it superset superset load_examples &&
            docker exec -it superset superset init
    ```
5. 连接一个数据库
6. 创建dataset
7. 修改数据集，定义列的一些属性
8. 基于数据集创建一个chart
9. 创建dashboard，把chart添加到dashboard
10. 停止服务
    ```shell
    docker container rm -f superset
    ```