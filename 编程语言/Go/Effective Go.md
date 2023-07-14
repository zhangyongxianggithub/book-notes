[TOC]
# Introduction
Go是一个新的语言，虽然Go借用了其他语言的一些理念，但是还是有自己独特的地方。将C++或Java程序直接翻译成Go不太可能产生令人满意的结果——Java程序是用Java而不是Go编写的。另一方面，从Go的角度思考问题可能会产生一个成功但完全不同的程序。换句话说，要写好Go，重要的是要了解它的属性和习语。了解Go编程的既定约定也很重要，例如命名、格式化、程序构造等，这样您编写的程序将很容易被其他Go程序员理解。本文档提供了编写清晰、惯用的Go代码的技巧。
2022年1月添加的注释：本文档是为Go于2009年发布而编写的，此后没有进行过重大更新。尽管它是了解如何使用语言本身的一个很好的指南，但由于语言的稳定性，它很少提及库，也没有提及Go生态系统自编写以来的重大变化，例如构建系统、测试、模块和多态性。没有更新它的计划，因为已经发生了很多事情，而且越来越多的文档、博客和书籍很好地描述了现代Go的用法。 Effective Go仍然有用，但读者应该明白它远非完整的指南。有关上下文，请参阅问题28782
# Formatting
格式问题是最有争议但最不重要的问题。人们可以采用不同的编码风格，但如果他们不这样做会更好，如果每个人都坚持相同的风格，那么花在格式上的时间就会更少。问题是如何在没有冗长的规范性风格指南的情况下实现这个乌托邦。对于Go，我们采用了一种不同寻常的方法，让机器处理大多数格式化问题。 `gofmt`程序（也可用作`go fmt`，它在包级别而非源文件级别运行）读取Go程序并以缩进和垂直对齐的标准样式发出源代码，保留并在必要时重新格式化注释。如果您想知道如何处理一些新的布局情况，请运行`gofmt`；如果答案看起来不正确，请重新安排您的程序（或提交有关gofmt的错误），不要绕过它。例如，无需花时间整理结构体字段的注释。 Gofmt会为你做到这一点。给出下面的声明:
```go
type T struct {
    name string // name of the object
    value int // its value
}
```
gofmt会排列列:
```go
type T struct {
    name    string // name of the object
    value   int    // its value
}
```
标准包中的Go代码都通过gofmt完成了，保留了一些格式细节。非常简短
- 缩进: tab用来缩进，gofmt默认就会使用tab来缩进，只有不许要用空格的情况下才使用;
- Line长度: Go没有行的长度限制，不用担心打孔卡溢出。如果一行感觉太长，请将其换行并缩进一个额外的制表符;
- Parentheses: Go相比C与Java需要很少的括号，控制结构，比如if、for、switch不需要括号，运算符优先级更加简短与清晰。`x<<8 + y<=16`正如空格所暗示的，这是与其他语言不同的;

# Commentary注释
Go提供了C风格的/**/的块注释与C++风格的//行注释。行注释更常用，块注释更多的是作为块注释，在一个表达式中或者需要注释多行代码的时候更有用。出现在顶级声明之前的注释且中间没有换行符，被认为是声明本身的文档。这些文档注释是Go包或命令的主要文档。有关文档注释的更多信息，请参阅[Go Doc Comments](https://go.dev/doc/comment)
# Names
命名在Go中的重要性与其他语言是一样的，它们甚至有语义上的影响: 包外名字的可见性是由首字母是否大写来决定的。因此，值得花一点时间讨论Go程序中的命名约定。
## Package names
当导入包时，包名成为内容的访问器。在`import "bytes"`之后，导入包可以访问`bytes.Buffer`，如果使用该包的每个人都可以使用相同的名称来引用其内容，这将很有帮助，这意味着包的名字需要良好的命名: short、concise、evocative。按照约定，包名都是小写的单个单词，不需要下划线或者混合大写字母。过于简洁是错误的，因为使用您的包的每个人都会输入该名称。并且不必担心名字碰撞。包名只是导入的默认名称；它不需要在所有源代码中都是唯一的，并且在极少数发生冲突的情况下，导入包可以选择一个不同的名称在本地使用。无论如何，混淆是很少见的，因为导入中的文件名决定了正在使用的包。另一个约定是包名是它的源代码目录名字，在src/encoding/base64目录中的包被导入为encoding/base64,包的名字是base64。包的导入者将使用名称来引用其内容，因此包中导出的名称可以使用该事实来避免重复。（不要使用import .符号，它可以简化必须在他们正在测试的包之外运行的测试，但应该避免使用）例如，bufio包中的缓冲读取器类型称为Reader，而不是BufReader，因为用户将其视为bufio.Reader，这是一个清晰、简洁的名称。此外，因为导入的实体总是用它们的包名称来寻址，所以bufio.Reader不会与io.Reader冲突。类似地，创建ring.Ring新实例的函数——这是Go中构造函数的定义——通常被称为NewRing，但由于Ring是包导出的唯一类型，并且由于包被称为 ring，所以它称为New，包的客户端将其视为ring.New。使用包结构来帮助您选择好的名称。另一个简短的例子是`once.Do`; `once.Do(setup)`读起来很好，不会通过写`once.DoOrWaitUntilDone(setup)`得到改善。长名称不会自动使内容更具可读性。有用的文档注释通常比超长的名称更有价值。
## Getters
Go不提供对getter和setter的自动支持。自己提供getter和setter没有错，这样做通常是合适的，但是将Get放入getter的名称中既不符合习惯也没有必要。 如果您有一个名为owner（小写，未导出）的字段，则getter方法应称为Owner（大写，已导出），而不是GetOwner。使用大写名称进行导出提供了区分字段和方法的挂钩。如果需要，setter函数可能会被称为SetOwner。这两个名字在实践中读起来都很好:
```go
owner := obj.Owner()
if owner != user {
    obj.SetOwner(user)
}
```
## Interface names
按照约定，单方法接口的命名方式是方法名加上-er后缀或类似修饰构造代理名词：Reader、Writer、Formatter、CloseNotifier等。有许多这样的名称，尊重它们和它们捕获的函数名称是很有成效的。 Read、Write、Close、Flush、String等具有规范的签名和含义。为避免混淆，除非具有相同的签名和含义，否则不要给您的方法使用这些名称之一。相反，如果你的类型实现了一个与知名类型上的方法具有相同含义的方法，则为其赋予相同的名称和签名； 调用您的字符串转换器方法String而不是 ToString。
最后，Go 中的约定是使用MixedCaps或mixedCaps而不是下划线来编写多词名称。
# Semicolons
与C一样，Go的形式语法使用分号来终止语句，但与C不同的是，这些分号不会出现在源代码中。 相反，词法分析器使用一个简单的规则在扫描时自动插入分号，因此输入文本大部分没有分号。规则是这样的。如果换行符之前的最后一个标记是标识符（包括int和float64等词）、基本文字（例如数字或字符串常量）或标记之一`break continue fallthrough return ++ -- ) }`，词法分析器总是在标记后插入一个分号。 这可以概括为: 如果换行符出现在可以结束语句的标记之后，则插入分号。右括号前的分号也可以省略，所以像这样的语句:`go func() { for { dst <- <-src } }()`不需要分号。地道的Go程序只在for循环子句等地方使用分号，以分隔初始值设定项、条件和延续元素。 如果您以这种方式编写代码，它们也是分隔一行中的多个语句所必需的。分号插入规则的一个后果是您不能将控制结构（if、for、switch或select）的左大括号放在下一行。如果这样做，将在大括号之前插入一个分号，这可能会导致不需要的效果。像这样写它们:
```go
if i < f() {
    g()
}
```
而不是这样:
```go
if i < f()  // wrong!
{           // wrong!
    g()
}
```
# 控制结构
Go的控制结构与C语言中的控制结构相关，但在某些重要的方面是完全不同的。 Go没有do或while循环，只有一个稍微概括的for循环；switch更灵活；if和switch接受一个可选的初始化语句，就像 for一样; break和continue语句采用可选标签来标识要中断或继续的内容；并且有新的控制结构，包括type switch和多路通信复用器select。语法也略有不同: 没有括号，主体必须始终用大括号分隔。Go中的if类似:
```go
if x > 0 {
    return y
}
```
if与switch接受一个初始化语句，通常用来设置局部变量
```go
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}
```
在Go的库中，您会发现当if语句没有流入下一个语句时——也就是说，主体以break、continue、goto或return结尾——不必要的else被省略。
```go
f, err := os.Open(name)
if err != nil {
    return err
}
codeUsing(f)
```
```go
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
codeUsing(f, d)
```
# 函数
## Defer
Go的Defer语句调度一个函数在执行return前执行(deferred function)，这是一种不寻常但有效的方法来处理诸如无论函数返回哪条路径都必须释放资源等情况。典型的例子是解锁Mutex或关闭文件。
```go
// Contents returns the file's contents as a string.
func Contents(filename string) (string, error) {
    f, err := os.Open(filename)
    if err != nil {
        return "", err
    }
    defer f.Close()  // f.Close will run when we're finished.

    var result []byte
    buf := make([]byte, 100)
    for {
        n, err := f.Read(buf[0:])
        result = append(result, buf[0:n]...) // append is discussed later.
        if err != nil {
            if err == io.EOF {
                break
            }
            return "", err  // f will be closed if we return here.
        }
    }
    return string(result), nil // f will be closed if we return here.
}
```
延迟函数调用有2个优势:
- 它保证你不会忘记close，比如你加了一个条件分支return，可能忘记加close
- close在open附近，比放在函数末尾更加清晰。

传递给延迟函数的参数在defer执行时计算，不是延迟函数执行时计算。除了避免担心函数执行时变量值发生变化之外，这意味着单个延迟调用站点可以延迟多个函数执行。这是一个愚蠢的例子:
```go
for i := 0; i < 5; i++ {
    defer fmt.Printf("%d ", i)
}
```
延迟函数的执行采用的是后进先出的顺序。因此此代码将导致函数返回时打印4 3 2 1 0。 一个更合理的例子是通过程序跟踪函数执行的简单方法。我们可以编写几个简单的跟踪例程，如下所示:
```go
func trace(s string)   { fmt.Println("entering:", s) }
func untrace(s string) { fmt.Println("leaving:", s) }

// Use them like this:
func a() {
    trace("a")
    defer untrace("a")
    // do something....
}
```
我们可以通过利用延迟执行时评估延迟函数的参数这一事实来做得更好。跟踪例程可以设置非跟踪例程的参数。这个例子:
```go
func trace(s string) string {
    fmt.Println("entering:", s)
    return s
}

func un(s string) {
    fmt.Println("leaving:", s)
}

func a() {
    defer un(trace("a"))
    fmt.Println("in a")
}

func b() {
    defer un(trace("b"))
    fmt.Println("in b")
    a()
}

func main() {
    b()
}
```
对于习惯于其他语言的块级资源管理的程序员来说，defer可能看起来很奇怪，但它最有趣和最强大的应用恰恰来自于它不是基于块而是基于函数的事实。在有关panic和recover的部分中，我们将看到其可能性的另一个示例。
# Data
## Allocation with new
Go有2种分配原语，内置的函数new与make，他们职责不同并且以应用于不同的类型。new, 用于分配内存的函数，但是与其他语言中的new不同，它不初始化内存，只是zero它，也就是说，new(T)会为类型T的item分配0值，并且返回地址也就是类型*T，在Go的术语中，它返回类型T零值的指针;
