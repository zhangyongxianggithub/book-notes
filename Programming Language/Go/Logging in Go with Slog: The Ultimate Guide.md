在这篇文章中，我们将会探索Go中的结构化日志记录包`log/slog`，具有高性能、结构化于分级日志记录的特性。`log/slog`软件包源于Jonathan Amsterdam在GitHub上发起的一次讨论。经过讨论之后，又提出了一个描述包设计细节的提案。最终，该软件包在Go v1.21版本中正式发布，并被放置在log/slog包中。
# Getting started with Slog
首先探索其设计与架构，你需要熟悉3个主要类型
- `Logger`: 日志记录的前端，提供了分级的日志记录方法，比如`Inof()`或者`Error`等，用来记录感兴趣的事件
- `Record`: 由`Logger`创建的日志对象的表示形式
- `Handler`: 一个借口，定义了格式化与日志记录目的地，有2个内置的实现`TextHandler`与`JSONHandler`，分别输出`key=value`与JSON形式

与大多数的Go日志记录库类似，`slog`包也暴露了一个默认的`Logger`，可以通过包级别的方法访问，这个logger与`log.Printf()`产生的日志输出是类似的，只是包含日志级别。只需要`slog.New()`方法就可以创建一个新的`Logger`对象，它接受一个`Handler`接口的实现。如果使用`TextHandler`，那么每个`Record`会被格式化为[Logfmt standard](https://betterstack.com/community/guides/logging/logfmt/)，所有的`Logger`默认记录`INFO`级别的日志，但是你可以改变。
```go
func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	logger.Debug("Debug message")
	logger.Info("Info message")
	logger.Warn("Warning message")
	logger.Error("Error message")
}
```
# Customizing the default logger
最直接的方法是使用`slog.SetDefault()`，你可以替换默认的logger
```go
func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	slog.Info("Info message")
}
```
`slog.SetDefault()`方法也也会改变`log`包底层的默认logger。这样可以让已有的使用`log`包的应用平滑的切换到结构化日志记录，`slog.NewLogLogger()`也可以把一个`slog.Logger`转换为`log.Logger`
```go
func main() {
    handler := slog.NewJSONHandler(os.Stdout, nil)
    logger := slog.NewLogLogger(handler, slog.LevelError)
    _ = http.Server{
        // this API only accepts `log.Logger`
        ErrorLog: logger,
    }
}
```
# 添加上下文属性到日志记录
结构化日志的优势就是在日志记录中添加key/value对形式的属性。这些属性提供了关于记录的事件的额外上下文，这些信息有助于疑难解答、生成指标信息、审计或其他的一些用途。
```go
logger.Info(
  "incoming request",
  "method", "GET",
  "time_taken_ms", 158,
  "path", "/hello/world?q=search",
  "status", 200,
  "user_agent", "Googlebot/2.1 (+http://www.google.com/bot.html)",
)
```
所有的方法第一个参数是一个log message，后面是任意的key/value对，但是如果最后一个值没有提供value化，会造成错误的未预期的输出，此时可以使用下面的形式
```go
logger.Info(
  "incoming request",
  slog.String("method", "GET"),
  slog.Int("time_taken_ms", 158),
  slog.String("path", "/hello/world?q=search"),
  slog.Int("status", 200),
  slog.String(
    "user_agent",
    "Googlebot/2.1 (+http://www.google.com/bot.html)",
  ),
)
```
如果需要完全的规范的格式输出,使用方法
```go
logger.LogAttrs(
  context.Background(),
  slog.LevelInfo,
  "incoming request",
  slog.String("method", "GET"),
  slog.Int("time_taken_ms", 158),
  slog.String("path", "/hello/world?q=search"),
  slog.Int("status", 200),
  slog.String(
    "user_agent",
    "Googlebot/2.1 (+http://www.google.com/bot.html)",
  ),
)
```
这个方法强制使用类型安全的key/value构造形式。Slog支持将多个属性组成组，但是输出依赖使用的`Handler`，比如如果使用`JSONHandler`，则每个组就是JSON中的一个对象。
```go
logger.LogAttrs(
  context.Background(),
  slog.LevelInfo,
  "image uploaded",
  slog.Int("id", 23123),
  slog.Group("properties",
    slog.Int("width", 4000),
    slog.Int("height", 3000),
    slog.String("format", "jpeg"),
  ),
)
```
```json
{
  "time":"2023-02-24T12:03:12.175582603+01:00",
  "level":"INFO",
  "msg":"image uploaded",
  "id":23123,
  "properties":{
    "width":4000,
    "height":3000,
    "format":"jpeg"
  }
}
```
# Creating and using child loggers