Fn是一个event-driven、open source、Function-as-a-Sevices(FaaS)计算平台，你可以在任何地方运行
- Open Source
- Native Docker: use any Docker contianer as your Function
- Supports all languages
- Run anywhere
  - Public, private and hybird cloud
  - import Lambda functions and run them anywhere
- Easy to use for developers
- Easy to manage for operators
- Written in GO
- Simple yet powerful extensibility
# 安装CLI工具与Server
```bash
brew update && brew install fn
```
还有其他平台的安装方式。
创建应用的基本步骤
```bash
fn start
```
启动一个单机模式的Fn，会使用内存数据库与内存消息队列。有很多配置选项。函数是小规模的代码块，只做一件事情，但是功能强大。
```bash
fn init --runtime go hello
cd hello
```
你可以使用任何运行时，go、java、node、python等。hello会是函数的名字。
```bash
fn create app myapp
fn deploy --app myapp --local

```
app是函数的集合。
```bash
fn invoke myapp hello
```
其实它更多的是一个FaaS，并不是一个事件驱动的应用，如果这么做，维护起来会比较复杂。
