Protocol Buffers are a language-neutral, platform-neutral extensible mechanism for serializing structured data.
# Programming Guides
## Language Guide(proto 3)
### Defining Services
通过远程调用系统使用你的消息类型，需要定义RPC服务接口。ProtoBuf编译器会生成接口代码与stubs。比如下面的例子:
```protobuf
service SearchService {
  rpc Search(SearchRequest) returns (SearchResponse);
}
```
实现ProtoBuf的RPC系统就是gRPC，语言无关的，平台无关的开源RPC系统。与ProtoBuf协同工作。让你可以直接通过.proto文件生成RPC代码。当让也有一些第三方的支持ProtoBuf的实现。
# Reference Guides
## Go
protoc如何通过`.proto`文件生成Go代码。protoc需要一个插件来生成Go代码，需要先安装`go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`，将会安装`protoc-gen-go`到`$GOBIN`目录，`$GOBIN`目录必须在PATH里面，要不protoc找不到。使用`go_out`命令行标志的时候产生Go代码，`go_out`的参数值是一个目录，目录里面是你的Go的代码，每个`.proto`文件一个源代码文件，文件名就是把`.proto`替换为你`.pb.go`，在输出目录中如何存放文件依赖编译器标志，有几种输出模式:
- 如果指定`paths=import`，输出文件会放到一个Go的包的导入路径的目录，这个导入路径可能是由`.proto`文件中的`go_package`选项提供的，比如输入文件`protos/buzz.proto`定义了一个Go导入路径`example.com/project/protos/fizz`，那么会导致输出文件的路径为`example.com/project/protos/fizz/buzz.pb.go`，这是默认的输出模式
- 如果指定`module=$PREFIX`标志，输出文件会放到一个Go的包的导入路径的目录，但是会移除输出文件路径中指定的路径前缀，比如输入文件是`protos/buzz.proto`，包的导入路径是`example.com/project/protos/fizz`，`module=example.com/project`，那么输出的文件路径是`protos/fizz/buzz.pb.go`，在模块路径之外生成任何的Go包都会导致错误，这个模式用来直接输出文件到Go模块
- 如果指定`paths=source_relative`，输出文件放到输入文件的相同位置，比如输入文件是`protos/buzz.proto`，那么输出文件放到`protos/buzz.pb.go`

protoc-gen-go使用的这些标志通过`go_opt`标志传输，支持多个`go_opt`标志，如下:
```shell
protoc --proto_path=src --go_out=out --go_opt=paths=source_relative foo.proto bar/baz.proto
```
编译器将会读取读取src目录下的proto文件，写入入文件到out目录下，编译器会自动创建输出目录中的子目录。为了生成Go代码，pb文件必须提供Go的包导入路径，包含当前pb文件依赖的pb文件，2种方式
- 在pb文件中声明
- 在命令行上声明

建议在`.proto`文件中声明Go包路径，以便`.proto`文件的Go包路径与其自身关联，并简化调用`protoc`时传递的标志集。如果给定的`.proto`文件的Go导入路径同时在`.proto`文件本身和命令行中提供，则后者优先于前者。Go导入路径在`.proto`文件中通过声明`go_package`选项并指定Go 包的完整导入路径来本地指定。示例用法:
```protobuf
option go_package = "example.com/project/protos/fizz";
```
Go导入路径可以在调用编译器时通过命令行传递一个或多个`M${PROTO_FILE}=${GO_IMPORT_PATH}`标志来指定。示例用法：
```shell
protoc --proto_path=src \
  --go_opt=Mprotos/buzz.proto=example.com/project/protos/fizz \
  --go_opt=Mprotos/bar.proto=example.com/project/protos/foo \
  protos/buzz.proto protos/bar.proto
```
由于可能需要为很多的`.proto`文件设置Go导入路径，因此这种指定Go导入路径的方式通常由一些构建工具（例如 Bazel）来执行，这些工具可以控制整个依赖树。如果给定的.proto文件有多个映射设置，则最后指定的映射设置优先。对于`go_package`选项和`M`标志中的参数值，都可以在导入路径后用分号后跟显式的包名来指定Go的简短包名。例如：`example.com/protos/foo;package_name`。这种用法不推荐，因为包名会根据导入路径以合理的方式自动派生。导入路径用于确定当一个`.proto`文件导入另一个`.proto`文件时需要生成的Go import语句。例如，如果`a.proto`导入了 `b.proto`，那么生成的`a.pb.go`文件需要导入生成的`b.pb.go`文件的Go包（除非这两个文件位于同一个包中）。导入路径也用于构建输出文件名。详情请参阅上面的“编译器调用”部分。Go导入路径与`.proto`文件中的`package`声明没有相关性。后者仅与protobuf命名空间相关，前者仅与Go命名空间相关。此外，Go导入路径与`.proto`文件的import语句路径也没有相关性。