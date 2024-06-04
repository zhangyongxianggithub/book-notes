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
在一个特定的范围内服用一些相同的属性是常用的，而且不需要重复的书写这些信息。子logger就是解决这个问题的，因为子logger会创建一个新的继承父logger的日志记录上下文。创建子logger的方法`Logger.With()`，接受一个或者多个key/value对，返回包含指定属性的心的`Logger`，考虑下面的代码片段，添加进程ID与Go版本到每个日志记录，并把他们存储在`program_info`属性中
```go
func main() {
    handler := slog.NewJSONHandler(os.Stdout, nil)
    buildInfo, _ := debug.ReadBuildInfo()
    logger := slog.New(handler)
    child := logger.With(
        slog.Group("program_info",
            slog.Int("pid", os.Getpid()),
            slog.String("go_version", buildInfo.GoVersion),
        ),
    )
}
```
也可以使用`WithGroup()`方法
```go
handler := slog.NewJSONHandler(os.Stdout, nil)
buildInfo, _ := debug.ReadBuildInfo()
logger := slog.New(handler).WithGroup("program_info")

child := logger.With(
  slog.Int("pid", os.Getpid()),
  slog.String("go_version", buildInfo.GoVersion),
)

child.Warn(
  "storage is 90% full",
  slog.String("available_space", "900.1 MB"),
)
```
# Customizing Slog levels
`log/slog`包默认提供了4种日志级别，每个级别都有一个关联的整数
- `DEBUG`(-4)
- `INFo`(0)
- `WARN`(4)
- `ERROR`(8)

数字值都是精心设计的，为了创建自定义的日志级别。默认打印`INFO`级别的日志，你可以可以通过`HandlerOptions`自定义日志记录的最低级别
```go
func main() {
    opts := &slog.HandlerOptions{
        Level: slog.LevelDebug,
    }
    handler := slog.NewJSONHandler(os.Stdout, opts)
    logger := slog.New(handler)
    logger.Debug("Debug message")
    logger.Info("Info message")
    logger.Warn("Warning message")
    logger.Error("Error message")
}
```
这种级别的设置贯穿`handler`的整个生命周期，如果需要最低日志级别动态变更，可以使用`LevelVar`
```go
func main() {
    logLevel := &slog.LevelVar{} // INFO
    opts := &slog.HandlerOptions{
        Level: logLevel,
    }
    handler := slog.NewJSONHandler(os.Stdout, opts)
}
```
你可以随时变更日志级别`logLevel.Set(slog.LevelDebug)`。自定义日志级别只需要实现`Leveler`接口
```go
type Leveler interface {
    Level() Level
}
```
`Level`本身也实现了`Leveler`接口
```go
const (
    LevelTrace  = slog.Level(-8)
    LevelFatal  = slog.Level(12)
)
```
一旦你像上面那样定义了自定义日志级别，你就可以通过`Log()`与`LogAttrs()`方法来使用它们。
```go
opts := &slog.HandlerOptions{
    Level: LevelTrace,
}
logger := slog.New(slog.NewJSONHandler(os.Stdout, opts))
ctx := context.Background()
logger.Log(ctx, LevelTrace, "Trace message")
logger.Log(ctx, LevelFatal, "Fatal level")
```
注意自定义日志级别的输出，这可能不是你想要的，你可能想要自定义日志级别名字，这可以通过`handlerOptions`实现
```go
var LevelNames = map[slog.Leveler]string{
    LevelTrace:      "TRACE",
    LevelFatal:      "FATAL",
}
func main() {
    opts := slog.HandlerOptions{
        Level: LevelTrace,
        ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
            if a.Key == slog.LevelKey {
                level := a.Value.Any().(slog.Level)
                levelLabel, exists := LevelNames[level]
                if !exists {
                    levelLabel = level.String()
                }

                a.Value = slog.StringValue(levelLabel)
            }

            return a
        },
    }
}
```
`ReplaceAttr()`函数用来定义一个`Record`中的每个key/value对如何被`Handler`处理。
# Customizing Slog Handlers
正如前面提到的，`TextHandler`与`JSONHandler`可以使用`HandlerOptions`定制。你在前面的例子中已经看到如何修改最小日志级别与修改属性。目前`HandlerOptions`还支持包含log source。
```go
opts := &slog.HandlerOptions{
    AddSource: true,
    Level:     slog.LevelDebug,
}
```
根据应用程序环境切换足够多的处理程序也轻而易举。例如，对于开发日志，您可能更喜欢使用`TextHandler`，因为它更易于阅读，然后在生产环境中切换到`JSONHandler`，以获得更大的灵活性并兼容各种日志记录工具。这可以通过环境变量实现
```go
var appEnv = os.Getenv("APP_ENV")
func main() {
    opts := &slog.HandlerOptions{
        Level: slog.LevelDebug,
    }

    var handler slog.Handler = slog.NewTextHandler(os.Stdout, opts)
    if appEnv == "production" {
        handler = slog.NewJSONHandler(os.Stdout, opts)
    }

    logger := slog.New(handler)

    logger.Info("Info message")
}
```
可以实现`Handler`接口自定义日志输出格式或者日志输出目的地。
```go
type Handler interface {
    Enabled(context.Context, Level) bool
    Handle(context.Context, r Record) error
    WithAttrs(attrs []Attr) Handler
    WithGroup(name string) Handler
}
```
- `Enabled()`方法决定根据level是否处理或者丢弃日志，`context`也能用来做决策
- `Handle()`方法处理发送到handler的每条日志记录，只有在`Enabled()`返回true这个方法才会调用
- `WithAttrs()`从当前的Handler创建一个新的Handler并添加额外的属性
- `WithGroup()`从现有Handler创建一个新的Handler，并向其添加指定的组名，以使该名称符合后续属性

下面是一个例子，这个例子使用了`log`、`json` 、[color](https://github.com/fatih/color)包来实现日志的美化输出
```go
// NOTE: Not well tested, just an illustration of what's possible
package main

import (
    "context"
    "encoding/json"
    "io"
    "log"
    "log/slog"

    "github.com/fatih/color"
)

type PrettyHandlerOptions struct {
    SlogOpts slog.HandlerOptions
}

type PrettyHandler struct {
    slog.Handler
    l *log.Logger
}

func (h *PrettyHandler) Handle(ctx context.Context, r slog.Record) error {
    level := r.Level.String() + ":"

    switch r.Level {
    case slog.LevelDebug:
        level = color.MagentaString(level)
    case slog.LevelInfo:
        level = color.BlueString(level)
    case slog.LevelWarn:
        level = color.YellowString(level)
    case slog.LevelError:
        level = color.RedString(level)
    }

    fields := make(map[string]interface{}, r.NumAttrs())
    r.Attrs(func(a slog.Attr) bool {
        fields[a.Key] = a.Value.Any()

        return true
    })

    b, err := json.MarshalIndent(fields, "", "  ")
    if err != nil {
        return err
    }

    timeStr := r.Time.Format("[15:05:05.000]")
    msg := color.CyanString(r.Message)

    h.l.Println(timeStr, level, msg, color.WhiteString(string(b)))

    return nil
}

func NewPrettyHandler(
    out io.Writer,
    opts PrettyHandlerOptions,
) *PrettyHandler {
    h := &PrettyHandler{
        Handler: slog.NewJSONHandler(out, &opts.SlogOpts),
        l:       log.New(out, "", 0),
    }

    return h
}
```
社区也提供了几个Handler，一些重要的Handler如下:
- [tint](https://github.com/lmittmann/tint)，输出彩色日志
- [slog-sampling](https://github.com/samber/slog-sampling)，通过丢弃重复的日志记录来提高日志吞吐量
- [slog-multi](https://github.com/samber/slog-multi)
- [slog-formatter](https://github.com/samber/slog-formatter)，提供更灵活的格式化

# 在Slog中使用context包

