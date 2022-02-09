# 第一章 Spring Security架构概览
Spring Security方便集成在Spring Boot于Spring Cloud项目中。
## Spring Security简介
java安全管理的实现方案
- Shiro
- Spring Security
- 开发者自己实现
Spring Security最早叫做Acegi Security，是基于Spring的一种框架，后来改名了叫Spring Security，一直是配置繁琐；但是Spring Boot的出现解决了这个问题，因为可以提供自动化的配置。
## Spring Security核型功能
- 认证（你是谁）
- 授权（你可以做什么）
支持的认证方式：
- 表单认证
- OAuth2.0认证
- SAML2.0认证
- CAS认证
- RememberMe自动认证
- JAAS认证
- OpenID去中心化认证
- Pre-Authentication Scenarios认证
- X509认证
- HTTP Basic认证
- HTTP Digest认证
也可以引入第三方的支持或者自定义认证逻辑。
Spring Security支持URL请求授权、方法访问授权、SpEL访问控制、域对象安全、动态权限配置、RBAC模型等。
## Spring Security整体架构
