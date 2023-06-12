# overview
context包定义了Context类型，携带了deadlines、cancellation信号，还有其他跨API边界或者进程之间的request-scope。请求应该创建一个Context，输出需要接收一个Context。函数调用链需要传播Context，甚至可以使用`WithCancel, WithDeadline, WithTimeout, or WithValue`来创建衍生的Context来替换，当一个COntext被取消，那么它派生的所有的Context也被取消。`WithCancel, WithDeadline, WithTimeout`函数的参数是一个Context(the parent)，并返回一个派生的Context(the child)与一个`CancelFunc`，调用`CancelFunc`会取消child还有其子Context，从parent中移除child的引用，停止所有相关的定时器。调用`CancelFunc`失败会泄漏child还有其子Context，直到parent被取消或者timer定时器触发。The go vet tool checks that CancelFuncs are used on all control-flow paths。`WithCancelCause`函数返回一个`CancelCauseFunc`，带有一个error参数表示取消的原因。使用Context的程序需要遵守几个约定来保持一致性:
- 不要吧Context保存在一个结构体类型中;
- 当作函数的第一个参数传递给函数,通常名字叫做ctx

```go
func DoSomething(ctx context.Context, arg Arg) error {
	// ... use ctx ...
}
```
不要传递nil context，如果你不确定使用哪一种Context，传递context.TODO。只有在跨API的数据传递中需要使用Context Value，Context是并发安全的。主要的函数:
- func Cause: `func Cause(c Context) error`，返回一个error来解释为什么c被取消了，c或者c的parent设置了这个cause，如果c没有被取消则返回nil
- func WithCancel: `func WithCancel(parent Context) (ctx Context, cancel CancelFunc)`，返回一个parent的副本，副本中有一个新的Done通道，当`CancelFunc`被调用时或者parent的Done通道被关闭，Done通道被关闭。取消Context，释放跟它有关的资源，只要在这个Context中运行的操作完成，代码应该调用cancle。下面是示例代码:
  下面的代码演示了使用Context的取消机制来防止gorotuine泄漏。
  ```go
  package main

    import (
	    "context"
	    "fmt"
    )

    func main() {
	// gen generates integers in a separate goroutine and
	// sends them to the returned channel.
	// The callers of gen need to cancel the context once
	// they are done consuming generated integers not to leak
	// the internal goroutine started by gen.
	gen := func(ctx context.Context) <-chan int {
		dst := make(chan int)
		n := 1
		go func() {
			for {
				select {
				case <-ctx.Done():
					return // returning not to leak the goroutine
				case dst <- n:
					n++
				}
			}
		}()
		return dst
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel() // cancel when we are finished consuming integers

	for n := range gen(ctx) {
		fmt.Println(n)
		if n == 5 {
			break
		}
	}
    }
  ```
- func WithCancelCause: `func WithCancelCause(parent Context)(ctx Context, cancel CancelCuaseFunc)`，`CancelCuaseFunc`类似WithCancel，但是返回`CancelCauseFunc`而不是`CancelFunc`，调用时使用一个error，表示context中的错误，随后可以通过Cause(ctx)来检索这个error。
- func WithDeadline: `func WithDeadline(parent Context, d time.Time) (Context, CancelFunc)`，