# 程序结构
Go语言中的大程序都从小的基本组件构建而来: 变量存储值，简单表达式通过加/减等操作合并成大的，基本类型通过数组和结构体进行聚合，表达式通过if/for等控制语句来决定执行顺序，语句被组织成函数用于隔离和复用，函数被组织成源文件和包。
## 名称
字母下划线开头，其他字母数字下划线， 区分大小写。关键子不能用于名称，名字声明在函数内，函数有效，声明在函数外，包有效，名字第一个字母大写代表可以跨包访问也就是导出的，可以被包之外的其他程序引用，名称的作用域越大，越使用长且有意义的名字。名称是驼峰的。
## 声明
声明4种:
- 变量 var
- 常量 const
- 类型 type
- 函数 func

声明不区分顺序
```go
package main
// 输出水的沸点
import (
	"fmt"
)
const boilingF = 212.0
func main() {
	var f = boilingF
	var c = (f - 32) * 5 / 9
	fmt.Printf("boiling point = %gF or %gC\n", f, c)
}
```
## 变量
变量声明的通用形式: `var name type = expression`, 类型或者表达式可以省略之一。表达式省略，初始化为对应类型的0值或者nil。Go中不存在未初始化的变量。可以声明变量列表:
```go
var i, j, k int  // int, int, int
var b, t, s=true, 2. 3，"four"  // bool, f1oat64，string
```
包级别初始化在main开始前进行。可以通过调用返回多个值的函数进行初始化
```go
var f, err = os.Open(name) // os.open 返回一个文件和一个错误
```
短变量声明可以用来声明或者初始化局部变量：`name := expression`.
变量时存储值的地方，指针是一个变量的地址。可以间接读取或者更新变量的值。&是取地址运算符，*是取值运算符。指针是可以比较的。
```go
× := 1
p : =&x
11 p 是整型指针，指向x
fmt.Printin(*p) 1/ "1"
*p= 2
1/ 等于x = 2
fmt.Println(x)// 结果“2"
```
函数返回局部变量的地址是不安全的:
```go
var p=f()
func f() *int { V=: 1
return &v 
}
```
使用new函数创建变量，new(T)创建一个未命名的T类型变量。初始化为T类型的0值返回其地址。
```go
p:=new(int) // int类型的p，指向未命名的int变量
fmt.Println(*p) // 输出"0"
*p=2 // 把未命名的int设置为2
fmt.Println(*p) // 输出“2"
```
生命周期，程序执行过程中变量存在的时间段。包级别变量的生命周期是整个程序，局部变量是函数或者块。编译器自行选择使用堆或者栈上的空间来分配变量内存。可以从函数中逃逸的变量都会使用堆来分配，否则使用栈分配。
## 赋值
赋值语句用来更新变量所指的值。只由简单的赋值运算符组成。
## 类型声明
变量或者表达式的类型定义值应有的特性。大小、内部表示、具有的操作/方法。type声明定义新的命名类型。`type name underlying-type`，通常出现在包级别中。
```go
package tempconv

import (
	"fmt"
)

type Celsius float64
type Fahrenheit float64

const (
	AbsoluteZeroC Celsius = -273.15
	FreezingC     Celsius = 0
	BoilingC      Celsius = 100
)

func CToF(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}
func FToC(f Fahrenheit) Celsius {
	return Celsius((f - 32) * 5 / 9)
}
```
对于每个类型T，都有一个对应的类型转换操作T(x)将值x转换为类型T。如果类型具有相同的底层类型，则2者可以相互转换。类型转换不改变值的表达方式，只改变类型。命名类型的底层类型决定结构与表达方式海域支持的操作/方法。命名类型主要为结构体类型提供便利。
## 包和文件
在Go语言中，包与其他语言中的库/模块类似。支持模块化、疯转、编译隔离和重用。包声明了独立的命名空间。导出的标识符已大写字母开头。文件的开头用package声明定义包的名称，package声明前面是文档注释，对整个包描述。在开头用一句话对包总结性描述，一个包只有一个文件包含文档注释，扩展的文档注释通常放在doc.go文件中。每个包通过导入路径(唯一字符串)来标识。导入声明给导入的包绑定一个短名字。包的初始化从初始化包级别的变量开始，变量按照声明顺序初始化，如果包由多个go文件组成，按照编译器收到的文件的顺序进行。对于包级别的每一个变量，生命周期从值初始化开始，另外的复杂的变量需要使用init函数。
## 作用域
声明将名字合程序实体关联起来，作用域是指用到声明时所声明名字的源代码段。与声明周期是不同的。作用域是区域，是空间，声明周期是时间的概念。
# 基本数据
计算机底层全是位，实际操作是基于大小固定的单元中的数值，称为字(word)。这些值可以解释为整数、浮点数、位集(bitset)或内存地址等。构成更大的聚合体，表示数据包、像素、文件等。Go数据类型分为4大类:
- 基础类型(basic type),数字、字符串合布尔
- 聚合类型(aggregate type)，数组和结构体
- 引用类型(reference type)，指针、slice、map、函数、channel，全部间接指向程序变量或者状态。
- 接口类型(interface type)
## 整数
不同大小的整数、浮点数与复数。
有符号整数: int8\int16\int32\int64
无符号整数: uint8\uint16\uint32\uint64
rune=int32，代表Unicode码点(code point)，byte=uint8，uintptr表示指针。整数支持算术、逻辑、比较、位等运算。
## 浮点数
Go浮点数只有2个float32/float64，float32的有效位数是6位，float64大约是15位，优先使用float64，float32经过运算后的累积误差会比较大。
## 复数
complex64/complex128，complex函数根据给定的实部与虚部创建复数，内置的real/imag函数分别提取复数的实部合虚步。
## 布尔值
真/假，
## 字符串
字符串事不可变的字节序列，可以包含任意数据。`len()`返回字节数，下标访问`s[i]`取得对应位置的字符。支持范围访问。支持+运算符拼接字符串。字符串因为不可变，共用底层存储，基本不需要额外的内存开销。可以通过UTF-8码点转义定义字符串。4个字符串操作的重要的标准包:
- bytes: 用于操作字节slice(byte[]类型，某些属性与字符串一样)，使用bytes.Buffer构建字符串性能更好;
- strings: 搜索、替换、比较、修整、切分与连接字符串;
- strconv: 用于将其他类型转换为字符串，或者将字符串转换为其他类型;
- unicode: 判断字符串特性的函数包，比如是否是数字，大写的还是小写的;

## 常量
编译阶段就计算出表达式的值，常量都是基本类型。比如`const pi=3.14159`，常量可以指定或者不指定类型，，可以通过值推断。常量的声明使用常量生成器`iota`, 它创建一系列相关值，从0开始每次+1。
# 复合数据类型
复合数据类型是由基本数据类型以各种方式组合而构成。有4种:
- 数组
- slice
- map
- 结构体
数组合结构体都是聚合类型，他们的值由内存中的一组变量构成，数组的元素具有相同的类型，结构体中的元素数据类型可以不同。数组合结构体的长度固定，slice/map事动态数据结构。
## 数组
数组是具有固定长度且拥有0+个相同数据类型元素的序列。一般使用slice（ArrayList）比较多。数组中的元素通过索引访问。
```go
package main

import (
	"fmt"
)

func main() {
	var a [3]int             // 声明3个整数的数组
	fmt.Println(a[0])        // 输出数组的第一个元素
	fmt.Println(a[len(a)-1]) // 输出数组的最后一个元素
	for i, v := range a {
		fmt.Printf("%d, %d\n", i, v)
	}

	for _, v := range a {
		fmt.Printf("%d\n", v)
	}

	var q = [3]int{1, 2, 3}// 通过字面量初始化数组
	fmt.Println(q[2])
	t := [...]int{1, 2, 3} // ...这种方式通过初始化的值决定数组的长度
	fmt.Println(t)
	fmt.Println(symbol)
}
```
数组的长度是数组类型的一部分。也可以像map/结构体那样初始化
```go
type Currency int
const (
	USD Currency = iota
	EUR
	GBP
	RMB
)
var symbol = [...]string{USD: "$", EUR: "e", GBP: "r", RMB: "¥"}
```
数组是可以比较的。数组是传值的，可以通过指针传地址。
```go
func zero(ptr *[32]byte) {
	for i := range ptr {
		ptr[i] = 0
	}
}
```
## slice
可变长度的序列。[]T像是没有长度的数组。数组与slice相关，是一种轻量级的数据结构，可以用来访问数组的部分/全部的元素。这个数组是slice的底层数组。有3个属性:
- 指针,指针指向数组中slice第一个访问的元素。
- 长度,slice元素个数`len()`返回个数
- 容量,容量,`cap()`返回容量
s[i:j]返回范围内的一个slice，slice是一个指针。
```go
func reverse(s []int) {
	for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
		s[i], s[j] = s[j], s[i]
	}
}
```
slice就是没有长度的数组，本身看定义类型也是这样的。slice不能做比较。内置函数make可以创建具有指定元素类型、长度、容量的slice。
```go
make([]T,len)
make([]T,len,cap)
```
内置函数append用于追加元素。
```go
func appendInt(x []int, y int) []int {
	var z []int
	zlen := len(x) + 1
	if zlen <= cap(x) {
		z = x[:zlen]
	} else {
		zcap := zlen
		if zcap < 2*len(x) {
			zcap = 2 * len(x)
		}
		z = make([]int, zlen, zcap)
		copy(z, x)
	}
	z[len(x)] = y
	return z

}
```
## map
拥有键值对元素的无序集合。map是散列表的引用，定义方式:
```go
map[k]v
```
键的数据类型必须是可以通过==来比较的类型;内置函数make用来创建map
```go
ages:=make(map[string]int)
```
也可以用字面量来创建:
```go
ages:=map[string]int{
	"alice": 31,
	"charlie": 34,
}
```
delete用于删除键。可以使用range来遍历map，这种遍历是无序的。map操作可以在map=nil的时候安全的执行。

## 结构体
结构体是将0个或者多个任意类型的命名变量组合在一起的聚合数据类型。每个变量都叫做结构体的成员。下面定义一个结构体:
```go
type Employee struct {
	ID int
	Name string
	Address string
	DoB time.Time
	Position string
	salary int
	ManagerID   int
}
var dilbert Employee
```
成员都通过.号来访问。可以获取成员变量的地址。可以获取成员变量的地址，通过指针来访问:
```go
position:=&dilbert.Position
*position="Senior "+*position 
```
结构体指针也使用.号来访问成员
```go
var employeeOfTheMonth *Employee =&dilbert
employeeOfTheMonth.Position += "(proactive team player)"
```
结构体的成员变量名称首字母大些，则是可导出的。结构体不能内嵌它自己，可以内嵌它自己的指针类型。结构体的零值由成员的零值组成。结构体类型的值可以通过结构体字面量来设置:
```go
type Point struct{X, Y int}
p:=Point{1, 2}
```
也可以指定部分或者全部成员变量的名称和值的方式来初始化结构体变量。
```go
anim:=gif.GIF{LoopCount: nframes}
```
不可导出变量无法在其他包中使用。
```go
package p
type T struct{a,b int }//a和b都是不可导出的
package q
import "p"
var _ = p.T{a:1,b:2} //编译错误，无法引用a、b
var _ = p.T{1, 2} //编译错误，无法引用a、b
```
结构体类型的值可以作为参数传递给函数或者作为函数的返回值。
```go
func Scale(p Point, factor int) Point{
	return Point{p.X * factor, p.Y * factor}
}
fmt.Println(Scale(Point{1,2}, 5)) // {5,10}
```
出于效率的考虑，大型的结构体通常都是用结构体指针的方式直接传递给函数或者从函数中返回。
```go
func Bonus(e *Employee, percent int)int{
	return e.Salary * percent / 100
}
```
如果结构体的所有成员变量都可以比较，那么结构体也是可以比较的。结构体可以匿名嵌套。
## JSON
## 文本和HTML模板
# 函数
函数包含连续的执行语句，可以在代码中通过调用函数来执行它们。函数可以将一个复杂的工作切分成多个更小的模块。函数对使用者隐藏了实现细节。
## 函数声明
每个函数都包含一个名字、一个形参列表、一个壳可选的返回列表以及函数体:
```go
func name(parameter-list)(result-list){
	body
}
```
函数的类型称作函数签名，函数签名是形参类型列表与返回类型列表。
## 递归
函数可以递归调用，函数可以直接或者间接的调用自己，可以处理许多带有递归特性的数据结构。
## 多返回值
函数可以返回多个结果。
## 错误
如果函数调用了发生错误时返回一个附加的结果做为错误值，习惯上将错误值作为最后一个结果返回。如果错误只有一种情况，结果通常设置为布尔类型，对于错误原因很多种的情况，调用者需要一些详细的信息，此时，错误的结果类型是error。error是内置的接口类型。一般一个函数返回一个非空错误时，它其他的结果都是未定义的而且应该忽略，有时候可能会返回部分有用的结果。
## 函数变量
函数在Go语言中是头等重要的值，函数变量也有类型，而且可以赋给变量或者传递或者从其他函数中返回。函数变量可以像其他函数一样调用。比如:
```go
func square(n int) int { return n * n}
func negative(n int) int { return -n }
func product( m,n int) int { return m * n }
f := square
fmt.Println(f(3)) // "9"
f = negative
fmt.Println(f(3)) // "-3"
fmt.Printf("%T\n", f) // "func(int) int"
f = product // 编译错误，不能把类型func(int ,int) int 赋给func(int)int
```
函数类型的零值是nil，调用一个空的函数变量导致宕机。
## 匿名函数
命名函数只能在包级别的作用域进行声明，可以使用函数字面量在任何表达式内指定函数变量，函数字面量就像函数声明，func后面没有函数名，它是一个表达式，称为匿名函数。
## 变长函数
函数有可变的参数个数，vals ...int这种形式
## 延迟函数调用
defer机制，defer语句就是一个普通的函数或者方法调用，类似于Java中的finaly语句，必然执行。常用于成对的操作，比如打开/关闭，连接/断开，枷锁/解锁等。
## 宕机
运行时发生错误，就会宕机，比如数组越界或者解引用空指针。
## 恢复
# 方法
对象在Go的理解: 对象就是拥有方法的简单的一个值或者变量。而方法是某种特定类型的函数。面向对象编程就是使用方法来描述每个数据结构的属性和操作，使用者不需要了解对象本身的实现。基于面向对象的编程思想，定义和使用方法，2个原则就是封装和组合。
## 方法声明
方法的声明和普通函数的声明类似，只是在函数名字前面多了一个参数。这个参数把这个方法绑定到这个参数对应的类型上。
## 指针接收者的方法
## 通过结构体内嵌组成类型
## 方法变量与表达式
## 示例: 位向量
## 封装
# 接口
接口类型是对其他类型行为的概括与抽象。通过使用接口，可以写出更加灵活和通用的函数，这些函数不用绑在一个特定的类型实现上。Go的接口实现是隐式实现，对于一个具体的类型，无须声明它实现了哪些接口，只要提供接口所需要的方法。
## 接口既约定
具体类型，
# goroutine和通道
# 使用共享变量实现并发
# 包和go工具
通过包来复用函数，Go自带100多个基础包，配套的Go工具功能强大。
## 引言
任何包管理系统的的目的都是通过对关联的特性进行分类，组织成便于理解与修改的单元，使其与程序的其他包保持独立，有助于设计和维护大型程序，模块化允许包在不同的项目中共享、复用。包的名字就是命名空间，每个名字都在包下也可以说在一个命名空间下。包通过控制名字是否导出使其对包外可见来提供封装能力，限制包成员的可见性，隐藏API后面的辅助函数和类型，允许包的维护者修改包的实现而不影响包外部的代码。限制变量的可见性也可以隐藏变量，使用者仅可以通过导出函数来对其访问和更新。
## 导入路径
每个包都通过一个唯一的字符串进行标识，称为导入路径，用在import声明中:
```go
import (
	"fmt"
	"math/rand"
	"golang.org/x/net/html"
	"github.com/go-sql-driver/mysql"
)
```
对于共享或者公开的包，导入路径需要全局唯一，包的包入路径应该以域名开始。比如上面的github的包。
## 包的声明
在每一个Go源文件的开头都要声明包，主要的目的是当该包被其他包引入的时候作为默认的标识符也就是包名。包名是导入路径的最后一段，可执行命令所在的包也就是入口包固定为main。
## 导入声明
package声明后面可以声明0个或者多个import声明，每个导入可以单独指定一条导入路径，也可以通过圆括号括起来的列表一次导入多个包。如果需要把2个名字一样的包导入到第三个包中，导入声明必须至少为其中的一个指定替代名字来避免冲突。这叫做重命名导入。
```go
import (
	"crypto/rand"
	mrand "math/rand" //通过指定一个不同的名字mrand就避免了冲突
)
```
## 空导入
如果导入的包的名字没有在文件中使用，会产生一个编译错误，但是有时候需要导入一个包，这个包用来执行包级别的变量初始化求值，并执行它的init函数，为了防止报错，必须使用_空白符来重命名导入，标识导入的内容为空白标识符，
```go
import _ "image/png"
```
这叫做空白导入。用来实现一种编译时的机制。一个例子程序如下:
```go
package main

import (
	"fmt"
	"image"
	"image/jpeg"
	_ "image/png" // 注册PNG解码器
	"io"
	"os"
)

func main() {
	if err := toJPEG(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "jpeg: %v\n", err)
		os.Exit(1)
	}
}
func toJPEG(in io.Reader, out io.Writer) error {
	img, kind, err := image.Decode(in)
	if err != nil {
		return err
	}
	fmt.Fprintln(os.Stderr, "Input format = ", kind)
	return jpeg.Encode(out, img, &jpeg.Options{Quality: 95})
}
```
##  包及其命名
创建一个包时，使用简短的名字保持可读性与无歧义。通常使用统一的形式，比如如果关键字冲突，使用复数形式。通常的名字格式[领域名+抽象的操作分类名]。
## go工具
Go工具主要用来下载、查询、格式化、构建、测试以及安装Go代码包。go有很多的子命令，通过`go help`来查看内置文档。
1. 工作空间的组织
   必须配置GOPATH环境变量，工作空间的根，GOPATH有3个子目录，src子目录包含源文件，每个包放在一个目录中，目录就是包的导入路径，pkg子目录是构建工具存储编译后的包的位置，bin子目录放置可执行程序。GOROOT环境变量类似GOPATH，但是是GO标准库包的位置。go env输出环境变量，GOOS指定目标操作系统，GOARCH指定目标处理器架构。
2. 包的下载
   包的导入路径是包在本地的位置也是在互联网上的位置，go get也会下载包的关联依赖，完成下载后，构建、安装库或者相应的命令，go get创建的目录是远程仓库的真实客户端。包导入路径中的golang.org不同于Git服务器的实际域名，这是因为对于github.com这样的服务，可以使用自定义域名，只要在获取资源的地址上放上源数据，也就是真实的代码地址，go工具会识别并自动重定向，这也实现了导入路径自定义。使用-u开关更新所有关联依赖包，不开启优先优先本地。如果需要精确的控制版本，请使用vendor目录。
3. 包的构建
   go build命令编译每一个命令行参数中的包，如果包的名字是main，go build调用链接器在当前目录中创建可执行程序，可执行程序的名字取自包的导入路径的最后一段。
# 测试
# 反射
# 低级编程