[TOC]
- [程序结构](#程序结构)
	- [名称](#名称)
	- [声明v](#声明v)
	- [变量](#变量)
	- [赋值](#赋值)
	- [流程控制](#流程控制)
		- [if](#if)
		- [switch](#switch)
		- [select](#select)
		- [for](#for)
		- [range](#range)
		- [goto/break/continue](#gotobreakcontinue)
	- [类型声明](#类型声明)
	- [包和文件](#包和文件)
	- [作用域](#作用域)
- [基本数据](#基本数据)
	- [整数](#整数)
	- [浮点数](#浮点数)
	- [复数](#复数)
	- [布尔值](#布尔值)
	- [字符串](#字符串)
	- [常量](#常量)
- [复合数据类型](#复合数据类型)
	- [数组](#数组)
	- [slice](#slice)
	- [map](#map)
	- [结构体](#结构体)
	- [JSON](#json)
	- [文本和HTML模板](#文本和html模板)
- [函数](#函数)
	- [函数声明](#函数声明)
	- [递归](#递归)
	- [多返回值](#多返回值)
	- [错误](#错误)
	- [函数变量](#函数变量)
	- [匿名函数](#匿名函数)
	- [变长函数](#变长函数)
	- [延迟函数调用](#延迟函数调用)
	- [宕机](#宕机)
	- [恢复](#恢复)
- [方法](#方法)
	- [方法声明](#方法声明)
	- [指针接收者的方法](#指针接收者的方法)
	- [通过结构体内嵌组成类型](#通过结构体内嵌组成类型)
	- [方法变量与表达式](#方法变量与表达式)
	- [示例: 位向量](#示例-位向量)
	- [封装](#封装)
- [接口](#接口)
	- [接口既约定](#接口既约定)
	- [接口类型](#接口类型)
	- [实现接口](#实现接口)
	- [使用flag.Value来解析参数](#使用flagvalue来解析参数)
	- [接口值](#接口值)
	- [error接口](#error接口)
	- [类型断言](#类型断言)
	- [使用类型断言来识别错误](#使用类型断言来识别错误)
	- [通过接口类型断言来查询特性](#通过接口类型断言来查询特性)
	- [类型分支](#类型分支)
	- [示例: 基于标记的XML解析](#示例-基于标记的xml解析)
	- [一些建议](#一些建议)
- [goroutine和通道](#goroutine和通道)
	- [goroutine](#goroutine)
	- [示例: 并发时钟服务器](#示例-并发时钟服务器)
	- [示例: 并发回声服务器](#示例-并发回声服务器)
	- [通道](#通道)
	- [并行循环](#并行循环)
	- [示例: 并发的Web爬虫](#示例-并发的web爬虫)
	- [使用select多路复用](#使用select多路复用)
	- [示例: 并发目录遍历](#示例-并发目录遍历)
	- [取消](#取消)
	- [示例: 聊天服务器](#示例-聊天服务器)
- [使用共享变量实现并发](#使用共享变量实现并发)
	- [竟态](#竟态)
	- [互斥锁: sync.Mutex](#互斥锁-syncmutex)
	- [读写互斥锁: sync.RWMutex](#读写互斥锁-syncrwmutex)
	- [内存同步](#内存同步)
	- [延迟初始化: sync.Once](#延迟初始化-synconce)
	- [竟态检测器](#竟态检测器)
	- [示例: 并发非阻塞缓存](#示例-并发非阻塞缓存)
	- [goroutine与线程](#goroutine与线程)
- [包和go工具](#包和go工具)
	- [包简介](#包简介)
	- [导入路径](#导入路径)
	- [包的声明](#包的声明)
	- [导入声明](#导入声明)
	- [空导入](#空导入)
	- [包及其命名](#包及其命名)
	- [go工具](#go工具)
- [package \& module](#package--module)
- [go工具](#go工具-1)
	- [go env](#go-env)
- [测试](#测试)
	- [go test工具](#go-test工具)
	- [Test函数](#test函数)
	- [Example函数](#example函数)
- [反射](#反射)
	- [为什么使用反射](#为什么使用反射)
	- [reflect.Type和reflect.Value](#reflecttype和reflectvalue)
	- [Display: 一个递归的值显示器](#display-一个递归的值显示器)
	- [访问结构体字段标签](#访问结构体字段标签)
- [低级编程](#低级编程)
- [go Context](#go-context)
- [viper](#viper)
	- [viper是什么?](#viper是什么)
	- [把值存入Viper](#把值存入viper)
	- [从Viper获取值](#从viper获取值)
- [gin](#gin)
- [gorm](#gorm)

# 程序结构
Go语言中的大程序都从小的基本组件构建而来: 变量存储值，简单表达式通过加/减等操作合并成大的，基本类型通过数组和结构体进行聚合，表达式通过if/for等控制语句来决定执行顺序，语句被组织成函数用于隔离和复用，函数被组织成源文件和包。
## 名称
字母下划线开头，其他字母数字下划线， 区分大小写。关键字不能用于名称，名字声明在函数内，函数有效，声明在函数外，包有效，名字第一个字母大写代表可以跨包访问也就是导出的，可以被包之外的其他程序引用，名称的作用域越大，越使用长且有意义的名字。名称是驼峰的。
## 声明v
声明有4种:
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
p := &x // p是整型指针，指向x
fmt.Printin(*p) //  "1"
*p = 2 // 等于x = 2
fmt.Println(x) // 结果“2"
```
函数返回局部变量的地址是不安全的:
```go
var p = f()
func f() *int {
	v := 1
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
## 流程控制
### if
### switch
### select
### for
支持3种循环方式，类似while的语法
```go
    for init; condition; post { }
    for condition { }
    for { }
    init： 一般为赋值表达式，给控制变量赋初值；
    condition： 关系表达式或逻辑表达式，循环控制条件；
    post： 一般为赋值表达式，给控制变量增量或减量。
    for语句执行过程如下：
    ①先对表达式 init 赋初值；
    ②判别赋值表达式 init 是否满足给定 condition 条件，若其值为真，满足循环条件，则执行循环体内语句，然后执行 post，进入第二次循环，再判别 condition；否则判断 condition 的值为假，不满足条件，就终止for循环，执行循环体外语句。
```
### range
类似迭代器操作，返回(索引,值)或者(键,值)。for循环的range格式可以对slice、map、数组、字符串进行迭代循环
```go
for key, value := range oldMap {
    newMap[key] = value
}
```
| ****        | **1st value** | **2nd value** | **元素类型**     |
|-------------|---------------|---------------|--------------|
| string      | index         | s[index]      | unicode,rune |
| array/slice | index         | s[index]      |              |
| map         | key           | map[key]      |              |
| channel     | element       |               |              |


### goto/break/continue
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
在Go语言中，包与其他语言中的库/模块类似。支持模块化、封装、编译隔离和重用。包声明了独立的命名空间。导出的标识符以大写字母开头。文件的开头用package声明定义包的名称，package声明前面是文档注释，对整个包描述。在开头用一句话对包总结性描述，一个包只有一个文件包含文档注释，扩展的文档注释通常放在doc.go文件中。每个包通过导入路径(唯一字符串)来标识。导入声明给导入的包绑定一个短名字。包的初始化从初始化包级别的变量开始，变量按照声明顺序初始化，如果包由多个go文件组成，按照编译器收到的文件的顺序进行。对于包级别的每一个变量，生命周期从值初始化开始，另外的复杂的变量需要使用init函数。任何文件可以包含任意数量的init函数:
```go
func init(){/**/}
```
init函数在程序启动时自动执行，

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
字符串是···不可变的字节序列，可以包含任意数据。`len()`返回字节数，下标访问`s[i]`取得对应位置的字符。支持范围访问。支持+运算符拼接字符串。字符串因为不可变，共用底层存储，基本不需要额外的内存开销。可以通过UTF-8码点转义定义字符串。4个字符串操作的重要的标准包:
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

数组合结构体是聚合类型，他们的值由内存中的一组值构成，数组的元素具有相同的类型，结构体中的元素数据类型可以不同。数组与结构体的长度固定，slice/map是动态数据结构。
## 数组
数组是固定长度且拥有0+相同数据类型元素的序列。一般使用slice(类似于Java中的ArrayList，更多的是类似vavr中的List数据结构)比较多。数组中的元素通过索引访问。
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
		fmt.Printf("%d, %d\n", i, v)//遍历数组
	}

	for _, v := range a {
		fmt.Printf("%d\n", v)//遍历数组
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
可变长度的序列。定义为`[]T`像是没有长度的数组。数组与slice相关，slice是一种轻量级的数据结构，底层是数组。有3个属性:
- 指针, 指针指向数组中slice第一个访问的元素的地址;
- 长度, slice元素个数`len()`返回个数，小于容量;
- 容量, `cap()`返回容量，是slice在数组的起始位置到数组终点的元素个数。

`s[i:j]`返回范围内的一个slice，s是可以是数组、数组指针或者是slice。其中$i$或者$j$都可以忽略，有默认值。slice不能超过被引用对象的容量，但是可以超过长度，也就是不能超过底层数组的长度。
```go
func main() {
	months := [...]string{1: "January", 2: "February", 3: "March", 4: "April", 5: "May", 6: "June", 7: "July",
		8: "August",
		9: "September", 10: "October", 11: "November", 12: "December",
	}
	fmt.Println(months[1:])
	summer := months[6:9]
	Q2 := months[4:7]
	for _, s := range summer {
		for _, q := range Q2 {
			if s == q {
				fmt.Printf("%s appears in both\n", s)
			}
		}
	}
}
```
slice是指针，传递可以直接修改底层数组元素。数组与slice字面量的区别
```go
a := [...]int{1,2,3,4,5}//有...
s := []int{1,2,3,4,5}//没有....
```
slice不能做比较,bytes.Equal可以用于比较字节slice，其他的需要自己写函数比较，但是可以与nil比较，任何类型，如果值可以是nil，则可以使用转换表达式`[]int(nil)`。内置函数make可以创建具有指定元素类型、长度、容量的slice。
```go
make([]T,len) // 容量与长度相同
make([]T,len,cap) //容量与长度不同
```
内置函数append用于追加元素。内置copy函数可以复制2个slice的元素。
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
`delete()`用于删除键。可以使用range来遍历map，这种遍历是无序的。map操作可以在map=nil的时候安全的执行。
## 结构体
结构体是将0+个任意类型的命名变量组合在一起的聚合数据类型。每个变量都叫做结构体的成员。结构体可以复制，传递给函数，作为函数的返回值，作为数组的元素类型，相当于一个独立的类型。下面定义一个结构体:
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
成员都通过.号来访问。结构体本身是变量，成员也是变量。可以获取成员变量的地址。通过指针来访问:
```go
position:=&dilbert.Position
*position="Senior "+*position 
```
结构体指针也使用.号来访问成员
```go
var employeeOfTheMonth *Employee =&dilbert
employeeOfTheMonth.Position += "(proactive team player)"// 等价于(*employeeOfTheMonth).Position += "(proactive team player)"
```
下面的代码:
```go
func EmployeeByID(id int) *Employee {}
fmt.Println(EmployeeByID(dilbert.ManagerID).Position)
EmployeeByID(dilbert.ID).salary=0//如果函数不是返回的指针，而是结构体，代码无法通过编译，赋值表达式的左侧无法识别出是一个变量
```
结构体包括成员变量的顺序，顺序不同也是不同的结构体。结构体的成员变量名称首字母大写是可导出的，也能包括不可导出的成员变量。匿名结构体类型多次写比较复杂，定义命名结构体类型。结构体不能内嵌自己，可以内嵌自己的指针类型。
```go
type tree struct {
    value int
    left, right *tree
}
```
结构体的零值由成员的零值组成。struct{}空结构体类型也就是结构体的零值。结构体类型的值可以通过结构体字面量来设置:
```go
type Point struct{X, Y int}
p:=Point{1, 2}// 结构体字面量
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
出于效率的考虑，**大型的结构体通常都是用结构体指针的方式直接传递给函数或者从函数中返回**。
```go
func Bonus(e *Employee, percent int)int{
	return e.Salary * percent / 100
}
```
如果结构体的所有成员变量都可以比较，那么结构体也是可以比较的。结构体可以匿名嵌套。
```go
type Point struct {
	X,Y int
}
type Circle struct {
	Center Point
	Radius int
}
type Wheel struct {
	Circle Circle
	Spokes int
}
```
上面的代码，访问wheel的成员`wheel.Circle.Center.X`，需要连续的访问成员。使用匿名嵌套，也是里面指定类型不指定名称
```go
type Circle struct {
    Point
	Radius int
}
type Wheel struct {
    Point
	Spokes int
}
```
可以直接访问`wheel.X`，实际上也是有名字的，就是类型的名称。外围结构体类型不仅获得匿名类型的成员，还有它的方法(生成的是代理方法)。有点类似继承。
## JSON
JSON定义发送与接收信息的标准格式，Go内置了对JSON、XML等格式化信息的编解码支持。JSON是数据的高效可读性强的表示方法。JSON的定义与Go的数据类型对应。把Go的数据结构转换为JSON叫做marshal，通过`json.marshal`实现
```go
type Movie struct {
	Title  string
	Year   int  `json:"released"`
	Color  bool `json:"color,omitempty"`
	Actors []string
}

var movies = []Movie{
	{"Casablanca", 1942, false, []string{"Humphrey Bogart", "Ingrid Bergman"}},
}

func main() {
	data, err := json.Marshal(movies)
	if err != nil {
		log.Fatalf("JSON marshaling failed: %s", err)
	}
	fmt.Printf("%s\n", data)
	
}
```
使用成员名作为json字段名，只有可导出的成员可以转换为json字段，成员标签是结构体成员在编译期间关联的元信息。可以是任意字符串。将JSON解码为Go数据结构叫做unmarshal，unmarshal操作忽略大小写，但是go数据必须是大写开头的。代码如下:
```go
	var titles []struct{ Title string }
	if err := json.Unmarshal(data, &titles); err != nil {
		log.Fatalf("JSON unmarshaling failed: %s", err)
	}
	fmt.Println(titles)
```
## 文本和HTML模板
TODO
# 函数
函数包含连续的执行语句，可以通过调用函数来执行它们。函数可以将复杂的工作切分成多个更小的工作，类似分治法。函数对使用者**隐藏**了实现细节。
## 函数声明
每个函数都包含一个名字、一个形参列表、一个壳可选的返回列表以及函数体:
```go
func name(parameter-list)(result-list){
	body
}
```
函数的类型称作函数签名，函数签名是形参类型列表与返回类型列表。
## 递归
函数可以递归调用，函数可以直接或者间接的调用自己，可以处理带有递归特性的数据结构。
## 多返回值
函数可以返回多个结果。返回结果通常是(result, error|ok?),一个错误值或者是一个布尔值都可以。
```go
func findLinks(url string) ([]string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("getting %s:%s", url, resp.Status)
	}
	doc, err := html.Parse(resp.Body)
	resp.Body.Close()
	if err != nil {
		return nil, fmt.Errorf("parsing %s as HTML: %v", url, err)
	}
	return visit(nil, doc), nil
}
```
多返回值可以赋给变量或者直接赋给多参的函数，也可以给返回值命名，此时可以不用写return的操作数这个叫做裸返回。
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
defer机制，defer语句就是一个普通的函数或者方法调用，类似于Java中的finaly语句，必然执行。常用于成对的操作，比如打开/关闭，连接/断开，加锁/解锁等。
## 宕机
运行时发生错误，就会宕机，比如数组越界或者解引用空指针。宕机时留下日志消息，包括宕机的值。可以调用内置的宕机函数手动宕机。`panic()`函数可以手动触发宕机。
## 恢复
退出程序是正确处理宕机的方式，也可以在退出前做清理工作。内置的`recover()`函数用于恢复，在延迟函数内部调用，并且包含defer的函数发生宕机，`recover()`会终止当前的宕机状态并且返回宕机的值，函数不会从之前宕机的地方继续运行而是正常返回，recover在其他情况下运行没有任何效果且返回nil，类似线程中断清除状态等。比如下面的代码:
```go
func Parse(input string)(s *Syntax, err error){
	defer func(){
		if p:=recover(); p!=nil{
			err=fmt.ErrorF("internal error: %v", p)
		}
	}()
}
```
Parse函数中的延迟函数会从宕机状态恢复，并使用宕机值组成一条错误消息，理想的写法是使用runtime.Stack将整个调用栈包含进来，延迟函数将错误赋给err结果变量从而返回给调用者。随意恢复可能会有问题，因为变量的值可能是一种中间状态。一般是不要恢复另一个包的宕机，自己包的宕机可以恢复，通常的做法是使用一个明确的，非导出类型作为宕机值，然后检测recover的返回值是否是这个类型，如果是处理宕机，不是则使用panic继续触发宕机。
```go
func soleTitle(doc *html.Node) (title string, err error) {
	type bailout struct{}
	defer func() {
		switch p := recover(); p {
		case nil://没有宕机
		case bailout{}:
			err := fmt.Errorf("multiple title emlements")
		default:
			panic(p)// 其他类型的宕机，继续宕机
		}
	}()
	// ......
	return "", err
}
```

# 方法
对象在Go的理解: 对象就是拥有方法的简单的一个值或者变量。而方法是某种特定类型的函数。面向对象编程就是使用方法来描述每个数据结构的属性和操作，使用者不需要了解对象本身的实现。基于面向对象的编程思想，定义和使用方法，2个原则就是封装和组合。
## 方法声明
方法的声明和普通函数的声明类似，只是在函数名字前面多了一个参数。这个参数把这个方法绑定到这个参数对应的类型上。
```go
package geometry
import "math"
type Point struct{X,Y float64}
func Distance(p,q Point) float64 {
	return math.Hypot(q.X-p.X, q.Y-p.Y)
}
func (p Point) Distance(q Point) float64 {
	return math.Hypot(q.X-p.X, q.Y-p.Y)
}
```
附加的参数p称为方法的接收者，在面向对象的语境中，表示主调方法就像向对象发送消息。调用的形式:
```go
fmt.Println(p.Distance(q))
```
## 指针接收者的方法
主调函数复制每一个实参变量，函数需要更新一个变量，或者实参太大希望避免复制整个实参，必须使用指针传递变量的地址。接收者也是这样的，需要将方法绑定到指针类型(避免接收者复制)
```go
func (p *Point) ScaleBy(factor float64) {
   p.X *=factor
   p.Y *=factor
}
```
方法的名字是`(*Point).ScaleBy`，没有圆括号，表达式会被解析成*(Point.ScaleBy)。本身是指针的类型不能进行方法声明。下面的用法都合法:
```go
r:=&Point{1, 2}
r.ScaleBy(2)
fmt.Println(*r)

p:=Point{1, 2}
pptr:=&p
pptr.ScaleBy(2)
fmt.Println(p)

q:=&Point{1, 2}
(&q).ScaleBy(2)
fmt.Println(q)
```
也可以直接用变量调用，go编译器会隐式的执行&操作。不能取地址的不能调用方法，比如字面量。
```go
Point{1, 2}.ScaleBy(2)//编译错误，不能获得Point类型字面量的地址
```
通过指针可以调用变量类型的方法:
```go
pptr.Distance(q)// 这是合法的，因为编译器通过解引用指针隐式转换。
(*pptr).Distance(q)
```
nil在类型中是有意义的零值，也是方法的接收者。
## 通过结构体内嵌组成类型
```go
type Point struct{
    X,Y float64
}
type ColoredPoint struct {
    Point
    Color color.RGBA
}
```
前面说匿名嵌套会继承属性与方法，但是有一点特殊
```go
p:=...
q:=...
fmt.Println(p.Distance(q.Point))
```
方法的参数不能直接传递ColoredPoint，虽然看起来是继承，但不是is-a的关系。在Go中实际是生成了Point方法的包装代理方法，只有代理方法是属于ColoredType的，如下:
```go
func (p ColoredType)Distance(q Point) float64{
	return p.Point.Distance(q)
}
```
匿名嵌套也可以嵌套指针效果与命名类型是一样的。
```go
type ColoredPoint struct{
	*Point
	Color color.RGBA
}
p:=ColoredPoint{&Point{1,2},red}
q:=ColoredPoint{&Point{5,4},blue}
fmt.Println(p.Distance(*q.Point))
```
ColoredPoint具有Point/RGBA的所有方法以及自己直接定义的方法，当编译器处理选择子(p.Distance，方法调用)，首先查找直接声明的方法Distance，之后再在内嵌的字段中查找方法，再在内嵌的内嵌的字段中查找。内嵌的机制可以帮助在非命名类型结构体中嵌入方法，因为方法是继承而来的。比如下面的:
```go
var cache =struct {
	sync.Mutex
	mapping map[string]string
}{mapping: make(map[string]stirng)}

func Lookup(key string)string{
	cache.Lock()
	v:=cache.mapping[key]
	cache.Unlock()
	return v
}
```
## 方法变量与表达式
选择子可以赋给一个方法变量，它是一个函数，把方法绑定到一个接收者p上。只需要提供实参而不需要提供接收者
```go
p:=Point{1,2}
q:=Point{4,6}
distanceFromP:=p.Distance // 方法变量
fmt.Println(distanceFromP(q))
```
如果是回调的场景，可以将参数中的函数与方法绑定起来执行回调.
```go
type Rocket struct{}
func (r *Rocket)Launch(){}
r:=new(Rocket)
time.AfterFunc(10 * time.Second, func(){ r.Launch()})// 传统形式
time.AfterFunc(10 * time.Second, r.Launch)//使用方法变量的形式
```
方法表达式，调用方法必须提供接收者按照选择子的语法进行。方法表达式写成T.f或者(*T).f，T是类型是一种函数变量，把原来方法的接收者替换成函数的第一个参数，就可以像普通的函数一样使用
```go
p:=Point{1,2}
q:=Point{4,6}
distanceFromP:=Point.Distance // 方法表达式,直接变成了一个函数
fmt.Println(distanceFromP(p, q))
```
## 示例: 位向量
## 封装
变量或者方法是不能通过对象访问到叫做封装的变量或者方法也叫做数据隐藏。Go语言只有一种方式控制命名的可见性: 是否首字母大写。同样的机制对结构体内的字段和类型中的方法也一样。要封装一个对象，必须使用结构体。Go语言中封装的单元是包而不是类型。不论函数内的代码还是方法内的代码，结构体类型内的字段对于同一个包中的所有代码都是可见的。封装的优点:
- 因为使用方不能直接修改对象的变量，所以不需要更多的语句来检查变量的值;
- 隐藏实现细节可以防止使用方依赖的属性发生改变，使得设计者可以更加灵活地改变API的实现而不破坏兼容性;
- 防止使用者肆意地改变对象内的变量。
# 接口
接口类型是对具体类型行为的概括与抽象。使用接口可以写出灵活和通用的函数，函数不用绑在一个特定的类型实现上。Go的接口实现是隐式实现，对于一个具体的类型，无须声明它实现了哪些接口，只要提供接口所需要的方法。无须修改包内的类型实现代码。
## 接口既约定
具体类型包含数据表示，暴露了基于数据表示的内部操作或者自定义方法。接口类型是一种抽象类型，没有暴露所含数据或者内部结构，它只提供一些方法而已。接口类型的值不能知道具体的类型只能知道它能做什么。接口机制的一个例子`Printf`与`SprintF`.
```go
package fmt
func Fprintf(w io.Writer, format string, args ...interface{})(int,error)//io.Writer是一个接口类型
func Printf(format string, args ...interface{})(int,error){
	return Fprintf(os.Stdout, format,args...)// os.Stdout是一个*os.File类型。
}
func Sprintf(format string, args ...interface{}) string {
	var buf bytes.Buffer
	Fprintf(&buf,format,args...)
	return buf.String()
}
```
```go
package io
type Writer interface{
	// Write从p向底层数据流写入len(p)个字节的数据
	//返回实际写入的字节数，
	Write(p []byte)(n int, err error)
}
```
可以把一种类型替换为满足同一接口的另一种类型的特性称为可取代性(substitutability)，里氏代换。
下面是一个例子:
```go
type ByteCounter int

func (c *ByteCounter) Write(p []byte) (int, error) {
	*c += ByteCounter(len(p))
	return len(p), nil
}
func main() {
	var c ByteCounter
	c.Write([]byte("hello"))
	fmt.Println(c)
	c = 0
	var name = "Dolly"
	fmt.Fprintf(&c, "hello, %s", name)
	fmt.Println(c)

}
```
类型可以控制如何输出自己，只需要定义String方法，这也是一个接口
```go
package fmt
type Stringer interface{
	String() string
}
```
## 接口类型
一个接口类型定义了一套方法，实现接口需要实现接口类型定义的所有方法。
```go
package io
type Reader interface{
	Read(p []byte)(n int, err error)
}
type CLoser interface{
	Close() error
}
```
可以通过组合已有接口来得到新的接口
```go
type ReadWriter interface{
	Reader
	Writer
}
type ReadWriteCloser interface{
	Reader
	Writer
	Closer
}
```
这叫做嵌入式接口，与嵌入式结构类似。
## 实现接口
如果一个类型实现了一个接口要求的所有方法。那么就是实现了这个接口。表达式实现了一个接口时，可以赋值给接口:
```go
var w io.Writer
w=os.Stdout//*os.File有Write方法
w=new(bytes.Buffer)//*bytes.Buffer有write方法
w=time.Second
var rwc io.ReadWriteCloser
rwc=os.Stdout
rwc=new(bytes.Buffer)
```
右侧是接口也行。类型有某一个方法的含义: 对于每个具体类型T，部分方法的接收者就是T，而其他方法的接收者则是*T指针。对类型T的变量直接调用*T的方法也是合法的，编译器隐式的完成了取地址操作。6.5节的IntSet类型的String方法，需要一个指针接收者，无法从一个无地址的IntSet值(字面量)上调用该方法，但是可以在一个变量上调用方法。
```go
type IntSet struct {}
func (*IntSet)String() string
var _=IntSet{}.String()//编译错误
```
因为只有\*IntSet有String方法，所以只有*IntSet实现了fmt.Stringer接口。接口封装了对应的类型和数据，通过接口暴露的方法才可以调用。`interface{}`叫做空接口类型，不包含任何方法，可以把任何值赋给空接口类型。可以使用类型断言来从空接口中还原出实际值。判断是否实现接口只需要比较具体类型和接口类型的方法。下面的声明在编译期就断言了\*byte.Buffer实现了io.Writer接口。
```go
// *bytes.Buffer必然实现io.Writer接口
var w io.Writer=new(bytes.Buffer)
```
甚至不需要新创建变量，*bytes.Buffer的任意值都实现了这个接口，甚至nil，修改的声明如下:
```go
var _ io.Writer=(*bytes.Buffer)nil
```
非空的接口类型通常由指针类型实现，一个指向结构体的指针是最常见的方法接收者。其他引用类型也可以实现接口，比如slice、map、函数类型。一个具体类型可以实现多个不想关的接口，比如销售/管理数字文化商品，可能定义的具体类型Album、Book、Movie...。
每一种抽象用一种接口类型来表示，一些属性是所有商品都具备的:
```go
type Artifact interface{
	Title() string
	Creators() []string
	Created()time.Time
}
```
其他属性也可以建立共同的抽象:
```go
type Text interface{
	Pages() int
	Words() int
	PageSize() int
}
type Audio interface{
	Stream()(io.ReadCloser, error)
	RunningTime() time.Duration
	Fomrat() string// 
}
```
只是把具体类型分组并暴露它们共性的方式。

## 使用flag.Value来解析参数
可以用`-period`命令行标志来控制睡眠时间。命令行标志也支持自定义类型，只需要定义满足`flag.Value`接口的具体类型
```go
package flag
// Value接口代表存储在标志内的值
type Value interface{
	String() string
	Set(string) error
}
```
String方法用于格式化标志对应的值，Set方法解析传入的字符串参数更新标志值。
```go
type clsiusFlag struct {Celsius}
func (f *celsiusFlag)Set(s string)error {
	var unit string
	var value float64
	fmt.Sscanf(s, "%f%s", &value, &unit)
	switch unit {
		case "C","oC":
		f.Celsius=Celsius(value)
		return nil
		case "F","oF":
		f.Celsius=FToC(Fahrenheit(value))
		return nil
	}
	return fmt.Errorf("invalid temperature %q", s)
}
```
## 接口值
接口类型的值有2个部分:
- 具体类型，接口的动态类型
- 该类型的一个值，接口的动态值

这类似与面向对象语言中的多态机制。接口声明会初始化为nil，在nil调用方法执行会会导致宕机。接口值可以指向任意大的动态值。如果接口值都是nil，或者动态类型/动态值都相同，则2个接口值相等。所以可以作为map的键作为switch语句的操作数。动态值可以比较时，接口值才能比较，否则会造成程序崩溃。fmt包中的%T可以打印接口值的动态类型。空的接口值与仅仅动态值是nil的接口值是不一样的。下面的程序:
```go
const debug = true
func main(){
	var buf *bytes.Buffer
	if debug {
		buf=new(bytes.Buffer)//启用输出收集
	}
	f(buf)//微妙的错误
}
func f(out io.Writer){
	if out != nil {
		out.Write([]byte{"done\n"})
	}
}
```
当debug=false时，程序还会调用`out.Write([]byte{"done\n"})`，此时程序崩溃。此时out是一个动态类型为*bytes.Buffer类型的空值的非空接口，所以out!=nil=true。
## error接口
error类型是一个接口类型，包含返回错误消息的方法:
```go
type error interface {
	Error() string
}
```
构造error的方式errors.New。
```go
package errors
func New(text string)error{
	return &errorString{text}
}
type errorString struct {
	text string
}
func (e *errorString)Error()string{
	return e.text
}
```
更易用的方式是`fmt.Errorf`。
## 类型断言
类型断言是一个作用在接口值上的操作。类似`x.(T)`，x是接口类型的表达式，T是一个类型。类型断言会检查作为操作数的动态类型是否满足指定的断言类型。如果T一个具体类型，类型断言会检查x的动态类型是否就是T，如果T是一个接口类型，如果检查成功，则转化为接口类型T，如果操作数是一个空接口值，类型断言都失败，无法确定一个接口值的动态类型，需要检测它是否是某一个特定类型，如果类型断言出现在需要2个结果的赋值表达式中，那么断言不会在失败时崩溃，而是返回一个布尔型的返回值表示类型断言是否成功。
```go
var w io.Writer=os.Stdout
f,ok:=w.(*os.File)
b,ok:=w.(*bytes.Buffer)
if f,ok:=w.(*os.File); ok {
	// 使用f
}
if w,ok:=w.(*os.File); ok {
	// 使用w，新的值覆盖原有的值
}
```
## 使用类型断言来识别错误
os包返回的文件错误集合，提供3个帮助函数
```go
package os
func IsExist(err error) bool
func IsNotExist(err error) bool
func IsPermission(err error) bool
```
可以根据某个err的字符串检测是某种错误，但是这种方法不健壮。有专门的类型表示错误值，PathError保留了错误所有的底层信息，所以可以通过类型断言来检查错误的特性类型。
## 通过接口类型断言来查询特性
```go
func writeString(w io.Writer, s string) (n int, err error) {
	type stringWriter interface {
		WriteString(string) (int, error)
	}
	if sw, ok := w.(stringWriter); ok {//使用类型断言推断w的动态类型是否满足新的接口
		return sw.WriteString(s)
	}
	return w.Write([]byte(s))
}
```
使用类型断言来将父类型转换为子类型，子类型更专用，父类型的方法更通用。
## 类型分支
接口有2种类型:
- 方法抽象接口，强调突出接口中的操作
- 标记接口，强调接口作为一个标记，没有任何方法，使用类型断言来if-else分别处理。

Go提供了类型分支switch语句简化类型断言if-else处理，主意使用的形式是`x.(type)`而不是具体的类型，重用变量名是为了在块中使用具体类型的变量而不用转型。
```go
switch x:=x.(type) {// 这是重用变量名，这里的x只是switch词法块的，隐藏了外部的x变量可见性	
	case nil:
	case int,unit:
	......
}
```

## 示例: 基于标记的XML解析
go标准库提供`encoding/xml`包用于解析XML文件，API中的相关的类型如下:
```go
package xml
type Name struct {
	Local string
}
type Attr struct {
	Name Name
	Value string
}
type Token interface{}
type StartElement struct {
	Name Name
	Attr []Attr
}
type EndElement struct {
	Name Name
}
type CharData []byte
type Comment []byte
type Decoder struct{

}
func NewDecoder(io.Reader) *Decoder
func (*Decoder) Token()(Token,error)
```
Token接口没有任何方法，是一种可识别联合接口，它的实现类型是固定而暴露的，使用类型switch来决定对每种具体类型的处理。
```go
package main

import (
	"encoding/xml"
	"fmt"
	"io"
	"os"
	"strings"
)

func main() {
	dec := xml.NewDecoder(os.Stdin)
	var stack []string
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break
		} else if err != nil {
			fmt.Fprintf(os.Stderr, "xmlselect: %v\n", err)
			os.Exit(1)
		}
		switch tok := tok.(type) {
		case xml.StartElement:
			stack = append(stack, tok.Name.Local)
		case xml.EndElement:
			stack = stack[:len(stack)-1]
		case xml.CharData:
			if containsAll(stack, os.Args[1:]) {
				fmt.Printf("%s:%s\n", strings.Join(stack, " "), tok)
			}
		}
	}
}
func containsAll(x, y []string) bool {
	for len(y) <= len(x) {
		if len(y) == 0 {
			return true
		}
		if x[0] == y[0] {
			y = y[1:]
		}
		x = x[1:]
	}
	return false
}

```
## 一些建议
不要上来就创建一系列接口，每个接口只有一个具体类型，这是不必要的抽象，使用导出机制来限制类型的方法/字段的可访问性，如果有多个具体类型需要按统一的方式处理才需要接口。接口抽象掉实现细节。接口设计的原则是仅要求你需要的。不是所有东西都必须是一个对象。
# goroutine和通道
并发编程表现为程序由若干个自主的活动单元组成，主要使用并发来隐藏I/O操作的延迟，充分利用现代的多核计算机。有2种并发编程的风格:
- goroutine和channel，支持通信顺序进程(Communicating Sequential Process,CSP),是一个并发的模式，在不同的执行体(goroutine)之间传递值，但是变量本身局限于单一的执行体;
- 共享内存多线程的传统模型，与在其他主流语言中的线程类似.
## goroutine
每一个并发执行的活动称为goroutine。goroutine类似于线程。程序启动时主goroutine调用main函数。使用go创建新的goroutine。就是在普通的函数或者方法调用前加上go关键字前缀。go语句使函数在一个新创建的goroutine中执行，go语句本身立刻返回:
```go
f()//阻塞调用
go f() // 异步调用
```
```go
package main

import (
	"fmt"
	"time"
)

func main() {
	go spinner(100 * time.Millisecond)
	const n = 55
	fibN := fib(n)
	fmt.Printf("\rGibonacci(%d) = %d\n", n, fibN)

}
func spinner(deley time.Duration) int {
	for {
		for _, r := range `-\|/` {
			fmt.Printf("\r%c", r)
			time.Sleep(deley)
		}
	}
}
func fib(x int) int {
	if x < 2 {
		return x
	}
	return fib(x-1) + fib(x-2)
}
```
main方法执行结束，goroutine退出，没有办法终止goroutine。
## 示例: 并发时钟服务器
以每秒钟一次的频率向客户端发送当前时间:
```go
package main

import (
	"io"
	"log"
	"net"
	"time"
)

func main() {
	listener, err := net.Listen("tcp", "localhost:8080")
	if err != nil {
		log.Fatal(err)
	}
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Print(err)
			continue
		}
		handleConn(conn) // 一次处理一个连接

	}

}
func handleConn(c net.Conn) {
	defer c.Close()
	for {
		_, err := io.WriteString(c, time.Now().Format("15:04:05\n"))
		if err != nil {
			return // 连接断开
		}
		time.Sleep(1 * time.Second)
	}
}
```
此时服务器是顺序的，一次只能处理一个请求。支持并发，只需要`go handleConn(conn)`。现在可接收多个客户端并发执行。
## 示例: 并发回声服务器
```go

func echo(c net.Conn, shout string, delay time.Duration) {
	fmt.Fprintln(c, "\t", strings.ToUpper(shout))
	time.Sleep(delay)
	fmt.Fprintln(c, "\t", shout)
	time.Sleep(delay)
	fmt.Fprintln(c, "\t", strings.ToLower(shout))
}
func handleConn1(c net.Conn) {
	input := bufio.NewScanner(c)
	for input.Scan() {
		go echo(c, input.Text(), 1*time.Second)
	}
	c.Close()
}
```
## 通道
通道是goroutine之间的通信机制。一个通道是一个具有特定类型的管道，叫做通道的元素类型，比如`chan int`。
```go
ch := make(chan int) //ch的类型是chan int
```
通道是引用类型。可以比较。2个主要的通信操作:
- 发送send
- 接收receive
- 关闭close，设置一个标志位标识值发送完毕，在关闭的通道上进行接收，将获取所有已经发送的值，直到通道为空，接收操作会立即完成，最后获取一个通道元素类型对应的零值
```go
ch <- x// 发送语句
x = <- ch // 赋值语句中的接收表达式
<-ch  // 接收语句，丢弃结果
```
- 无缓冲通道: `make(chan int) make(chan int, 0)`
- 缓冲通道: `make(chan int, 3)// 容量为3的缓冲通道`
1. 无缓冲通道
   类似于1个容量的生产者消费者，如果没有被接收，再次发送将会阻塞，如果没有值，则接收会阻塞，直到值存在。无缓冲通道的通信使发送与接收的goroutine同步化。称为同步通道。下面的例子:
   ```go
	func main() {
		conn, err := net.Dial("tcp", "localhost:8080")
		if err != nil {
			log.Fatal(err)
		}
		done := make(chan struct{})
		go func() {
			io.Copy(os.Stdout, conn) // 忽略错误
			log.Println("done")
			done <- struct{}{} // 指示主goroutine
		}()
		mustCopy(conn, os.Stdin)
		conn.Close()
		<-done
	}
	func mustCopy(dst io.Writer, src io.Reader) {
		if _, err := io.Copy(dst, src); err != nil {
			log.Fatal(err)
		}
	}
   ```
   当通道的通信本身以及通信发生的时间很重要时，消息叫做事件。 
2. 管道
   通道可以用来连接goroutine。这个叫管道。一个2个管道的例子:
   ```go
	func main() {
		naturals := make(chan int)
		squares := make(chan int)
		go func() {
			for x := 0; ; x++ {
				naturals <- x
				time.Sleep(1 * time.Second)
			}
		}()
		go func() {
			for {
				x := <-naturals
				squares <- x * x
			}
		}()
		for {
			fmt.Println(<-squares)
		}
	}
   ```
   可以调用内置的`close`函数来关闭通道。关闭通道后，最后一个数据被读完，后续会直接获取通道的零值。没有直接的方式判断通道是否关闭。从机制上来说，通道都是发送端关闭的。接收操作有一个变种: 接收通道的元素/一个布尔值，为true表示接收成功，false表示接收的操作在一个关闭的并且读完的通道上，所以可以修改代码:
   ```go
   go func() {
       for {
		   x, ok := <-naturals
		   if !ok {
			   break //通道关闭并且读完
		   }
		   squares<-x*x
	   }
	   close(squares)
   }
   ```
   range循环支持在通道上迭代，接收完最后一个值后关闭循环。
   ```go
	func main() {
		naturals := make(chan int)
		squares := make(chan int)
		go func() {
			for x := 0; x < 10; x++ {
				naturals <- x
				time.Sleep(1 * time.Second)
			}
			close(naturals)
		}()
		go func() {
			for x := range naturals {
				squares <- x * x
			}
			close(squares)
		}()
		for x := range squares {
			fmt.Println(x)
		}
	}
   ```
   关闭已经关闭的通道会导致宕机。
3. 单向通道类型
   Go系统提供了单向通道接口类型，仅仅具有发送或者接收的操作。`chan<- int`是一个只能发送的通道。`<-chan int`是一个只能接收的通道。
   ```go
	func counter(out chan<- int) {
		for x := 0; x < 100; x++ {
			out <- x
		}
		close(out)
	}
	func squarer(out chan<- int, in <-chan int) {
		for v := range in {
			out <- v * v
		}
		close(out)
	}
	func printer(in <-chan int) {
		for v := range in {
			fmt.Println(v)
		}
	}
	func main() {
		naturals := make(chan int)
		squares := make(chan int)
		go counter(naturals)
		go squarer(squares, naturals)
		printer(squares)
	}
   ```
4. 缓冲通道
   缓冲通道有一个元素队列。就是类似支持并发的普通队列，消费者从头消费，生产者从尾部插入。如果满了，发送者阻塞，如果空了，消费者阻塞。缓冲通道将发送者与接收者解耦，不用同步了。
## 并行循环
下面的程序批量生成缩略图
```go
// ImageFile从infile中读取一幅图像并把它的缩略图写入同一个目录
// 它返回生成的文件名，比如foo.thumb.jpg
func ImageFile(infile string) (string, error) {
	return "", nil
}
func makeThumbnails(filenames []string) {
	for _, f := range filenames {
		if _, err := ImageFile(f); err != nil {
			log.Println(err)
		}
	}
}
```
完全独立的子问题组成的问题称为高度并行。第一个并行的版本，这个版本没有等待所有的goroutine结束就结束了，有问题需要等待其他goroutine完成:
```go
func makeThumbnails2(filenames []string) {
	for _, f := range filenames {
		go ImageFile(f)
	}
}
```
第二个版本的
```go
func makeThumbnails3(filenames []string) {
	ch := make(chan struct{})
	for _, f := range filenames {
		go func(f string) {
			ImageFile(f)
			ch <- struct{}{}
		}(f)
	}
	for range filenames {
		<-ch
	}
}
```
```go
for _, f := range filenames {
	go func(){
		ImageFile(f)// 这种方式不正确，f是共享的，goroutine运行时，可能被下一次的迭代f更改了，所以不是执行时候状态的值。
	}()
}
```
返回第一个遇到的错误
```go
func makeThumbnails4(filenames []string) error {
	errors := make(chan error)
	for _, f := range filenames {
		go func(f string) {
			_, err := ImageFile(f)
			errors <- err
		}(f)
	}
	for range filenames {
		if err := <-errors; err != nil {
			return err // 不正确，goroutine泄漏
		}
	}
	return nil
}
```
上面的代码有一个错误，当遇到非nil的错误时，方法返回，没有goroutine继续从errors通道上接收，直至读完，其他的goroutine在发送时会被阻塞永不终止。goroutine泄漏可能导致程序卡住或者系统内存耗尽。2种方案:
- 使用一个有足够容量的缓冲通道,这样发送的goroutine不会阻塞
- 返回错误时，创建一个goroutine来读完通道

```go
func makeThumbnails5(filenames []string) (thumbfiles []string, err error) {
	type item struct {
		thumbfile string
		err       error
	}
	ch := make(chan item, len(filenames))
	for _, f := range filenames {
		go func(f string) {
			var it item
			it.thumbfile, it.err = ImageFile(f)
		}(f)
	}
	for range filenames {
		it := <-ch
		if it.err != nil {
			return nil, it.err
		}
		thumbfiles = append(thumbfiles, it.thumbfile)
	}
	return thumbfiles, nil
}
```
使用一个计数器机制来统计文件的总大小:
```go
func makeThumbnails6(filenames <-chan string) int64 {
	sizes := make(chan int64)
	var wg sync.WaitGroup // 记录工作goroutine的个数
	for f := range filenames {
		wg.Add(1)
		// worker
		go func(f string) {
			defer wg.Done()
			thumb, err := ImageFile(f)
			if err != nil {
				log.Println(err)
				return
			}
			info, _ := os.Stat(thumb)
			sizes <- info.Size()
		}(f)
	}
	go func() {
		wg.Wait()
		close(sizes)
	}()
	var total int64
	for size := range sizes {
		total += size
	}
	return total
}
```
## 示例: 并发的Web爬虫

## 使用select多路复用
下面的程序是一个火箭发射程序，`time.Tick()`会返回一个channel，这个channal周期性的接收当前的时间事件。如果需要一个中断火箭的操作，因为channel是阻塞的，所以需要多路复用。
```go
func main() {
	fmt.Println("Commencing countdown")
	abort := make(chan struct{})
	go func() {
    	os.Stdin.Read(make([]byte, 1)) // read a single byte
    	abort <- struct{}{}
	}()
	tick:=time.Tick(1*time.Second)
	for countdown:=10;countdown>0;countdown--{
		fmt.Println(countdown)
		<-tick
	}
	launch()
}
func launch()  {
}
```
多路复用使用select语句
```go
select {
case <-ch1:
    // ...
case x := <-ch2:
    // ...use x...
case ch3 <- y:
    // ...
default:
    // ...
}
```
每个case代表一个通信操作(在channel上发送或者接收)，如果有一个case满足就执行，没有就执行default，`select{}`会永远的阻塞下去。
```go
func main() {
    // ...create abort channel...
    fmt.Println("Commencing countdown.  Press return to abort.")
    select {
    case <-time.After(10 * time.Second):
        // Do nothing.
    case <-abort:
        fmt.Println("Launch aborted!")
        return
    }
    launch()
}
```
多个case都满足条件，则随机的执行一个，最终的火箭发射程序
```go
func main() {
    // ...create abort channel...
    fmt.Println("Commencing countdown.  Press return to abort.")
    tick := time.Tick(1 * time.Second)
    for countdown := 10; countdown > 0; countdown-- {
        fmt.Println(countdown)
        select {
        case <-tick:
            // Do nothing.
        case <-abort:
            fmt.Println("Launch aborted!")
            return
        }
    }
    launch()
}
```
此处`time.Tick`有点类似`time.Sleep`操作，`time.Tick`后台会创建一个goroutine，不断的向channel发送当前时间，此时函数执行完毕后，这个gotroutine还在执行，造成goroutine的泄漏。一个合适的方式是
```go
ticker := time.NewTicker(1 * time.Second)
<-ticker.C    // receive from the ticker's channel
ticker.Stop() // cause the ticker's goroutine to terminate
```
## 示例: 并发目录遍历
## 取消
一个goroutine无法直接终止另一个。任何时刻都难以知道工作的goroutine数量，使用通道关闭(关闭后，接口操作立即返回)特点来测试一个取消机制
```go
```
## 示例: 聊天服务器
# 使用共享变量实现并发
## 竟态
如果2个事件毫无任何关联点或者发生顺序的直接或者间接的定义，这2个事件就是并发的。函数再并发调用时正确工作(无共享状态或者状态有同步机制)就是并发安全。类型所有可访问方法和操作都是并发安全的就是并发安全的类型。竟态是指多个goroutine按交错顺序执行时程序不能正确工作。数据竟态发生于2个goroutine并发读写同一个变量并且至少其中一个是写入时。避免数据竟态的3种方式:
  - 不要修改变量，不修改的数据结构与不可变数据本质是并发安全的
  - 变量只在一个goroutine内访问，不会有多于1个的goroutine访问，如果要访问需要通过通道的方式（Go箴言: 不要通过共享内存来通信，而应该通过通信来共享内存）;
  - 互斥机制，同一时间只能有一个goroutine访问
## 互斥锁: sync.Mutex
容量为1的通道也能限制多个goroutine反问共享变量。`sync.Mutex`是专门的互斥锁。Lock方法用于上锁，Unlock方法用于释放锁。
```go
var (
	mu      sync.Mutex
	balance int
)
func Deposit(amount int) {
	mu.Lock()
	balance += amount
	mu.Unlock()
}
func Balance() int {
	mu.Lock()
	b := balance
	mu.Unlock()
	return b
}
```
互斥锁保护共享变量，2者应该声明再一起。中间的代码称为临界区域，必须保证锁被释放，包括所有分支，所以Unlock通过defer机制使用。函数、互斥锁与共享变量的组合称为监控模式。处理并发程序优先考虑清晰度拒绝过早优化。互斥锁是不可再入的。封装在程序中减少对数据结构的非预期交互帮助保证数据结构中的不变量。使用互斥锁要保证互斥锁与保护的共享变量不会导出，否则互斥锁没有任何意义。
## 读写互斥锁: sync.RWMutex
多读单写锁。一般情况下比较少用。
## 内存同步
## 延迟初始化: sync.Once
延迟一个昂贵的初始化步骤到有实际需求的时刻是好的实践预先初始化会增加程序的启动延迟，下面的例子:
```go
import (
	"image"
)

var icons map[string]image.Image

func loadIcons() {
	icons = map[string]image.Image{
		"spades.png": loadIcon("spades.png"),
	}
}

// 并发不安全
func Icon(name string) image.Image {
	if icons == nil {
		loadIcons()
	}
	return icons[name]
}
func loadIcon(name string) image.Image {
	return nil
}
```
多个goroutine使用icons变量时，可能多次初始化。最好就是使用互斥锁:
```go
// 并发不安全
func Icon(name string) image.Image {
	mu.Lock()
	defer mu.Unlock()
	if icons == nil {
		loadIcons()
	}
	return icons[name]
}
```
但是这样写在初始化完成后，锁操作就是无用了，而且会造成额外的代价。使用读写锁可以改善
```go
func Icon2(name string) image.Image {
	mu2.RLock()
	if icons != nil {
		icon := icons[name]
		mu2.RUnlock()
		return icon
	}
	mu2.RUnlock()
	mu2.Lock()
	defer mu2.Unlock()
	if icons == nil {
		loadIcons()
	}
	return icons[name]
}
```
go提供了`sync.Once`机制来解决这个问题，类似读写锁，包含一个布尔变量与一个互斥量，布尔变量记录初始化是否已经完成，互斥量负责保护这个布尔变量和客户端的数据结构，Once的唯一方法Do的参数是初始化的函数，简化后的代码:
```go
var loadIconsOnce sync.Once
func Icon3(name string) image.Image {
	loadIconsOnce.Do(loadIcons)
	return icons[name]
}
```
## 竟态检测器
Go运行时为了避免犯并发上的错误，提供竟态检测器。使用-race参数就开启检测，它会修改应用加上对共享变量的统计等记录信息。还会记录同步事件包括go语句、通道、锁等调用。它只能检测实际运行涉及到的竟态，所以测试时保证用例全面，开启竟态检测器的性能与内存消耗可以忽略不记，可以帮助节省额外的调试时间。
## 示例: 并发非阻塞缓存
## goroutine与线程
1. 线程的栈是固定大小的，goroutine的栈不是，栈都用于存储正在执行的函数的局部变量。
2. OS线程由OS内核调度，每隔几毫秒，一个硬件时钟中断发到CPU，CPU调用一个叫调度器的内核函数。这个函数暂停当前正在运行的线程，把它的寄存器信息保存到内存，查看线程列表并决定接下来运行哪一个线程，再从内存恢复线程的注册表信息，最后执行选中的线程。因为OS线程由内核来调度，所以控制权限从一个线程切换到另外一个线程需要一个完整的上下文切换(context switch): 即保存一个线程的状态到内存，再恢复另外一个线程的状态，最后更新调度器的数据结构。Go运行时包含一个自己的调度器，这个调度器使用一个称为$m:n$调度的技术，它可以复用/调度$m$个goroutine到$n$个OS线程，Go调度器与内核调度器类似，Go调度器不是由硬件时钟来定期触发的，由特定的go语言结构触发，比如time.Sleep()、通道阻塞、互斥量操作等，调度器会把这个goroutine设置为休眠模式，运行其他的goroutine。因为不需要切换到内核环境，所以一个gouroutine比调度线程的成本低。
3. GOMAXPROCS，确定使用多少个OS线程来执行Go代码。可以通过环境变量设置，默认值是CPU核数，还有一些特殊类型的goroutine是独立的OS线程，不算在这个参数数量内。
4. goroutine没有向外部提供可访问的标识，因为go追求尽量简单，所以没有java中的类似ThreadLocal的机制，因为go觉得函数要明显的指定参数并只依赖参数，不能依赖线程标识等。
# 包和go工具
通过包/模块来复用别人写的代码，Go自带100多个基础包，配套的Go工具功能强大。`go list std`列出标准包。
## 包简介
任何包管理系统的目的维护独立的包，包都是实现特定功能的，通过包组成大型程序，模块化允许包可以共享、复用。包的名字就是命名空间，这样较短的名字不会冲突。包通过控制名字是否导出来提供封装能力，隐藏内部使用的函数和类型，也就是隐藏实现，修改不影响对外接口。编译快的原因
- 导入在文件头，依赖性问题可以快速识别
- 包的依赖是树形，可以并行编译
## 导入路径
每个包的规范名也就是称为导入路径是全球唯一的，用在import声明中:
```go
import (
	"fmt"
	"math/rand"
	"golang.org/x/net/html"
	"github.com/go-sql-driver/mysql"
)
```
导入路径可以是任意字符串。因为并没有任何规定。但是为了分发的方便，设定了Go工具可以理解的形式。标准包外的其他包的导入路径应该以域名开始。比如上面的github的包，这样知道去哪里下载包。
## 包的声明
Go源文件的开头声明自己所在的包，被引入时才能使用到Go源文件中的代码。包名就是路径的最后一段，如果遇到包名冲突，可以给包起别名，可执行命令所在的包总是为main，go build时会生成可执行文件。
## 导入声明
源文件声明0个或者多个import声明。如果遇到包名冲突，可以给包起别名，叫做重命名导入，只在当前文件起作用。如果包与变量名字冲突，起别名叫做变量名+pkg就可以了。
```go
import (
	"crypto/rand"
	mrand "math/rand" //通过指定一个不同的名字mrand就避免了冲突
)
```
## 空导入
没有用到的导入会产生一个编译错误，有时候需要导入一个包来执行包级别的变量初始化求值与init函数，为了防止报错，必须使用`_`空白符来重命名导入，表示导入的内容为空白标识符，
```go
import _ "image/png" // 注册PNG解释器
```
这叫做空白导入，用来实现一种编译时的机制开启主程序中可选的特性。一个例子程序如下，例子使用来`image.Decode`函数从`io.Reader`读取数据，内部识别格式调用适当的解码器返回`image.Image`对象
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
	img, kind, err := image.Decode(in)// 读取图像数据
	if err != nil {
		return err
	}
	fmt.Fprintln(os.Stderr, "Input format = ", kind)
	return jpeg.Encode(out, img, &jpeg.Options{Quality: 95})//写入图像数据到标准输出
}
```
标准库提供GIF、PNG、JPEG格式解码库，默认解码器不会被包含进程序。`image.Decode`查询一个支持格式的表格，表格包含4列: 格式的名字、格式的字符串前缀、解码函数Decode、解码元数据的函数DecodeConfig；对于解码器实现来说，调用`image.RegisterFormat`向表格添加项。
```go
package png
func Decode(r io.Reader)(image.Image,error)
func DecoderConfig(r io.Reader)(image.Config, error)
func init(){
	const pngHeader="\x89PNG\r\n\x1a\n"
	image.RegisterFormat("png",pngHeader, Decode, DecoderConfig)
}
```
观察者模式。database/sql也是类似的机制。
```go
import (
	"database/sql"
	_ "github.com/lib/pg" // 添加Postgres支持
	_ "github.com/go-sql-driver/mysql" // 添加MySQL支持
)
db,err=sql.Open("postgres",dbname) //OK
db,err=sql.Open("mysql",dbname)//OK
db,err=sql.Open("sqlite3",dbname)// unknown driver sqlite3
```
##  包及其命名
创建包使用简短的名字保持可读性与无歧义。不要用可能是变量名的名字，通常使用统一的形式，比如如果关键字冲突，使用复数形式。通常的名字格式[领域名+抽象的操作分类名]。
## go工具
Go工具主要用来下载、查询、格式化、构建、测试以及安装Go代码包。go有很多的子命令，通过`go help`来查看内置文档。
1. 工作空间的组织
   必须配置GOPATH环境变量，工作空间的根，GOPATH有3个子目录，src子目录包含源文件，每个包放在一个目录中，目录就是包的导入路径，pkg子目录是构建工具存储编译后的包的位置，bin子目录放置可执行程序。GOROOT环境变量类似GOPATH，但是是GO标准库包的位置。go env输出环境变量，GOOS指定目标操作系统，GOARCH指定目标处理器架构。
2. 包的下载
   包的导入路径是包在本地的位置也是在互联网上的位置，go get也会下载包的关联依赖，完成下载后，构建、安装库或者相应的命令，go get创建的目录是远程仓库的真实客户端。包导入路径中的golang.org不同于Git服务器的实际域名，这是因为对于github.com这样的服务，可以使用自定义域名，只要在获取资源的地址上放上源数据，也就是真实的代码地址，go工具会识别并自动重定向，这也实现了导入路径自定义。使用-u开关更新所有关联依赖包，不开启优先优先本地。如果需要精确的控制版本，请使用vendor目录。
3. 包的构建
   go build命令编译每一个命令行参数中的包，如果包的名字是main，go build调用链接器在当前目录中创建可执行程序，可执行程序的名字取自包的导入路径的最后一段。
4. 包的文档化
   有良好的API文档。`go doc time`输出文档注释，可以输出一个包、方法、成员等都可以。还有一个工具godoc。提供相互链接的HTML页面服务。
5. 内部包
   导入路径中含有internal关键词的包，internal目录的父目录下的所有包可以导入此内部包，其他不行。限定了包的访问范围
6. 包的查询
   `go list`列出包是否再工作空间中，输出导入路径。`go list ...`列出工作空间中的所有包。`go list -json hash`json格式输出包的完整记录。
# package & module
# go工具
## go env
go环境变量可以直接在系统中设置或者通过Go的命令行工具设置。`go env <NAME>`查看环境变量，
`go env -w <NAME>=<VALUE>`设置环境变量，比如
```shell
go env -w GO111MODULE=on
```
这种方式设置的变量会写到一个Go的配置文件中。这个文件的地址可以通过`GOENV`修改，具体的环境变量的介绍如下：
- GOROOT: Go的安装目录
- GOPATH: 指定开发工作区，存放源代码、测试文件、库静态文件、可执行文件的目录。可以包含多个目录，一般有3个子目录:
  - src: 每个模块包的源代码
  - pkg: 编译后的库静态文件
  - bin: 存放可执行文件
- GOBIN: 编译后的程序的目录，`go install`也会安装到这个目录下面，一般就是`${GOPATH}/bin`目录
- GOOS: 交叉编译用的，默认是当前操作系统
- GOARCH: CPU架构，默认是当前计算机的，
# 测试
测试是自动化测试的简称，编写简单的程序来确保程序在该测试中针对特定输入产生预期的输出。
## go test工具
go test是go语言包的测试驱动命令，在一个包中，以_test.go结尾的文件不是go build命令编译的目标，是go test编译的目标。在*_test.go文件中，3种函数需要区别对待:
- 功能测试函数，以Test前缀命名的函数，用来检测程序逻辑结果的正确性;
- 基准测试函数: 名称以Benchmark开头，测试操作的性能
- 示例运行测试函数: 名称以Example开头，用来提供机器检查过的文档

go test工具扫描*_test.go文件寻找特殊函数并生成一个临时的main包来调用它们，编译运行汇报结果
## Test函数
必须导入testing包，函数签名如下:
```go
func TestName(t *testing.T){...}
```
```go
func TestIsPalindrome(t *testing.T) {
	if !IsPalindrome("abba") {
		t.Error(`IsPalindrome("abba") = false`)
	}
}
```
go test在不指定包参数的情况下，以当前目录所在的包为参数，可以cd到要运行的测试文件所在的目录执行go test。
- -v 输出测试名称测试时间
- -run 只运行匹配的测试用例，也就是特定的函数
## Example函数
示例函数，既没有参数也没有结果。3个目的:
- 作为文档中的例子;
- Example函数将和包关联在一起，后面如果是函数，就与函数关联在一起，godoc时文档显示在一起;
- 通过`go test`运行的可执行测试
- 提供手动实验代码，godoc文档服务器提供的Go Playground可以在web上编辑与运行每个示例函数

# 反射
再不知道类型的情况下更新变量、查看值调用方法的机制，称为反射，就是再不知道类型的情况操作值。
## 为什么使用反射
编写一个统一处理各种值类型的函数，面临3个问题
- 这些类型没有统一的接口
- 布局未知
- 设计时还不存在
一个例子是`fmt.Printf()`，我们自定义的实现如下:
```go
func Sprint(x interface{}) string {
	type stringer interface {
		String() string
	}
	switch x := x.(type) {
	case stringer:
		return x.String()
	case string:
		return x
	case int:
		return strconv.Itoa(x)
	case bool:
		return "true"
	default:
		return "???"
	}
}
```
没办法处理各种引用类型或者自定义类型，分支不能无限加，这时候就需要反射。
## reflect.Type和reflect.Value
反射功能由reflect包提供，包含2个类型
- Type，表示Go语言的一个类型，一个很多方法的接口，只有一个实现，类型描述符接口值中的动态类型也是类型描述符`reflect.TypeOf(interface{})`把接口中的动态类型以reflect.Type的形式返回。格式化中的%T使用的就是这个反射；
- Value，包含一个任意类型的值，`reflect.ValueOf(interface{})`把接口中的值以reflect.Value的形式返回，%v使用的是这个反射。`Value.Type()`方法返回值的	`reflect.Type`形式，`reflect.Value.Interface`是ValueOf的逆操作。

reflect.Value与interface{}都可以包含任意的值，区别是interface{}隐藏了值的布局信息、内置操作和相关方法，只有通过类型断言来做深入的处理，Value有很多方法可以用来分析所包含的值，不用知道它的类型，一个通用格式化函数如下:
```go
// 把任何一个值格式化为一个字符串
func Any(vale interface{}) string {
	return formatAtom(reflect.ValueOf(vale))
}
func formatAtom(v reflect.Value) string {
	switch v.Kind() {
	case reflect.Invalid:
		return "invalid"
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return strconv.FormatInt(v.Int(), 10)
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64, reflect.Uintptr:
		return strconv.FormatUint(v.Uint(), 10)
	case reflect.Bool:
		return strconv.FormatBool(v.Bool())
	case reflect.String:
		return strconv.Quote(v.String())
	case reflect.Chan, reflect.Func, reflect.Ptr, reflect.Slice, reflect.Map:
		return v.Type().String() + "0x" + strconv.FormatUint(uint64(v.Pointer()), 16)
	default:
		return v.Type().String() + " value"

	}
}
```
## Display: 一个递归的值显示器
更好的显示组合类型，给定的任意一个复杂的值$x$，输出复杂值的完整结构，并且输出元素路径。
```go
func Display(name string, x interface{}) {
	fmt.Printf("Display %s (%T): \n", name, x)
	display(name, reflect.ValueOf(x))
}
func display(path string, v reflect.Value) {
	switch v.Kind() {
	case reflect.Invalid:
		fmt.Printf("%s = invalid\n", path)
	case reflect.Slice, reflect.Array:
		for i := 0; i < v.Len(); i++ {
			display(fmt.Sprintf("%s[%d]", path, i), v.Index(i))
		}
	case reflect.Struct:
		for i := 0; i < v.NumField(); i++ {
			fieldPath := fmt.Sprintf("%s.%s", path, v.Type().Field(i).Name)
			display(fieldPath, v.Field(i))
		}
	case reflect.Map:
		for _, key := range v.MapKeys() {
			display(fmt.Sprintf("%s[%s]", path, formatAtom(key)), v.MapIndex(key))
		}
	case reflect.Ptr:
		if v.IsNil() {
			fmt.Printf("%s = nil\n", path)
		} else {
			display(fmt.Sprintf("(*%s)", path), v.Elem())
		}
	case reflect.Interface:
		if v.IsNil() {
			fmt.Printf("%s = nil\n", path)
		} else {
			fmt.Printf("%s.type = %s\n", path, v.Elem().Type())
			display(path+".value", v.Elem())
		}
	default:
		fmt.Printf("%s = %s\n", path, formatAtom(v))
	}
}
```
- slice与数组: Len()方法与Index方法可以获取元素，获取的元素类型是`reflect.Value`，`reflect.Value`中的方法只对特定的值可以调用
- struct: NumField与Field方法
- map: MapKeys,
- 指针: Elem返回指针指向的变量，
- 接口: 
## 访问结构体字段标签

# 低级编程
# go Context
# viper
Go的完整配置解决方案，支持多种类型的配置格式。
## viper是什么?
特性:
- 设置默认值
- 支持JSON、TOML、YAML、HCL、envfile与Java Properties格式的配置
- 实时监控重新读取配置文件
- 从环境变量中读取
- 从远程配置系统(etcd/consul)读取并监控配置变化
- 从命令行参数读取配置
- 从buffer读取配置
- 显示配置值

Viper支持的操作:
- 查找、加载和反序列化JSON、TOML、YAML、HCL、INI、envfile和Java properties格式的配置文件
- 提供一种机制为你的不同配置选项设置默认值
- 提供一种机制来通过命令行参数覆盖指定选项的值
- 提供别名系统，以便在不破坏现有代码的情况下轻松重命名参数
- 当用户提供了与默认值相同的命令行或配置文件时，可以很容易地分辨出它们之间的区别

Viper中配置的优先级，递减顺序
- 显示调用Set设置值
- 命令行参数（flag）
- 环境变量
- 配置文件
- key/value存储
- 默认值

Viper中的配置项是不区分大小写的。
## 把值存入Viper
1. 默认值
   ```go
	viper.SetDefault("ContentDir", "content")
	viper.SetDefault("LayoutDir", "layouts")
	viper.SetDefault("Taxonomies", map[string]string{"tag": "tags", "category": "categories"})
   ```
2. 读取配置文件
   Viper要知道去哪里找配置文件。可以搜索多个路径，一个Viper只支持一个配置文件。Viper没有默认的搜索路径设置。
   ```go
	func main() {
		viper.SetConfigFile("./toml.toml") // 指定配置文件路径
		viper.SetConfigName("config")      // 配置文件名称(无扩展名)
		// viper.SetConfigType("toml")        // 如果配置文件的名称中没有扩展名，则需要配置此项
		// viper.AddConfigPath("/Users/zhangyongxiang/Projects/go-practice/viper/") // 查找配置文件所在的路径
		viper.AddConfigPath("$HOME/.appname") // 多次调用以添加多个搜索路径
		viper.AddConfigPath(".")              // 还可以在工作目录中查找配置
		err := viper.ReadInConfig()           // 查找并读取配置文件
		if err != nil {
			if _, ok := err.(viper.ConfigFileNotFoundError); ok {
				// 配置文件未找到错误；如果需要可以忽略
				fmt.Println("config.json file not found")
			} else { // 处理读取配置文件的错误
				panic(fmt.Errorf("Fatal error config.json file: %s \n", err))
			}
		}
		fmt.Println(viper.GetString("format"))

	}
   ```
3. 写入配置文件，存储运行时所做的修改，使用2种方式:
   - WriteConfig: viper写入预定义文件，如果没有则不会写入
   - SafeWriteConfig: 配置写入预定义文件，如果存在则不覆盖
   - WriteConfigAs: 配置写入给定的文件，如果存在则覆盖
   - WriteConfigAs: 配置写入给定的文件，如果存在不覆盖
   
   ```go
	viper.WriteConfig() // 将当前配置写入“viper.AddConfigPath()”和“viper.SetConfigName”设置的预定义路径
	viper.SafeWriteConfig()
	viper.WriteConfigAs("/path/to/my/.config")
	viper.SafeWriteConfigAs("/path/to/my/.config") // 因为该配置文件写入过，所以会报错
	viper.SafeWriteConfigAs("/path/to/my/.other_config")
   ```
4. 监控并重新读取配置文件，运行时实时读取配置文件的更新。提供一个回调函数在发生变更运行
   ```go
	viper.WatchConfig()
	viper.OnConfigChange(func(e fsnotify.Event) {
	// 配置文件发生变更之后会调用的回调函数
		fmt.Println("Config file changed:", e.Name)
	})
   ```
5. 从`io.Reader`读取配置，实现自己所需的配置源提供给viper
   ```go
	viper.SetConfigType("yaml") // 或者 viper.SetConfigType("YAML")

	// 任何需要将此配置添加到程序中的方法。
	var yamlExample = []byte(`
	Hacker: true
	name: steve
	hobbies:
	- skateboarding
	- snowboarding
	- go
	clothing:
	jacket: leather
	trousers: denim
	age: 35
	eyes : brown
	beard: true
	`)
	viper.ReadConfig(bytes.NewBuffer(yamlExample))
	viper.Get("name") // 这里会得到 "steve"
   ```
6. 覆盖设置
   配置可能来自不同的来源
   ```go
	viper.Set("Verbose", true)
	viper.Set("LogFile", LogFile)
   ```
7. 注册与使用别名
   允许多个键引用单个值
   ```go
	viper.RegisterAlias("loud", "Verbose")  // 注册别名（此处loud和Verbose建立了别名）
	viper.Set("verbose", true) // 结果与下一行相同
	viper.Set("loud", true)   // 结果与前一行相同

	viper.GetBool("loud") // true
	viper.GetBool("verbose") // true
   ```
8. 使用环境变量
   支持环境变量，涉及到环境变量的有5种方法
   - `AutomaticEnv()`
   - `BindEnv(string...) : error`有种形式通过键名或者变量名2种方式读取，优先通过变量名的方式
   - `SetEnvPrefix(string)`: 读取环境变量时使用前缀
   - `SetEnvKeyReplacer(string...) *strings.Replacer`: 重写健的生成方式
   - `AllowEmptyEnv(bool)`
  
   viper在处理环境变量时区分大小写。
   ```go
	fmt.Println(os.Environ())
	viper.AutomaticEnv()
	viper.SetEnvPrefix("HOMEBREW") // 将自动转为大写
	err := viper.BindEnv("PREFIX")
	if err != nil {
		return
	}
	id := viper.Get("PREFIX") // 13
	fmt.Println(id)
   ```
9. 使用Flags
    可以绑定到命令行参数，支持Cobra的Pflag。这里暂时没看懂什么意思
10. 远程Key/Value存储支持

## 从Viper获取值
获取值的方法如下:
- `Get(key string) : interface{}`
- `GetBool(key string) : bool`
- `GetFloat64(key string) : float64`
- `GetInt(key string) : int`
- `GetIntSlice(key string) : []int`
- `GetString(key string) : string`
- `GetStringMap(key string) : map[string]interface{}`
- `GetStringMapString(key string) : map[string]string`
- `GetStringSlice(key string) : []string`
- `GetTime(key string) : time.Time`
- `GetDuration(key string) : time.Duration`
- `IsSet(key string) : bool`
- `AllSettings() : map[string]interface{}`

找不到对应的键的时候返回0值，使用`IsSet()`方法检查键是否存在。
1. 使用点号访问嵌套的键
2. 可以获取Sub配置
3. 可以对配置反序列化
# gin
# gorm

