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
- func WithDeadline: `func WithDeadline(parent Context, d time.Time) (Context, CancelFunc)`，这个函数返回parent context的一个副本，这个副本带有一个deadline，且这个deadline不超过时间d，如果parent的deadline早于d，那么这个函数返回的context与parent就是等价的。当deadline过期、调用了返回的取消函数或者parent的Done通道被关闭时context的Done通道关闭。取消这个context会释放与其相关的资源，例子如下:
  ```go
  func main() {
	d := time.Now().Add(shortDuration)
	ctx, cancel := context.WithDeadline(context.Background(), d)

	// Even though ctx will be expired, it is good practice to call its
	// cancellation function in any case. Failure to do so may keep the
	// context and its parent alive longer than necessary.
	defer cancel()

	select {
	case <-time.After(1 * time.Second):
		fmt.Println("overslept")
	case <-ctx.Done():
		fmt.Println(ctx.Err())
	}
	}
  ```
- func WithTimeout: `func WithTimeout(parent Context, timeout time.Duration)(Context, CancelFunc)`，这个方法返回`WithDeadline(parent, time.Now().Add(timeout))`，取消这个Context会释放与其相关的资源，只要与这个Context相关的操作完成，就应该调用cancel方法.
  ```go
  func slowOperationWithTimeout(ctx context.Context) (Result, error) {
	ctx, cancel := context.WithTimeout(ctx, 100*time.Millisecond)
	defer cancel()  // releases resources if slowOperation completes before timeout elapses
	return slowOperation(ctx)
  }
  ```
  下面是一个例子:
  ```go
  func main() {
	// Pass a context with a timeout to tell a blocking function that it
	// should abandon its work after the timeout elapses.
	ctx, cancel := context.WithTimeout(context.Background(), shortDuration1)
	defer cancel()

	select {
	case <-time.After(10 * time.Second):
		fmt.Println("overslept")
	case <-ctx.Done():
		fmt.Println(ctx.Err()) // prints "context deadline exceeded"
	}
	}
  ```
定义的主要的Types
- type CancelCauseFunc，`type CancelCauseFunc func(cause error)`，`CancelCauseFunc`函数的表现类似一个`CancelFunc`但是额外设置了取消原因，这个原因可以通过调用Cause函数来获取，如果context早已经被取消，`CancelCauseFunc`没有设置原因，比如，如果childContext派生自parentContext:
  - 如果在使用Cause2取消childContext之前使用Cause1取消ParentContext，则Cause(parentContext)==Cause(childContext)==Cause1;
  - 如果在使用Cause1取消parentContext之前使用Cause2取消childContext，则Cause(parentContext) == Cause1且Cause(childContext) == Cause2
- type CancelFunc，`type CancelFunc func()`，一个CancelFunc告诉一个操作放弃后续的工作，CancelFunc不会等待工作停止。CancelFunc可能会被多个携程同时调用。在第一次调用后，后续的调用什么也不做。
- type Context
  ```go
  type Context interface {
	// Deadline returns the time when work done on behalf of this context
	// should be canceled. Deadline returns ok==false when no deadline is
	// set. Successive calls to Deadline return the same results.
	Deadline() (deadline time.Time, ok bool)

	// Done returns a channel that's closed when work done on behalf of this
	// context should be canceled. Done may return nil if this context can
	// never be canceled. Successive calls to Done return the same value.
	// The close of the Done channel may happen asynchronously,
	// after the cancel function returns.
	//
	// WithCancel arranges for Done to be closed when cancel is called;
	// WithDeadline arranges for Done to be closed when the deadline
	// expires; WithTimeout arranges for Done to be closed when the timeout
	// elapses.
	//
	// Done is provided for use in select statements:
	//
	//  // Stream generates values with DoSomething and sends them to out
	//  // until DoSomething returns an error or ctx.Done is closed.
	//  func Stream(ctx context.Context, out chan<- Value) error {
	//  	for {
	//  		v, err := DoSomething(ctx)
	//  		if err != nil {
	//  			return err
	//  		}
	//  		select {
	//  		case <-ctx.Done():
	//  			return ctx.Err()
	//  		case out <- v:
	//  		}
	//  	}
	//  }
	//
	// See https://blog.golang.org/pipelines for more examples of how to use
	// a Done channel for cancellation.
	Done() <-chan struct{}

	// If Done is not yet closed, Err returns nil.
	// If Done is closed, Err returns a non-nil error explaining why:
	// Canceled if the context was canceled
	// or DeadlineExceeded if the context's deadline passed.
	// After Err returns a non-nil error, successive calls to Err return the same error.
	Err() error

	// Value returns the value associated with this context for key, or nil
	// if no value is associated with key. Successive calls to Value with
	// the same key returns the same result.
	//
	// Use context values only for request-scoped data that transits
	// processes and API boundaries, not for passing optional parameters to
	// functions.
	//
	// A key identifies a specific value in a Context. Functions that wish
	// to store values in Context typically allocate a key in a global
	// variable then use that key as the argument to context.WithValue and
	// Context.Value. A key can be any type that supports equality;
	// packages should define keys as an unexported type to avoid
	// collisions.
	//
	// Packages that define a Context key should provide type-safe accessors
	// for the values stored using that key:
	//
	// 	// Package user defines a User type that's stored in Contexts.
	// 	package user
	//
	// 	import "context"
	//
	// 	// User is the type of value stored in the Contexts.
	// 	type User struct {...}
	//
	// 	// key is an unexported type for keys defined in this package.
	// 	// This prevents collisions with keys defined in other packages.
	// 	type key int
	//
	// 	// userKey is the key for user.User values in Contexts. It is
	// 	// unexported; clients use user.NewContext and user.FromContext
	// 	// instead of using this key directly.
	// 	var userKey key
	//
	// 	// NewContext returns a new Context that carries value u.
	// 	func NewContext(ctx context.Context, u *User) context.Context {
	// 		return context.WithValue(ctx, userKey, u)
	// 	}
	//
	// 	// FromContext returns the User value stored in ctx, if any.
	// 	func FromContext(ctx context.Context) (*User, bool) {
	// 		u, ok := ctx.Value(userKey).(*User)
	// 		return u, ok
	// 	}
	Value(key any) any
	}
  ```
  一个Context携带了deadline、取消信号，还有其他值。
- func Backgroud,`func Backgroud() Context`，返回一个non-nil的空Context，永远不会被取消，没有值也没有deadline。它通常由主函数、初始化和测试使用，并作为传入请求的顶级上下文。
- func TODO, `func TODO() Context`，TODO 返回一个非零的空上下文。 当不清楚要使用哪个 Context 或它尚不可用时（因为周围的函数尚未扩展为接受 Context 参数），代码应使用 context.TODO。
- func WithValue，`func WithValue(parent Context, key, val any) Context`，WithValue返回parent的副本，其中包含与key关联的val。仅将Context用于传输跨processes和API的请求范围数据，而不是用于传递可选参数给函数。提供的键必须是可比较的，并且不应是字符串类型或任何其他内置类型，以避免使用上下文的包之间发生冲突。 WithValue的用户应该定义自己的键类型。为了避免在赋值为空接口时时进行内存分配，上下文键通常具有具体类型struct{}。或者，导出的上下文键变量的静态类型应该是指针或接口。
  
  