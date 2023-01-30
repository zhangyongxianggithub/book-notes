# 程序结构
Go语言中的大程序都从小的基本组件构建而来: 变量存储值，简单表达式通过加/减等操作合并成大的，基本类型通过数组和结构体进行聚合，表达式通过if/for等控制语句来决定执行顺序，语句被组织成函数用于隔离和复用，函数被组织成源文件和包。
## 名称

## 声明
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

