# 开源的方案
- incubator-kie-drools
- easy-rules
- liteflow
- radar
- rulebook
- QLExpress
- ice
- RuleEngine
- jetlinks/rule-engine
- evrete/evrete
# liteflow
轻量请打的规则引擎框架，用于复杂的组件化业务的编排，使用DSL规则驱动整个复杂业务，实现平滑刷新热部署，支持多种脚本语言的嵌入。特点
- 强大的EL: 简单低学习成本的EL，丰富的关键字，完成任意模式的逻辑编排
- 皆为组件: 独特的设计理念，所有逻辑皆为组件，上下文隔离，组件单一指责，组件可以复用并互相解耦
- 脚本支持: 可以使用7种脚本语言写逻辑Java、Groovy、Js、Python、Lua、QLExpress、Aviator
- 规则存储: 支持把规则和脚本存储在任何关系型数据库，支持大部分的注册中心zk、nacos、etcd、appolo、redis
- 平滑热刷: 编排规则、脚本组件，不需要重启应用即时刷新，实时替换逻辑
- 支持度广: JDK8~JDK17,Spring 2.x ~ Spring 3.x
- 高级特性: 很多
# QLExpress

# RuleEngine
非常简单的规则引擎，容易使用，可以用多种方式来表示规则，xml、drools、database等。添加依赖
```xml
    <dependency>
        <groupId>com.github.hale-lee</groupId>
        <artifactId>RuleEngine</artifactId>
        <version>0.2.0</version>
    </dependency>
```

