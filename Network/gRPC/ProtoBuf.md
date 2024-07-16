Protocol Buffers are a language-neutral, platform-neutral extensible mechanism for serializing structured data.
# Programming Guides
## Language Guide(proto 3)
### Defining Services
通过远程调用系统使用你的消息类型，需要定义RPC服务接口。ProtoBuf编译器会生成接口代码与stubs。比如下面的例子:
```proto
service SearchService {
  rpc Search(SearchRequest) returns (SearchResponse);
}
```
实现ProtoBuf的RPC系统就是gRPC，语言无关的，平台无关的开源RPC系统。与ProtoBuf协同工作。让你可以直接通过.proto文件生成RPC代码。当让也有一些第三方的支持ProtoBuf的实现。