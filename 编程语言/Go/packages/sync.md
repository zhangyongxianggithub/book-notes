sync包提供基本的同步原语比如互斥锁。除了Once和WaitGroup类型之外，大多数类型都供低级库例程使用。通过通道和通信可以更好地实现更高级别的同步。
# Types
## type WaitGroup
```go
type WaitGroup struct {
	// contains filtered or unexported fields
}
```
一个WaitGroup等待一组协程运行结束。主协程调用Add方法来设置要等待的协程数量。每个协程运行结束后调用Done方法表示自己已经结束。同时，Wait操作会阻塞直到所有的协程结束。