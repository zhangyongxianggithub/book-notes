# What is gRPC
## Introduction
gRPC使用ProtoBuf作为IDL(Interface Definition Language)与底层的消息交换格式。在gRPC中，客户端应用程序可以像调用本地对象一样直接调用另一台机器上的服务器应用程序的方法，从而简化了分布式应用程序和服务的创建过程。与许多RPC系统一样，gRPC的核心思想是定义服务，并指定可以远程调用的方法及其参数和返回值类型。在服务器端，服务器实现此接口并运行一个gRPC服务器来处理客户端调用。在客户端，客户端拥有一个存根（某些语言中称为客户端），它提供与服务器相同的方法。
![gRPC核心思想](./pic/grpc.svg)
gRPC 客户端和服务器可以在各种环境中运行并相互通信 - 从谷歌内部的服务器到您自己的桌面电脑，并且可以用任何gRPC支持的语言编写。例如，您可以轻松地使用Java创建一个gRPC服务器，并使用Go、Python或Ruby编写的客户端与其通信。此外，最新的谷歌API将提供gRPC版本的接口，让您轻松地将谷歌的功能集成到您的应用程序中。默认情况下，gRPC使用 Protocol Buffers，谷歌成熟的开源结构化数据序列化机制（当然它也可以使用其他数据格式，例如JSON）。下面将简要介绍其工作原理。使用Protocol Buffers的第一步是在`.proto`文件中定义要序列化的数据的结构：这只是一个带有 `.proto`扩展名的普通文本文件。Protocol Buffers数据以消息的形式进行组织，其中每个消息都是一个小型的逻辑信息记录，包含一系列称为字段的名称-值对。这里有一个简单的例子：
```proto
message Person {
  string name = 1;
  int32 id = 2;
  bool has_ponycopter = 3;
}
```
一旦指定了数据结构，你可以使用protoc编译器来生成指定的数据访问类，提供了简单的getter与setter方法，还有序列化与反序列化的方法。在普通的proto文件中定义gRPC服务，使用消息置顶RPC方法的参数与返回类型
```proto
// The greeter service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```
gRPC使用protoc与一个特殊的gRPC插件来从proto文件生成代码，获得生成的gRPC客户端与服务端代码，还会获得用于填充、序列化与反序列化消息的代码。具体如何安装一个带有指定语言的gRPC拆建的protoc，参考[protocol buffers文档](https://protobuf.dev/overview)。
## Core Concepts
### Overview
#### Service definition
与很多RPC系统类似，gRPC就是定义服务、定义可以远程调用的方法，定义方法的参数与返回值，默认情况下，gRPC使用ProtoBuf作为IDL来描述服务接口与消息体，如果需要也可以使用别的替代者。
```proto
service HelloService {
  rpc SayHello (HelloRequest) returns (HelloResponse);
}

message HelloRequest {
  string greeting = 1;
}

message HelloResponse {
  string reply = 1;
}
```
gRPC定义了4种服务方法:
- 一元RPC，单请求单响应就类似普通的函数调用`rpc SayHello(HelloRequest) returns (HelloResponse);`
- 服务端流式RPC，客户端发送请求到服务端，然后获得一个流，从流中读取到返回的连续的消息体，直到没有更多的消息，消息有序`rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse);`
- 客户端流式RPC，客户端使用流发送连续的消息体，发送完毕后等待服务端的响应`rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse);`
- 双向流式RPC，双方可以使用读写流发送一系列消息。这两个流独立运行，因此客户端和服务器可以按照他们喜欢的任何顺序进行读写操作。例如，服务器可以在写入响应之前等待接收所有客户端消息，也可以交替读取一条消息然后写入一条消息，或者其他一些读取和写入的组合。每个流中的消息顺序将被保留。`rpc BidiHello(stream HelloRequest) returns (stream HelloResponse);`

#### Using the API
首先需要在`.proto`文件中定义远程调用接口，gRPC提供了protoc编译器的插件，可以用来生成客户端与服务器端的代码，gRPC用户通常在客户端调用这些API在服务端实现这些API。
- 在服务端: 服务器实现了接口声明的方法，并且运行一个gRPC服务器来操作客户端的调用，gRPC基础设施回解码输入的请求、执行方法、然后编码响应
- 在客户端: 客户端有一个本地对象叫做stub，实现了同样的方法，客户端调用本地对象上的这些方法

#### Synchronous vs Asynchronous
同步RPC调用会一直阻塞到服务器响应到达，这与RPC试图模拟的过程调用抽象非常接近。然而，网络本质上是异步的，在许多情况下，能够在不阻塞当前线程的情况下启动RPC调用会非常有用。gRPC编程API在大多数语言中都提供同步和异步两种形式。有关详细信息，请参阅每种语言的教程和参考文档（完整参考文档即将推出）。
### RPC life cycle
在这一部分，你将近距离观察gRPC客户端调用gRPC服务端方法时发生了什么?
#### Unary RPC
首先考虑最简单的RPC类型，客户端发送一个请求并接收一个请求
- 一旦客户端调用stub的方法，服务端就会被通知RPC被调用，通知包含本地调用的客户端的metadata信息、方法名、指定的deadline
- 服务端要么返回它自己的初始metadata(必须在响应前发送)，要么继续等待客户端的请求，具体哪个取决于服务端如何编写
- 一旦服务端获得了客户端的请求消息体，服务端有必要创建并返回一个响应给客户端，客户端获取的响应还包括状态信息与可选的metadata信息
- 如果状态码OK。客户端获取响应，完成调用
#### Server streaming RPC
服务端流式RPC类似unary RPC，只是服务器返回的是响应流，在发送完所有响应后，回发送状态信息与可选的metadata给客户端，服务端完成处理，客户端接收到所有服务端的消息体后完成处理
#### Client streaming RPC

# Lnaguages
每个支持的语言都具有下面的3个链接
- Quick start
- Tutorials
- API reference
## Go
### Quick start
需要为protoc编译器安装Go的插件
```shell
$ go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
$ go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```
下载示例代码库
```shell
git clone -b v1.65.0 --depth 1 https://github.com/grpc/grpc-go
cd grpc-go/examples/helloworld
```
编译运行服务端代码
```shell
go run greeter_server/main.go
```
编译运行客户端代码
```shell
go run greeter_client/main.go
```
开发一个新的RPC方法
```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```
重新生成gRPC代码
```shell
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    helloworld/helloworld.proto
```
实现新的方法
```go
func (s *server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
        return &pb.HelloReply{Message: "Hello again " + in.GetName()}, nil
}
```
添加客户端调用
```go
r, err = c.SayHelloAgain(ctx, &pb.HelloRequest{Name: *name})
if err != nil {
        log.Fatalf("could not greet: %v", err)
}
log.Printf("Greeting: %s", r.GetMessage())
```
### Basics tutorial
提供了基本的Go编程介绍，关于如何使用gRPC。通过一个例子，你将学会:
- 在`.proto`文件中定义一个接口
- 使用protoc生成服务端与客户端的代码
- 使用Go的gRPC API来编写简单的客户端与服务端

假设你已经了解gRPC与ProtoBuf。我们以一个简单的路线规划应用程序为例，该应用程序允许客户端获取路线要素信息、创建路线摘要以及与服务器和其它客户端交换路线信息（例如交通更新）。通过gRPC，我们可以将服务在单个`.proto`文件中定义一次，然后使用任何gRPC支持的语言生成客户端和服务器代码。这些代码可以在各种环境中运行，从大型数据中心内的服务器到您的平板电脑-gRPC会处理不同语言和环境之间通信的所有复杂性。我们还可以获得使用Protocol Buffers的所有优势，包括高效的序列化、简单的IDL以及轻松的接口更新。获取示例代码
首先下载代码
```shell
git clone -b v1.65.0 --depth 1 https://github.com/grpc/grpc-go
cd grpc-go/examples/route_guide
```
然后定义Service，request、response，定义4种接口方法
- Unary RPC
  ```proto
    // Obtains the feature at a given position.
    rpc GetFeature(Point) returns (Feature) {}
  ```
- 服务端流式RPC
  ```proto
    // Obtains the Features available within the given Rectangle.  Results are
    // streamed rather than returned at once (e.g. in a response message with a
    // repeated field), as the rectangle may cover a large area and contain a
    // huge number of features.
    rpc ListFeatures(Rectangle) returns (stream Feature) {}
  ```
- 客户端流式RPC
  ```proto
    // Accepts a stream of Points on a route being traversed, returning a
    // RouteSummary when traversal is completed.
    rpc RecordRoute(stream Point) returns (RouteSummary) {}
  ```
- 双向流式RPC
  ```proto
    // Accepts a stream of RouteNotes sent while a route is being traversed,
    // while receiving other RouteNotes (e.g. from other users).
    rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
  ```

生成客户端与服务端代码
```shell
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    routeguide/route_guide.proto
```
生成2类文件
- *.pb.go: 包含消息体代码
- *.grpc.pb.go: 包含客户端存根接口与服务端接口，这2个接口都是PB文件中的接口定义
创建服务器，分为2个步骤
- 实现接口
- 运行一个gRPC服务器来监听客户端的请求并分发到正确的接口实现
  ```go
  // 指定用来监听客户端请求的端口
  lis, err := net.Listen("tcp", fmt.Sprintf("localhost:%d", port))
  if err != nil {
    log.Fatalf("failed to listen: %v", err)
  }
  var opts []grpc.ServerOption
  ...
  // 创建一个gRPC服务器实例
  grpcServer := grpc.NewServer(opts...)
  // 注册服务实现到gRPC服务器
  pb.RegisterRouteGuideServer(grpcServer, newServer())
  // 调用服务器的Serve()方法来等待请求，直到进程被Kill或者调用了stop()方法
  grpcServer.Serve(lis)
  ```

接下来创建Client，首先创建一个stub，然后再首先创建一个gRPC channel来与服务端通信，通过把服务地址与端口号传递给`grpc.NewClient`来创建，如下:
```go
var opts []grpc.DialOption
...
conn, err := grpc.NewClient(*serverAddr, opts...)
if err != nil {
  ...
}
defer conn.Close()
```
可以通过`DialOptions`来设置认证，然后创建stub来执行RPCs
```go
client := pb.NewRouteGuideClient(conn)
```
接下来就是调用RPC方法，RPC调用使用阻塞/同步的方式调用，等待返回一个响应或者一个错误。
### ALTS认证
ALTS=Application Layer Transport Security, 应用层传输安全。ALTS是一个Google开发的认证与加密系统，用来保护RPC通信，类似TLS但是更多的是满足Google本身产品的安全需求。有系列特点:
- 创建带有ALTS作为传输安全协议的gRPC服务端与客户端
- ALTS的连接是端到端隐私保护的
- 应用可以访问认证信息，比如认证的服务账户
- 客户端授权与服务端授权支持
- 只需很少的代码即可支持ALTS

gRPC客户杜u安可以使用ALTS证书来连接到服务端，如下所示:
```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

altsTC := alts.NewClientCreds(alts.DefaultClientOptions())
conn, err := grpc.NewClient(serverAddr, grpc.WithTransportCredentials(altsTC))
```
gRPC服务端开启ALTS传输安全协议
```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

altsTC := alts.NewServerCreds(alts.DefaultServerOptions())
server := grpc.NewServer(grpc.Creds(altsTC))
```
gRPC通过ALTS（Application Layer Transport Security）提供了内置的服务器授权支持。使用ALTS的gRPC客户端可以在建立连接之前设置期望的服务器服务账号。然后，在握手结束时，服务器授权会确保服务器身份与客户端指定的其中一个服务账号匹配。否则，连接将失败。
```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

clientOpts := alts.DefaultClientOptions()
clientOpts.TargetServiceAccounts = []string{expectedServerSA}
altsTC := alts.NewClientCreds(clientOpts)
conn, err := grpc.NewClient(serverAddr, grpc.WithTransportCredentials(altsTC))
```
在成功建立连接后，对等信息（例如，客户端的服务账号）将存储在`AltsContext`中。gRPC提供了一个用于客户端授权检查的实用程序库。假设服务器知道预期的客户端身份（例如，foo@iam.gserviceaccount.com），它可以运行以下示例代码来授权传入的RPC调用。
```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)
err := alts.ClientAuthorizationCheck(ctx, []string{"foo@iam.gserviceaccount.com"})
```



