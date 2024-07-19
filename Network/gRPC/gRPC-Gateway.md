gRPC-Gateway是一个protoc的插件，读取gRPC服务定义来生成一个反向代理服务，反向代理服务把RESTful JSON API调用转换为GRPC调用，服务的生成要依据你的gRPC定义中的一些自定义选项。
![gRPC-Gateway架构](./pic/architecture_introduction_diagram.svg)
gRPC无疑是高效的，但是有时候可能也需要提供RESTful API，可能是为了向后兼容或者是为了与哪些gRPC不支持的语言使用。这个项目就是为你的gRPC服务提供HTTP+JSON的接口，只需要很少的配置就可以生成一个反向代理。
# Installation
```shell
$ go install \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest \
    github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest \
    google.golang.org/protobuf/cmd/protoc-gen-go@latest \
    google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```
# Usage
## Default
不需要修改pb文件，使用默认的HTTP设置，最简单
## 自定义映射
在pb文件中添加`google.api.http`注解。
```protobuf
 syntax = "proto3";
 package your.service.v1;
 option go_package = "github.com/yourorg/yourprotos/gen/go/your/service/v1";
+
+import "google/api/annotations.proto";
+
 message StringMessage {
   string value = 1;
 }

 service YourService {
-  rpc Echo(StringMessage) returns (StringMessage) {}
+  rpc Echo(StringMessage) returns (StringMessage) {
+    option (google.api.http) = {
+      post: "/v1/example/echo"
+      body: "*"
+    };
+  }
 }
```
你需要提供需要的第三方protobuf文件给protoc编译器，如果你正在使用buf，需要将依赖添加到`buf.yaml`文件中的deps元素中
```yaml
version: v1
name: buf.build/yourorg/myprotos
deps:
  - buf.build/googleapis/googleapis
```
最后`buf.gen.yaml`文件中的内容如下:
```yaml
version: v1
plugins:
  - plugin: go
    out: gen/go
    opt:
      - paths=source_relative
  - plugin: go-grpc
    out: gen/go
    opt:
      - paths=source_relative
  - plugin: grpc-gateway
    out: gen/go
    opt:
      - paths=source_relative
```
如果使用的是protoc命令，你需要保证编译器可以访问到依赖，需要下载到的proto文件如下
```
google/api/annotations.proto
google/api/field_behavior.proto
google/api/http.proto
google/api/httpbody.proto
```
protoc命令如下:
```shell
protoc -I . --grpc-gateway_out ./gen/go \
    --grpc-gateway_opt paths=source_relative \
    your/service/v1/your_service.proto
```

## 使用额外的配置文件
当不能修改pb文件的时候使用。最好与`standalone=true`选项一起使用来生成文件到独立的包下，与源pb文件生成的文件分开。
buf命令使用的`buf.gen.yaml`文件的实例
```yaml
version: v1
plugins:
  - plugin: go
    out: gen/go
    opt:
      - paths=source_relative
  - plugin: go-grpc
    out: gen/go
    opt:
      - paths=source_relative
  - plugin: grpc-gateway
    out: gen/go
    opt:
      - paths=source_relative
      - grpc_api_configuration=path/to/config.yaml
      - standalone=true
```
使用protoc的的命令
```shell
protoc -I . --grpc-gateway_out ./gen/go \
    --grpc-gateway_opt paths=source_relative \
    --grpc-gateway_opt grpc_api_configuration=path/to/config.yaml \
    --grpc-gateway_opt standalone=true \
    your/service/v1/your_service.proto
```
# Mapping
## gRPC API Configuration
在某些场景下不能注解pb文件或者你想要用不通的方式暴露一个gRPC接口多次。Gateway提供了2种方式来实现
- `generate_unbound_methods`: 为所有方法产生HTTP映射
  - HTTP方法是POTST
  - URI path来自于接口名于方法名`/<fully qualified service name>/<method name>`(`/my.package.EchoService/Echo`)
  - http body是序列化的消息体
- 使用外部配置文件: 