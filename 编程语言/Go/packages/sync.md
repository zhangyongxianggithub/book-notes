sync包提供基本的同步原语比如互斥锁。除了Once和WaitGroup类型之外，大多数类型都供低级库例程使用。通过通道和通信可以更好地实现更高级别的同步。
# Types
## type WaitGroup
```go
type WaitGroup struct {
	// contains filtered or unexported fields
}
```
一个WaitGroup等待一组协程运行结束。主协程调用Add方法来设置要等待的协程数量。每个协程运行结束后调用Done方法表示自己已经结束。同时，Wait操作会阻塞直到所有的协程结束。WaitGroup在第一次使用后不能被copy。在Go的内存模型的术语中，对Done的调用总是发生在Wait调用解除阻塞之前。
- `func (*WaitGroup)Add`，对WaitGroup的计数器做加减操作，如果计数器变为0，在wait调用上阻塞的所有的协程都会接触阻塞的状态。如果计数器变为负数，那么方法会panic。对计数器=0的WaitGroup做add操作一定要在调用Wait之前，如果计数器>0，则做add操作可以在任何时候，可以发生在Wait调用之后。通常，这意味着对Add的调用应该在创建goroutine或其他要等待的事件的语句之前执行。如果重复使用WaitGroup来等待多个独立的事件集，则必须在所有先前的Wait调用返回后发生新的Add调用。 请参阅WaitGroup示例;
- `func (*WaitGroup)Done`，Done将计数器-1
- `func (*WaitGroup)Wait`，阻塞直到计数器=0

```go
package main

import (
	"sync"
)

type httpPkg struct{}

func (httpPkg) Get(url string) {}

var http httpPkg

func main() {
	var wg sync.WaitGroup
	var urls = []string{
		"http://www.golang.org/",
		"http://www.google.com/",
		"http://www.example.com/",
	}
	for _, url := range urls {
		// Increment the WaitGroup counter.
		wg.Add(1)
		// Launch a goroutine to fetch the URL.
		go func(url string) {
			// Decrement the counter when the goroutine completes.
			defer wg.Done()
			// Fetch the URL.
			http.Get(url)
		}(url)
	}
	// Wait for all HTTP fetches to complete.
	wg.Wait()
}
```
## type Cond
```go
type Cond struct {
	// L is held while observing or changing the condition
	L Locker
	// contains filtered or unexported fields
}
```
Cond实现了condition变量，等待或宣布事件发生的goroutine的集合点。每个Cond都有一个关联的Locker L(通常是*Mutex或*RWMutex)，在改变条件和调用Wait方法时必须保持它。