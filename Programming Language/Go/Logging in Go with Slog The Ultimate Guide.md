在这篇文章中，我们将会探索Go中的结构化日志记录包`log/slog`，具有高性能、结构化与分级日志记录的特性。`log/slog`软件包源于Jonathan Amsterdam在GitHub上发起的一次讨论。经过讨论之后，又提出了一个描述包设计细节的提案。最终，该软件包在Go v1.21版本中正式发布，并被放置在log/slog包中。
# Getting started with Slog
首先探索其设计与架构，你需要熟悉3个主要类型
- `Logger`: 日志记录的前端，提供了分级的日志记录方法，比如`Inof()`或者`Error`等，用来记录感兴趣的事件
- `Record`: 由`Logger`创建的日志对象的表示形式
- `Handler`: 一个接口，定义了格式化与日志记录目的地，有2个内置的实现`TextHandler`与`JSONHandler`，分别输出`key=value`与JSON形式

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
所有的方法第一个参数是一个log message，后面是任意的key/value对，但是如果最后一个值没有提供value，会造成错误的未预期的输出，此时可以使用下面的形式
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
在一个特定的范围内复用一些相同的属性是常用的，而且不需要重复的书写这些信息。子logger就是解决这个问题的，因为子logger会创建一个新的继承父logger的日志记录上下文。创建子logger的方法`Logger.With()`，接受一个或者多个key/value对，返回包含指定属性的新的`Logger`，考虑下面的代码片段，添加进程ID与Go版本到每个日志记录，并把他们存储在`program_info`属性中
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
日志记录方法也有第一个参数是`context.Context`的变体。方法签名如下:
```go
func (ctx context.Context, msg string, args ...any)
```
考虑下面的程序
```go
package main

import (
    "context"
    "log/slog"
    "os"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

    ctx := context.WithValue(context.Background(), "request_id", "req-123")

    logger.InfoContext(ctx, "image uploaded", slog.String("image_id", "img-998"))
}
```
# Error logging with Slog
记录error的方法，使用`slog.Any()`
```go
err := errors.New("something happened")
logger.ErrorContext(ctx, "upload failed", slog.Any("error", err))
```
为了获取并记录异常栈，你可以使用类似`xerrors`的包来创建带有异常栈的errors，如下:
```go
err := xerrors.New("something happened")
logger.ErrorContext(ctx, "upload failed", slog.Any("error", err))
```
在打印到错误日志时，你需要解析、格式化并通过`ReplaceAttr()`函数添加到对应的`Record`。
```go
package main

import (
    "context"
    "log/slog"
    "os"
    "path/filepath"

    "github.com/mdobak/go-xerrors"
)

type stackFrame struct {
    Func   string `json:"func"`
    Source string `json:"source"`
    Line   int    `json:"line"`
}

func replaceAttr(_ []string, a slog.Attr) slog.Attr {
    switch a.Value.Kind() {
    case slog.KindAny:
        switch v := a.Value.Any().(type) {
        case error:
            a.Value = fmtErr(v)
        }
    }

    return a
}

// marshalStack extracts stack frames from the error
func marshalStack(err error) []stackFrame {
    trace := xerrors.StackTrace(err)

    if len(trace) == 0 {
        return nil
    }

    frames := trace.Frames()

    s := make([]stackFrame, len(frames))

    for i, v := range frames {
        f := stackFrame{
            Source: filepath.Join(
                filepath.Base(filepath.Dir(v.File)),
                filepath.Base(v.File),
            ),
            Func: filepath.Base(v.Function),
            Line: v.Line,
        }

        s[i] = f
    }

    return s
}

// fmtErr returns a slog.Value with keys `msg` and `trace`. If the error
// does not implement interface { StackTrace() errors.StackTrace }, the `trace`
// key is omitted.
func fmtErr(err error) slog.Value {
    var groupValues []slog.Attr

    groupValues = append(groupValues, slog.String("msg", err.Error()))

    frames := marshalStack(err)

    if frames != nil {
        groupValues = append(groupValues,
            slog.Any("trace", frames),
        )
    }

    return slog.GroupValue(groupValues...)
}

func main() {
    h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        ReplaceAttr: replaceAttr,
    })

    logger := slog.New(h)

    ctx := context.Background()

    err := xerrors.New("something happened")

    logger.ErrorContext(ctx, "image uploaded", slog.Any("error", err))
}

```
# Hiding sensitive fields with the LogValuer interface
`LogValuer`接口可以通过控制特定类型如何输出来标准化日志输出。接口的签名
```go
type LogValuer interface {
    LogValue() Value
}
```
主要的使用场景就是隐藏结构体中的字段。比如，下面的`User`类型，没有实现`LogValuer`接口，当打印实例日志时，敏感信息就会暴露
```go
// User does not implement `LogValuer` here
type User struct {
    ID        string `json:"id"`
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
    Email     string `json:"email"`
    Password  string `json:"password"`
}

func main() {
    handler := slog.NewJSONHandler(os.Stdout, nil)
    logger := slog.New(handler)

    u := &User{
        ID:        "user-12234",
        FirstName: "Jan",
        LastName:  "Doe",
        Email:     "jan@example.com",
        Password:  "pass-12334",
    }

    logger.Info("info", "user", u)
}
```
你可以指定这个类型如何在日志中打印，你可以指定只打印ID字段
```go
// implement the `LogValuer` interface on the User struct
func (u User) LogValue() slog.Value {
    return slog.StringValue(u.ID)
}
```
也可以对多个属性分组
```go
func (u User) LogValue() slog.Value {
    return slog.GroupValue(
        slog.String("id", u.ID),
        slog.String("name", u.FirstName+" "+u.LastName),
    )
}
```
# Using third-party logging backends with Slog
Slog的主要设计目标就是提供一个统一的日志记录前端`slog.Logger`，而后端(`slog.Handler`)是可定制的。这样，所有的日志记录库的日志记录API就都是一致的。也解耦了日志实现与特定的包，这样可以在项目中任意的切换不同的日志实现。下面是一个使用[Zap](https://betterstack.com/community/guides/logging/go/zap/)日志实现的例子。
```go
package main

import (
    "log/slog"

    "go.uber.org/zap"
    "go.uber.org/zap/exp/zapslog"
)
func main() {
    zapL := zap.Must(zap.NewProduction())
    defer zapL.Sync()
    logger := slog.New(zapslog.NewHandler(zapL.Core(), nil))
    logger.Info(
        "incoming request",
        slog.String("method", "GET"),
        slog.String("path", "/api/user"),
        slog.Int("status", 200),
    )
}
```
这个片段床了一个`zap.Logger`实例，然后使用`zapslog.NewHandler`创建了一个`slog.Handler`。最后，将这个handler作为参数传给`slog.New`函数，这样就可以使用`slog.Logger`来记录日志了。切换成不同的日志实现，只需要替换`zapslog.NewHandler`的参数即可。
```go
package main

import (
    "log/slog"
    "os"

    "github.com/rs/zerolog"
    slogzerolog "github.com/samber/slog-zerolog"
)

func main() {
    zerologL := zerolog.New(os.Stdout).Level(zerolog.InfoLevel)

    logger := slog.New(
        slogzerolog.Option{Logger: &zerologL}.NewZerologHandler(),
    )

    logger.Info(
        "incoming request",
        slog.String("method", "GET"),
        slog.String("path", "/api/user"),
        slog.Int("status", 200),
    )
}
```
# Best Pratices for writing and storing Go logs
- Standardize your logging interface: 通过实现`LogValuer`接口，您可以标准化应用程序中各种类型的日志记录方式，以确保它们在日志中的表示在整个应用程序中保持一致。正如我们在本文前面所探讨的那样，这也是确保从应用程序日志中省略敏感字段的有效策略
- Add a stack trace to your error logs: 为了提升debug问题的能力，你应该在错误日志中添加stack trace，这样，就很容易指出错误发生的位置以及导致错误发生的程序流。slog目前没有提供内置的方式来支持添加stack tarce到错误日志，但是正如前面我们所展示的，可以使用[pkgerrors](https://github.com/pkg/errors)或者[go-xerros](https://github.com/MDobak/go-xerrors)包
- Lint your Slog statements to enforce consistency: Slog API的一个主要缺点就是，它支持不同的参数类型，在代码库中可能存在不同的日志记录形式，除此以外，你可能想要强制使用统一的key命名约定或者所有的日志记录函数调用都应该包含一个context参数。linter比入[sloglint](https://github.com/go-simpler/sloglint/releases)可以帮助你统一日志风格，下面是一个使用[golangci-lint](https://freshman.tech/linting-golang/)例子:
  ```yaml
    linters-settings:
    sloglint:
        # Enforce not mixing key-value pairs and attributes.
        # Default: true
        no-mixed-args: false
        # Enforce using key-value pairs only (overrides no-mixed-args, incompatible with attr-only).
        # Default: false
        kv-only: true
        # Enforce using attributes only (overrides no-mixed-args, incompatible with kv-only).
        # Default: false
        attr-only: true
        # Enforce using methods that accept a context.
        # Default: false
        context-only: true
        # Enforce using static values for log messages.
        # Default: false
        static-msg: true
        # Enforce using constants instead of raw keys.
        # Default: false
        no-raw-keys: true
        # Enforce a single key naming convention.
        # Values: snake, kebab, camel, pascal
        # Default: ""
        key-naming-case: snake
        # Enforce putting arguments on separate lines.
        # Default: false
        args-on-sep-lines: true
  ```
- Centralize your logs, but persist them to local files first: 通常，最好将写入日志的任务与将日志发送到集中式日志管理系统的任务分离开来。首先将日志写入本地文件可确保在日志管理系统或网络遇到问题时进行备份，从而防止关键数据丢失。此外，在发送日志之前将日志存储在本地有助于缓冲日志，从而允许批量传输，以帮助优化网络带宽使用率并最大限度地减少对应用程序性能的影响。本地日志存储还提供了更大的灵活性，因此如果需要过渡到不同的日志管理系统，则只需修改传送方法，而不是整个应用程序日志记录机制。有关更多详细信息，请参阅我们关于使用 Vector 或 Fluentd 等专用日志传送器的文章。记录到文件并不一定需要您将所选框架配置为直接写入文件，因为 Systemd可以轻松地将应用程序的标准输出和错误流重定向到文件。Docker还默认收集发送到两个流的所有数据并将它们路由到主机上的本地文件
- Sample your logs: 日志采样是一种仅记录日志条目的代表性子集而非记录每个日志事件的做法。这种技术在高流量环境中非常有用，因为系统会生成大量日志数据，而处理每个条目的成本可能非常高，因为集中式日志解决方案通常根据数据采集率或存储量收费。
  ```go
    package main

    import (
        "fmt"
        "log/slog"
        "os"

        slogmulti "github.com/samber/slog-multi"
        slogsampling "github.com/samber/slog-sampling"
    )

    func main() {
        // Will print 20% of entries.
        option := slogsampling.UniformSamplingOption{
            Rate: 0.2,
        }

        logger := slog.New(
            slogmulti.
                Pipe(option.NewMiddleware()).
                Handler(slog.NewJSONHandler(os.Stdout, nil)),
        )

        for i := 1; i <= 10; i++ {
            logger.Info(fmt.Sprintf("a message from the gods: %d", i))
        }
    }
  ```
  第三方框架比入[Zerolog](https://betterstack.com/community/guides/logging/zerolog/#log-sampling-with-zerolog)与[Zap](https://betterstack.com/community/guides/logging/go/zap/#log-sampling-with-zap)已经提供了内置的日志采样功能，使用 Slog，您必须集成第三方handler(例如[slog-sampling](https://github.com/samber/slog-sampling))或开发自定义解决方案。您还可以选择通过专用日志发送程序（例如 Vector）对日志进行采样
- Use a log management service: 将日志集中到日志管理系统中，可以轻松搜索、分析和监控应用程序在多个服务器和环境中的行为。将所有日志集中到一个位置，可以大大提高您识别和诊断问题的能力，因为您不再需要在不同的服务器之间跳转来收集有关服务的信息。虽然目前有多种日志管理解决方案，但[Better Stack](https://betterstack.com/logs)提供了一种在几分钟内设置集中日志管理的简单方法，其中实时跟踪、警报、仪表板和正常运行时间监控以及事件管理功能内置在现代且直观的界面中。请在此处试用完全免费的计划。
# Final thoughts
