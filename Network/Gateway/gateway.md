|Gateway|Description|
|:---|:---|
|Caddy||
|Nginx||
|OpenResty||
|Kong||
|ApiSix||
|Shenyu||
|Spring Cloud Gateway||
|Netflix Zuul||
|SafeLine||
|tyk||
|lura||
|gloo||
|emissary||
|manba||
|janus||
|higress|以istio+envoy为核心构建的云原生网关，流量网关+微服务网关+安全网关3合1集成，降低网关的部署与运维成本。支持Ingress与标准API规范|
|orange||
# Higress
![higress网关架构](./pic/higress-architecture.avif)
- 流量网关: 全局性的与后端业务无关的策略配置
- 业务网关: 提供独立业务域级别的与后端业务紧耦合策略配置，微服务网关就是业务网关的一种
![网关分类](./pic/gateway-class.avif)
Higress的功能聚合
![Higress的聚合功能](./pic/gateway-func.avif)
