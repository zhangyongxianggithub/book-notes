[TOC]
# 第2章 编程原理与软件工程
本章讲一些编程的基本原理，用来应对复杂的大型程序。
## 2.1 问题求解与软件工程
问题求解是指描述问题以及开发计算机程序来解决问题的整个过程，这个过程包含多个阶段，比如：理解待解决的问题，设计概念化的方案、用计算机程序设实现解决方案。
解决方案由算法与数据结构2部分组成，算法是对在有限时间内求解问题的方法的分步描述。
软件生命周期分为9个阶段。这9个阶段都以文档记录为核心。
- 第一阶段 问题描述：软件的目标，问题的所有方面。必须对最初的问题描述进行准确的定义与详细的说明；在编写软件规范时，需要回答的问题有：1.输入什么数据、2.那些数据有效、3.哪些数据无效、4.软件的使用者是谁、5.选择什么什么形式的用户界面、6.要求进行什么错误检测显示什么错误消息、7.有什么假设、8.有特例么、9.选用哪种输出形式、10.需要哪些文档记录、11.未来要对软件进行哪些改进。
- 第二阶段 设计：对规模较大或者复杂度较大的程序，需要分解问题为若干个可以控制的小问题，最终程序会包含多个模块。一个例子：移动图形到一个新的坐标，问题描述如下:
    - f方法接收一个(x,y)坐标
    - 方法将图形移到屏幕的一个新的位置
上述的初始条件与结束条件不够充分，坐标能出现什么样的值，坐标是起始点还是结束点，都没有说明。预定条件需要更详细的说明。
```c
move(x,y)
// moves a shape to coordinate (x,y) on the screen
// Precondition: the calling program provides an (x,y) pair, both integers where 0<=x<=MAX_XCOOR and 0<=y<=MAX_YCOOR where MAX_XCOOR and MAX_YCOOR are class constants that specify the maximum coordinate values
// PostCondition: the shape is moved to the (x,y)
```
编写初始条件：描述方法形参、说明常量、列出假设条件
编写结束方法：描述方法对形参的作用，说明返回值，描述已发生的其他的操作。
准确的文档记录很重要，时间推移与团队扩大，都需要文档。
- 第三阶段：风险分析，影响项目进度成本等，影响软件的生命周期。
- 第四阶段：验证
断言（assertion）是对算法中某处具体条件的描述，初始条件与结束条件是方法开始与结束的断言；
不变式（invariant）是算法中某个位置一个恒为true的条件；
循环不变式（loop invariant）算法中循环前后恒为true的一个条件。
验证算法，就是对算法的每个步骤能够得出步骤前的断言导出步骤后的断言，则步骤正确，一直到结束条件的断言正确，则算法程序正确。
有点类似于几何推理。使用循环不变式来推导迭代算法的正确性。例子，证明代码可以计算出数组前n项的和
```c
int sum = 0;
int j = 0;
while(j < n) {
    sum+=item[j];
    ++j;
}
```
每一次循环执行完，sum都是元素item[0]到item[j-1]的和，这就是一个循环不变式，对于一个循环下列情况不变式恒为true.
1. 初始化步骤之后，循环开始执行之前;
2. 再循环的每次迭代前;
3. 在循环的每次迭代后;
4. 循环终止后.

对于上面的例子有:
```c
int sum = 0;
int j = 0;
// 不变式恒为true
while(j < n) {
    // 不变式恒为true
    sum+=item[j];
    ++j;
    // 不变式恒为true
}
// 不变式恒为true
```
通过观察不变式，可以证明算法是正确的，其实就是数学归纳法。
1. 开始时不变式必为true，开始前，sum=j=0，不变式是sum包含元素item[0]到item[-1]的和，这个范围没有元素，不变式为true
2. 循环的执行必须维持不变式的值，不变式在循环的恩和迭代前为true，迭代后必为true，sum的最后一个元素是item[j-1]，估迭代前与迭代后都是true的。
3. 不变式必须证明算法的正确性，就是结束后不变式为true。结束后，j=n，sum等于元素item[0]到item[n-1]的和，所以算法正确；
4. 循环必须能够终止.

开始时，不变式是true，意味着建立了数学归纳法的基例，类似于对于自然数0，属性是true，正确循环迭代维持值是归纳步骤，类似于对于k，属性为true，则对于k+1，属性是true。结束后得出结论。
- 第五阶段：编码,编码工作不是软件生命周期的主要部分，只是相对次要的工作。
- 第六阶段：测试，使用边角值测试，使用无效的值测试.
- 第七阶段：完善解决方案，通常解决问题的最好的方法就是在解决方案的设计期间做一些简化建设，比如：假设输入是某种格式，而且其内容是正确的，之后基于这些假设开发完整的工作程序，接下来，可向程序天际复杂的输入与输出处理附加的功能与更多的错误检查。这种简化问题的方法使问题解决过程需要加入一个完善步骤。
- 第八阶段：生产,
- 第九阶段：维护

如果解决方案在软件生命周期的所有阶段引发的总成本最低，它就是一个优秀的解决方案。
## 2.2 面向对象设计
解决方案设计中确定对象的2种技术
- 抽象
- 信息隐藏

1. 过程抽象
在设计一个问题解决方案的一部分使用的一个方法时，每个方法最初表示为一个箱子，箱子指出方法做什么，但不说明如何做。每个箱子都不知道其他箱子执行的方式。只知道其他箱子完成什么任务。比如一个方法做排序，只知道可以排序，不知道具体是如何排序的。这样，解决方案的各个组件就彼此分离开来。
![排序](pi csort-component.png)
过程抽象分离了方法的功能与实现方式，抽象就是描述方法的功能而不实现，着眼于高级功能，不使细节影响到我们。
2. 数据抽象
数据抽象注重操作执行什么任务不考虑如何实现操作；解决方法的其他模块知道它们可以执行哪些操作，但不了解数据存储方式以及操作执行方式；数据抽象是本书的主要内容，抽象的分析数据（考虑对数据执行哪些操作而不是如何执行这些操作），定义抽象数据类型（abstract data type），ADT是指一个数据集合与这个集合上的一组操作。在问题求解的过程中，ADT支持算法，算法不是ADT的组成部分，应协作开发算法与ADT，解决问题的全局算法要给出在数据上执行的操作，操作又给出ADT以及在数据上执行操作的算法。也可能以相反的方向进行。
2种观点：
- 数据结构支持精巧的算法
- 算法支持精巧的数据结构
3. 信息隐藏
抽象过程描述外部接口，对外部隐藏细节，要确保其他模块不能改变本模块的细节；模块的使用者不需要考虑实现细节，模块的实现者不需要考虑其用法。

面向对象的设计方案的开发方式是开发组合了数据与操作的对象，表示现实的实体或者操作过程，这种面向对象的模块化方法生成具有行为的对象的集合。
封装意思就是装箱封闭，是隐藏内部细节的技术，方法封装了操作，对象封装了数据与操作。
设计模块化的解决方案的步骤：
- 标识问题中的对象，一种简单的方法是考虑问题描述中的名词与动词，名词是对象，动词是操作。类型相同的一组对象叫做类。
OOP：
1. 封装：对象组合数据与操作
2. 继承：类可从其他类中继承属性
3. 多态（有多种形式）：对象可以在执行时确定需要什么样的操作，某个对象的输出取决于执行操作的对象。

功能分解（也叫做自上而下的设计）有助于把对象中的复杂任务分解为更便于管理的目的单一的任务与子任务。功能分解的原理为：逐步细化任务以完成任务。下图是解决问题的方法的层次结构
![功能分解](pic/方法分解.png)
设计问题的求解方案时，一般使用面向对象的设计（OOP）、功能分解（FD）、抽象与信息隐藏技术，下面的设计原则总结了导出模块化解决方案的方法。
- 使用OOD与FD生成模块化解决方案。协作开发抽象数据类型与算法。
- 为主要设计数据的问题使用OOD
- 使用FD为对象的操作设计算法
- 使用FD为强调算法的问题设计解决方案
- 在设计ADT与算法时，侧重做什么而不是如何做
- 考虑将以前编写的软件组件包含到设计方案中。

UML是表达面向对象设计的一种建模语言；提供了图表与文本描述规范，在表示解决方案的整体设计包括类的规范与类彼此交互的各种方式时，图表非常有效。一个解决方案通常会涉及许多类，表示类之间交互能力是UML的长处之一。类图指定了类的名称、数据成员、操作。一个简单的类图
![一个简单的类图](pic/简单的类图.png)
数据成员的UML表示法 visibility  name: type=default value
visibility的值是+=public，-=private，#=protected
操作的UML表示法 visibility name (parameter list):return-type {property-string}
parameter list的语法 direction name: type=default value
面向对象的解决方案更具有普遍性，功能分解会使的比较容易实现，可以继承复用类，减少代码的数量，继承可以随便更改不影响以前的逻辑使用的父类。
## 2.3 关键编程问题
关键的编程问题
- 模块化
- 可修改
- 易用
- 防故障编程
- 风格
- 调试
1. 模块化
面向对象设计就是模块化设计，模块化方便组建大型程序，支持大型程序的调试，并且能够隔离错误；方便修改，消除冗余代码。
2. 可修改性
通过方法与命名常量来提高程序的可修改性
- 方法：将共同的操作提取为方法；
- 命令常量：将共同需要使用的常量提取为命名常量，方便变更。
3. 易用性
- 交互环境程序总应该以意图明确的方式提示用户输入数据;
- 一定要显示输入，方便用户检查数据；
- 输出有明显的标志；
4. 防故障编程
防故障程序是指无论以什么方式使用，它都能合理执行的程序。
- 防止数据输入错误
- 防止程序逻辑错误
5. 风格
- 广泛使用方法，如果一组语句多次重复执行，编写为方法;
- 使用私有数据字段，符合信息隐藏原理;
- 错误处理，检查错误，返回值或者抛出异常;
- 可读性，选择具有描述作用的标识符，通过缩进样式来增强程序的可读性；
- 文档记录，编写良好的文档，方便别人读取、使用】修改，文档的内容
  - 程序的初始注释：作用描述、作者与日期、程序输入与输出的描述、程序用法描述、所需数据类型的假设、异常描述、主要类;
  - 各个类的初始注释，声明类的作用，描述类包含的数据;
  - 各个方法的初始注释，声明方法的作用、初始条件、结束条件和调用的方法;
  - 各个方法体的注释，解释重要功能与微妙的逻辑.
6. 调试，调试埋点需要放在良好的位置，并逐步缩小范围。
- 调试方法，使用监视窗口或者System.out.println();
- 调试循环，开始与结束
- if,else,
- 使用System.out.println();
## 2.4 小结
## 2.6 自我测试题
1. 循环不变式是sum是item[0]到item[index]的和
2. 方法的uml表示法如下：+ sum(in count:int): int
## 2.7 练习题
1. effect：计算输入的美元美分扣除物品总额后的剩余美元或者美分，
    precondition：输入MAX_DOLLORx>0 x>y>0，都是浮点数，表示美元数额。
    postcondition：x-y后剩余的美元金额
2. 
    - Date plusOneDay(Date date)
    - effect desc: 计算给定日期的下一天的日期
    - precondition: Date使一个从0000-00-00开始的有效日期，表示日期
    - postcondition: 在Date的基础上+1
```java
public class Exercise2 {
    /**
     * @param date a specific day
     * @return date+1day
     */
    public LocalDate plusOneDay(final LocalDate date) {
        return date.plusDays(1);
    }
}
```
# 第3章 递归: 镜子
递归是计算机科学家使用的最强大的问题求解技术之一。
## 3.1 递归解决方案
递归是强大的问题求解技术，思想类似于自上而下将复杂的问题分解为更小的问题，而且最特殊的就是小问题与初始问题的类型完全相同。新建递归解决方案时要牢记以下4个问题
- 怎样根据同类型的更小问题来定义问题
- 各个递归调用怎样减小问题的规模
- 什么样的问题实例可以用作基例
- 随着问题规模的减小，最终能否到达基例
### 3.1.1 递归值方法：n的阶乘
箱式跟踪是跟踪递归方法的执行情况的一种系统方法。建立箱式跟踪的步骤
- 在递归方法体中标记各个递归调用，可能包含多个递归调用，使用一个独立的标记
```java
if(n == 0){
    return 1;
}else{
    return n*fact(n-1);
    // A ，递归调用后返回A点
}
```
- 执行中，使用新箱表示各个方法调用，在新箱中指示方法的局部环境;
- 绘制一个箭头，从启动递归过程的语句指向第一个箱;
- 不断生成箱子;
- 与栈一样，不断从箭头向上返回;
递归方法也存在不变式。
### 3.1.2 递归void方法
## 3.2 计数
兔子计数的问题
- 兔子产生不死
- 兔子在出生后2个月性成熟，性成熟在生命的第三个月开始
- 兔子总是雌雄配对而生，产出一对雌雄兔子
构建一个递归的方案来计算rabbit(n), 必须确定如何用rabbit(n-1)来计算rabbit(n)，rabbit(n)=n月开始前的兔子对数(rabbit(n-1))+当月产出的兔子对数，在n月初，并不是所有的的rabbit(n-1)个兔子都成熟了，只有n-2月前出生的兔子才成熟了，于是n月初产出的兔子个数是rabbit(n-2)。于是得到递归的关系是rabbit(n)=rabbit(n-1)+rabbit(n-2)。某些情况下，可以通过解决相同类型的多个更小的问题来解决初始问题。需要注意基例的问题。得到兔子的递归的定义如下:
![生兔子的问题](pic/rabbit.png)
这正好是一个斐波那契数列，java代码如下:
```java
public static int rabbit(n){
    //Computes a term in the Fibonacci sequence
    //Precondition: n is positive integer
    //PostCondition: Returns the nth Fibonacci number
    if(n<2){
        return 1;
    }else{
        return rabbit(n-1)+rabbit(n-2);
    }
```
组织游行队伍的问题，长为n的游行队伍，乐队不能相邻，有n个彩车与n个乐队，乐队-彩车，彩车-乐队是不同的排列，组织游行队伍的方法数是各排列类型的数目之和.
- P(n) 是组织长为n的排列的方法数
- F(n)是长为n，以彩车结尾的排列方法数；
- B(n)是长为n，以乐队结尾的方法数;
则P(n)=F(n)+B(n).
F(n)=P(n-1),B(n)=F(n-1)=P(n-2)，则可以得到
P(n)=P(n-1)+P(n-2).
得到的公式是：
![游行的彩车的问题](pic/parade.png)
- 可以通过分解来解决问题;
- 基例值非常重要。
Spock的困惑：访问n颗行星中的k颗，有多少中选择，不考虑访问行星的顺序。基于行星X，得到选择数
c(n,k)=包含行星X的k颗行星的组合数+不包含行星X的k颗行星的组合数
c(n,k)=c(n-1,k-1)+c(n-1,k)
若访问所有的行星那么n=k，则c(k,k)=1, 如果k=0，那么c(n,0)=1,如果k>n,c(n,k)=0，得到的公式是
![访问行星的组合的方法](pic/compose.png)
## 3.3 数组查找
分而治之就是通过分解问题，处理子问题来推进算法。binarySearch方法的代码如下:
```java
public static int binarySearch(int anArray[], int first, int last, int value){
    int index;
    if(first>last){
        index=-1;
    }
    else{
        int mid=(first+last)/2;
        if(value==anArray[mid]){
            index=mid;
        }else if(value<anArray[mid]){
            // POINT X
            index=binarySearch(anArray, first, mid-1, value);
        }else{
            // POINT Y
            index=binarySearch(anArray, mid+1, last, value);
        }
    }
    return index;
}
```
二分查找的不变式是若value出现在数组中，则anArray[first]<=value<=anArray[last]。
统计学家经常需要数据集合的中值，在已排序的集合中，中值位于集合中心，未排序的数据集合中，小于中值与大于中值的值数相同。要递归的解决一个问题，应根据一个或者多个同类型的更小问题编写解决方案，更小的概念确保能够达到基例。但是查找第k个最小项的问题与之前的问题不同，它没办法根据问题的规模决定递归，而是根据元素的值决定的。递归的解决方案如下：
- 在数组中选择枢轴项(pivot item);
- 围绕枢轴项，合理排列数组项;
- 将该策略递归的用于一个数组段.
公式是
![第k个最小项](pic/ksmall.png)
下面是伪码解决方案
```java
ksmall(in k:integer, anArray: ArrayType, in first:integer, in last:integer)
// return the kth smallest value in anArray[first...last]
choose a pivot item p fromm anArray[first...last]
partition the items of anArray[first...last] about p
if(k< pivotIndex-first+1)
    return ksmall(k,anArray,first,pivotIndex-1)
else if(k==pivotIndex-first+1)
    return p;
else return ksmall(k-(pivotIndex-first+1),anArray,pivotIndex+1,last);
```
上述问题的关键是如何选择枢轴项p以及围绕所选的p划分数组。这是快速排序的雏形。
## 3.4 组织数据
汉诺塔问题的解决方案
solveTowers(in count:integer, in source:Pole, in destination:Pole, in spare:Pole)
  if(count is 1){
      move a disk directly from source to destination
  }else{
      solveTowers(count-1, source,spare,destination);
      solveTowers(1,source,destination,spare);
      solveTowers(count-1,source,destination,spare);
  }
## 3.5 递归与效率
递归是一种强大的问题解决技术，常用于为最复杂的问题生成清晰的解决方案，易于理解与描述。递归的效率不高的2个因素：
- 与方法调用相关的开销;
- 一些递归算法的内在低效性。
只有问题没有简单的迭代解决方案递归方案才是有价值的。内在低效性与使用的求解方法有关，比如rabbit案例中，很多值被反复计算了很多次。往往迭代解决方法的效率更高，我们通常会首先想到递归方法，可以合理的转换为迭代方案，比如rabbit的迭代方案如下:
```java
public static int iterativeRabbit(int n){
    // iterative solution to the rabbit problem
    // initialize base cases
    int previous = 1;
    int current = 1;
    int next = 1;
    for(int i=3;i<=n;i++){
        next = current + previous;
        previous=current;
        current=next;
    }
    return next;
}
```
如果方法的最后一个操作是单个递归调用，称为尾递归。尾递归方法转换为迭代方式是非常方便的。
## 3.6 小结
- 递归技术通过解决相同类型的，规模更小的问题来解决问题;
- 构建递归解决方案时，需要注意以下4点:
    - 如何用相同类型的规模更小的问题来定义问题;
    - 每次递归调用怎样减少问题的规模;
    - 什么问题实例可以作为基例;
    - 随着问题规模的缩减，最终能到达基例么;
- 在构建递归解决方案时，应该假设：若递归调用的初始条件是true，则其结束条件也为true;
- 可以通过箱式跟踪递归方法的操作;
- 递归方案更容易想出来，并易于理解、描述与实现;
- 递归解决方法可以转换为迭代解决方案;
- 如果可以用迭代方法就用迭代方法.
## 3.7 自测题
# 第4章 墙
数据抽象可以增强程序的模块化.
## 4.1 抽象数据类型
模块化是增强程序可管理性的技术，组件分解、内聚、错误分离等。开发模块化程序，首先关注模块的功能是什么，不考虑其实现，这就是过程抽象。模块必须标明隐藏的信息并且保证这些信息外界无法访问，仅知道功能以及如何使用。通常问题的解决方案需要对数据进行操作，这些操作分为3类:
- 向数据集合添加数据;
- 从数据集合中删除数据;
- 提出与数据集合中的数据相关的问题;
数据抽象只关系可以对集合进行哪些操作，不关心实现；数据集合与针对这些数据的一组操作称为抽象数据类型（ADT）,有些抽象数据类型可以由编程语言直接表示，如果没法直接表示就要设计一个抽象数据类型，并用语言的一些特性实现操作。ADT并不是数据结构的别名，它们不相同: 
- ADT是指数据集合和针对这些数据的一组操作
- 数据结构是编程语言中用于存储数据集合的一种结构。
## 4.2 指定ADT
- 操作抽象;
- adt的设计应该在问题解决过程中逐步得出，下面介绍一个推演ADT的例子
1. 例子：计算给定年份中所有假日的日期，实现方案之一是查日历，以下是伪代码表示
```java
listHolidays(in year: integer)
// display the dates of all holidays in a given year
    date= date of first day of year
    while(date is before the first day of year+1){
        if(date is a holiday){
            write (date is a holiday)
        }
        date=date of next day
    }
```
该问题的数据是由年月日构成的日期，对日期数据的操作抽象有:
- 确定给定年份的第一天的日期
- 确定一个日期是否在另一个日期之前
- 确定一个是否是假日
- 确定指定日期后一天的日期.
可以定义ADT的的操作如下:
- +firstDay(in year:integer):Date {query}//return the date of the frist day of a given year
- +isBefore(in date1:Date, in date2:Date): bool {query}//
- +isHoliday(in date:Date):boolean {query}
- +nextDay(in date:Date):Date {query}
2. 例子: 约见簿，创建呢一个一年期的约见簿，上午8点到下午5点，每次30分钟。存储约见的日期、时间与性质的简单描述。定义一个ADT约见簿，数据项是约见，约见由日期、时间与目的组成，ADT的主要操作是
- 为某天、某时某目的约见
- 取消约见
- 查询给定时间是否有约见
- 确定呢给定时间约见的性质
操作如下:
- +createAppointmentBook()
- +isAppointment(in date:Date, in time:Time): boolean {query}
- +makeAppointment(in date:Date, in time:Time, in purpose: String): boolean
- +cancelAppointment(in date:Date, in time:Time): boolean
- +checkAppointment(in date:Date, in time:Time): String {query}
## 4.3 实现ADT
实现ADT时应该设计一种数据结构来表示ADT的数据，然后按照ADT操作，编写方法来访问数据，使用自上而下的方法设计ADT操作的算法，将每一次更进一步的具体描述看作对其抽象前去的实现形式，只有能使用编程语言的数据结构来表示ADT的数据这种细化过程才停止，编程语言越初级，实现级别越多。使用ADT的程序只能看到作用于数据的墙，数据的数据结构与ADT操作的实现过程都隐藏在墙后。
非面向对象的实现比如c语言，客户代码是可以随便绕过墙的，并没有严格的限制，Java等面向对象的实现因为封装、接口等机制严格限制了这种行为。
OOP编程是组件或者对象的集合，而不是操作序列，封装特性支持ADT的墙规则。
## 4.4 小结
- 数据抽象技术用于控制程序与数据结构间的交互，它在程序的数据结构周围建墙，这类似于其他模块化设计围绕程序算法建墙，使用这样的墙，可以简化程序的设计、实现、读取与修改;
- 一组数据管理操作的规范以及这些操作处理的数据值就是一个ADT;
- 对于ADT的正式数学研究采用公理系统指定ADT操作的行为;
- 只有完整定义ADT后，才能考虑如何实现ADT，为正确选择实现ADT的数据结构，要考虑ADT操作的细节，也要考虑使用操作的具体情况;
- 即使已经选择了用来实现ADT的数据结构，程序的其余部分也不应该依赖这个选择，换言之，只能通过ADT操作访问数据结构，实现过程将隐藏在ADT操作的墙之后，在Java中，未实施墙，将ADT定义为类，对使用ADT的程序隐藏ADT的实现过程;
- 对象封装数据与数据上的操作，在Java中，对象是类的实例，类是编程人员定义的数据类型;
# 第5章 链表
## 5.1 预备知识
数组不适合用来实现ADT列表，主要是由于它是定长的，而且因为物理有序，插入/删除数据需要移动数据，链表是更灵活的数据结构。
使用Java引用的ADT实现方式于数据结构都称为“基于引用”。
使用数组的方式可以使用一种变长数组的方式实现ADT列表，具体的实现方式是，当达到容量限制后，分配一个更大的数组，并复制原来数组的内容到新的数组。具体的代码如下:
```java
if (capacityIncrement == 0){
    capacity *= 2;
}else{
    capacity += capacityIncrement;
}
// now create a new array using the updated capacity value
double[] newArray = new double[capacity];
//copy the contents of the original array to the new array
for (int i = 0;i < myArray.length; i++){
    newArray[i]=myArray[i];
}
// now change th referennce to the original array to the new array
myArray=newArray;
```
java中的Vector于ArrayList都是使用这种方式实现的。
构建链表的节点定义
```java
public class Node<T extends Object> {
    
    private T item;
    
    private Node<T> next;
    
    private Node(final T item, final Node<T> next) {
        this.item = item;
        this.next = next;
    }
    
    public Node(final T item) {
        this(item, null);
    }
    
    public T getItem() {
        return item;
    }
    
    public void setItem(final T item) {
        this.item = item;
    }
    
    public Node<T> getNext() {
        return next;
    }
    
    public void setNext(final Node<T> next) {
        this.next = next;
    }
}
```
链表必须有一个head引用，要不找不到链表的其他节点。不一定基于引用来实现链表，可以使用数组来实现链表。
## 5.2 链表编程
显示链表的数据
```java
    public void display() {
        for (Node<T> curr = head; curr != null; curr = curr.getNext()) {
            System.err.println(curr.getItem());
        }
    }
```
删除链表中的节点涉及到删除中间节点与删除头节点。
```java
    public void delete(final T item) {
        Node<T> prev = null;
        Node<T> curr = head;
        while (curr != null && !Objects.equals(curr.getItem(), item)) {
            prev = curr;
            curr = curr.getNext();
        }
        if (curr != null) {
            if (prev != null) {
                // 中间节点的情况
                prev.setNext(curr.getNext());
            } else {
                //头节点的情况
                head = curr.getNext();
            }
        }
    }
```
按照index删除节点的元素
```java
    public void delete(int index) {
        Node<T> prev = null;
        Node<T> curr = head;
        while (curr != null && index-- > 0) {
            prev = curr;
            curr = curr.getNext();
        }
        if (index <= 0) {
            if (index < 0) {
                head = curr.getNext();
            } else {
                prev.setNext(curr.getNext());
            }
        }
    }
```
删除过程包含3步:
- 定位要删除的节点;
- 通过更改引用，将节点从链表中分离出来;
- 把这个节点返回给系统;

插入过程与删除过程类似，分为3个步骤:
- 确定插入位置;
- 新建一个节点，并在其中存储新数据;
- 通过更改引用，将新节点连接到链表中.
考虑有序表的情况
curr指向第一个大于newValue的节点，prev指向最后一个小与newValue的节点。查询的伪代码如下:
```java
// determine the point of insertion into a sorted linked list
// initialize prev and curr to start the traversal from the beginning of the list
prev=null;
curr=head;
// advance prev and curr as long as nenwValue>the current data item
// Loop invariant: newValue > data items in all
// holds at and before the node that prev references
while(newValue>curr.getItem()){
    prev=curr;
    curr=curr.getNext();
}
```
上述的伪代码中，当newValue大于所有的值时，curr最后一次循环是null，此时抛出空指针异常，修改如下:
```java
// determine the point of insertion into a sorted linked list
// initialize prev and curr to start the traversal from the beginning of the list
prev=null;
curr=head;
// advance prev and curr as long as nenwValue>the current data item
// Loop invariant: newValue > data items in all
// holds at and before the node that prev references
while(curr!=null&&newValue>curr.getItem()){
    prev=curr;
    curr=curr.getNext();
}
newNode.setNext(curr);
prev.setNext(newNode);
//下面的情况是链表头的情况
if(prev==null){
    head=newNode;
}
```
复用之前定义的ADT列表接口
```java
public interface ListInterface<T extends Object & Comparable<T>> {
    // list operations:
    boolean isEmpty();
    
    int size();
    
    void add(int index, T item) throws IndexOutOfBoundsException;
    
    void remove(int index) throws IndexOutOfBoundsException;
    
    T get(int index) throws IndexOutOfBoundsException;
    
    void removeAll();
}
```
基于数组与基于引用的实现的比较
基于数组的缺点：定长需要考虑ADT的最大存储个数，可能会造成空间浪费，采用变长数组也会造成空间浪费，而且复制元素比较耗时;适合列表项比较少的场景，空间浪费不严重，单节点内存少，因为下一个节点通过下标隐式得到，对特定值的访问都是O(1)时间复杂度，插入/删除节点要移动元素
基于引用的优缺点:不受长度限制，不会浪费节点空间，按需分配，访问特点节点O(n)时间复杂度，都要从头开始遍历，插入/删除节点不用移动元素。
递归方法需要头引用作为实参，不能作为类的公有成员。
## 5.3 链表的各种变体
1. 尾引用。
为了方便向链表的末尾新增元素，不需要每次都从头开始遍历，增加一个tail尾引用变量就可以了。
2. 循环链表
tail.next=head就是循环链表，前面都叫做线性链表。适合于循环访问的情况。
3. 虚拟头节点
就是在链表中head指向一个一直存在的头节点，这样，插入与删除的行为就会保持一致，不需要为第一个节点的情况做特殊考虑。
4. 双向链表
就是节点存储前驱与后继，双向链表可以做成循环双向链表。为了避免头尾节点处理的复杂性，双向链表一般都有虚拟头节点。
## 5.4 清单应用程序
## 5.6 小结
- 可以使用引用变量实现链表数据结构
- 链表中的各个引用指向链表中的下一个节点;
- 在链表中插入与删除数据的算法都涉及下列步骤：从头遍历链表，直到适当的位置，执行引用更改，改变链表结构；
- 基于数组的方式使用隐式排序方案;
- 在基于数组的实现中，可直接访问数组中的任何元素，在基于引用的实现中，必须遍历链表才能访问一个特定的节点，数组的访问时间是常量，链表的访问时间取决于节点在链表中的位置;
- 链表可以执行递归操作;
- 使用尾引用，可方便的定位链表尾，若需追加操作，者特别有用;
# 第6章 递归问题求解技术
## 回溯
一种连续猜测的组织化方法，若某种猜测行不通，则撤回，并用另一种猜测替换它，这种反向折回并试探新步骤序列的策略称为回溯（backtracking）。可以与递归操作一起来解决问题。
八皇后问题，8行8列，不能对角线，不能在同一行，同一列。使用回溯的方法解决，伪代码如下:
```java
placeQueue(in currColumn: integer)
// please queens in columns numbered currColumn through 8.
if(currColumn>8){
    the problem is solved
}else{
    while(unconsidered squares exist in currColumn and the problem is unsolved){
        determine the next square in column currColumn that
        is not under attack by a queen in an earlier column
        if( such a square exists){
            place a queen in the square
            placeQueen(currColumn+1);
            if (no queen is possible in column currColumn+1){
                remove queen from column currColumn and consider the next square in that column
            }
        }
    }
}
clear all squares on the board
if(a solution exists){
    display solution
}else{
    display message
}
```
书写的java代码如下
```java
package com.zyx.java.adt.chapter6;

/**
 * @version 1.0
 * @name: zhangyongxiang
 * @author: zhangyongxiang@baidu.com
 * @date 2022/4/21 13:04
 * @description:
 **/

public class Queens {
    // squares per row or column
    private static final int BOARD_SIZE = 8;
    
    // used to indicate an empty square
    private static final int EMPTY = 0;
    
    // used to indicate square contains a queen
    private static final int QUEEN = 1;
    
    private final int[][] board;
    
    private Queens() {
        this.board = new int[BOARD_SIZE][BOARD_SIZE];
    }
    
    /**
     * clears the board
     * Precondition: None
     * Postcondition: Sets all squares to EMPTY
     */
    public void clearBoard() {
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                board[i][j] = EMPTY;
            }
        }
    }
    
    /**
     * Display the board
     * Precondition: None
     * Postcondition: board is written to standard output; zero is an EMPTY
     * square, one is
     * a square containing a queen(QUEEN)
     */
    private void displayBoard() {
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                System.out.print(board[i][j] + "\t");
            }
            System.out.println();
        }
    }
    
    /**
     * Places queens in columns of the board beginning at the column specified
     * Precondition: Queens are placed correctly in columns 1 through column - 1
     * Postcondition: if a solution is found each column of th board contains
     * one queen and method return true;
     * otherwise returns false(no solution exists for a queen anywhere in column
     * specified)
     * 
     * @param column
     * @return
     */
    private boolean placeQueue(final int column) {
        if (column > BOARD_SIZE) {
            return true; // base case
        } else {
            boolean queenPlaced = false;
            int row = 1;
            while (!queenPlaced && row <= BOARD_SIZE) {
                // if square can be attacked
                if (isUnderAttack(row, column)) {
                    ++row; // consider next square in column
                } else {
                    setQueen(row, column);
                    queenPlaced = placeQueue(column + 1);
                    // if no queen is possible in next column
                    if (!queenPlaced) {
                        // backtrack: remove queen placed earlier and try next
                        // square in column
                        removeQueen(row, column);
                        ++row;
                    }
                }
            }
            return queenPlaced;
        }
    }
    
    /**
     * Removes a queen at quare indicated by row and column .
     * Precondition: None
     * Postcondition: Sets the square on the board in given row and column to
     * EMPTY
     * 
     * @param row
     * @param column
     */
    private void removeQueen(final int row, final int column) {
        board[row - 1][column - 1] = EMPTY;
    }
    
    /**
     * Sets a queen at square indicated by row and column.
     * Precondition: None
     * Postcondition: Sets the quare in the board in a given row and column to
     * QUEEN
     *
     * @param row
     * @param column
     */
    private void setQueen(final int row, final int column) {
        board[row - 1][column - 1] = QUEEN;
    }
    
    /**
     * Determines whether the square on the board at a given row and column is
     * under attack by any queens in the column 1 through column-1
     * Precondition: Each column between 1 and column-1 has a queen placed in a
     * square at a specific row.
     * None of thes queens can be attacked by any other queen.
     * Postcondition: If the designated square is under attack, return true,
     * otherwise return false.
     * 
     * @param row
     * @param column
     * @return
     */
    private boolean isUnderAttack(final int row, final int column) {
        final int boardRow = row - 1;
        final int boardColumn = column - 1;
        for (int i = 0; i < boardColumn; i++) {
            if (board[boardRow][i] == QUEEN) {
                return true;
            }
        }
        for (int i = 0; i < boardRow; i++) {
            if (board[i][boardColumn] == QUEEN) {
                return true;
            }
        }
        for (int i = 1; boardRow - i >= 0 && boardColumn - i >= 0; i++) {
            if (board[boardRow - i][boardColumn - i] == QUEEN) {
                return true;
            }
        }
        for (int i = 1; boardColumn - i >= 0
                && boardRow + i < BOARD_SIZE; i++) {
            if (board[boardRow + i][boardColumn - i] == QUEEN) {
                return true;
            }
        }
        return false;
    }
    
    public static void main(final String[] args) {
        final Queens queens = new Queens();
        queens.placeQueue(1);
        queens.displayBoard();
    }
}
```
## 定义语言
语言是字符串的集合，语法正确的Java集合的定义:
> JavaPropgrams = {字符串w: w是语法正确的Java程序}
语言不一定是指编程语言或者用于交流的语言，满足某些语法规则的字符串的集合都叫做语言，语法提出了语言的规则，大多的语法本质上都是递归的，一个好处是语法（确定字符串是否是给定语言）可以使用简洁的递归算法表示。这种算法叫做语言的识别算法。
1. 语法基础知识
- x|y表示x或者y
- xy表示x后接y，或者x·y，·被省略了，表示连接或者追加;
- <word>表示定义确定的word的任何实例
以JavaIds={w: w是一个有效的Java标识符}
有效的Java标识符以字母开头，后接0个或者多个字母或者数字，_或者$也算合法的字符。表示标识符定义的好的方法是使用语法图
![语法图](pic/%E8%AF%AD%E6%B3%95%E5%9B%BE.png)
或者使用文字语法表示:
> \<identifier>=\<letter>|\<identifier>\<letter>|\<identifier>\<digit>|$\<identifier>|_\<identifier>
\<letter>=a|b|...|z|A|B|...|Z
\<digit>=0|1|...|9

identifier出现在自己的定义中，所以是递归的。要确定给出的字符串w是否是JavaIds语言，识别算法：若w的长度为1且字符是字母，则w属于该语言，这个语句是基例，若w的长度大于1，w的最后一个字符是字母或者数字，且前面的字符是一个标识符，w属于该语言。伪代码如下:
```java
isId(in w:string):boolean
// returns true if w is a legal Java identifier
// otherwise returns false
if(w is of length 1){//base case
    if(w is a letter){
        return true;
    }else{
        return false;
    }
}
else if(th last character of w is a letter or a digit){
    return isId(w minus its last character);
}else{
    return false;
}
```
2. 2种简单语言
回文Palindromes={w:从左向右读与从右向左读相同}
语法的递归定义：
- w是回文
- 去掉第一个与最后一个字符的w是回文,且去掉的字符相同
基例要考虑奇偶数的情况。
回文Palindromes的语法如下:
> \<pal>=empty string|\<ch>|a\<pal>a|b\<pal>b|c\<pal>c|...|z\<pal>z
\<ch>=a|b|...|z|A|B|...|Z
识别算法的伪代码如下:
```java
isPal(in w:string):boolean
// returns true if the string w of letters is a palindrome otherwise returns false;
if(w is the empty string or w is of length 1){
    return true;
}else if(w''s first and last characters are the same letter){
    return isPal(w minus its first and last characters);
}else{
    return false;
}
```
3. 代数表达式
根据操作符所在位置的不同将代数表达式分为前、中、后缀代数表达式，完全加括号的中缀表达式通过合理的将()替换为操作符是非常方便的将中缀表达式转换为前、后缀代数表达式，前缀与后缀表达式的优点：不需要设定优先级规则、关联规则与小括号，语法简单，识别与计算表达式的算法容易编写。定义前缀代数表达式的语法为:
<前缀>=<标识符>|<操作符><前缀><前缀>
<操作符>=+｜-｜*｜/
<标识符>=a|b|...|z
可以看到是递归结构的.首先构建一个递归的值方法endPre(first,last),返回前缀表达式尾自负的索引或者如果不是前缀表达式返回-1，方法的伪代码如下:
```java
endPre(in first:integer, in last: integer)
// finds the end of a prefix expression, if one exists.
// Precondition: the substring of strExp from first through last contains no blank characters。
// Postcondition: Returns the index of the last character in strExp that begins at index first, if one exists,
// or returns -1 if no such prefix expression exists
if(first<0 or first>last){
    return -1;
}
ch=character at position first of strExp
if(ch is an identifier){
    // index of last character in simple prefix expression
    return first;
}else if(ch is an operator){
    // find the end of the first prefix expression
    firstEnd=endPre(first+1,last);
    if(firstEnd>-1){
        return endPre(firstEnd+1,last);
    }else{
        return -1;
    }
}else{
    return -1;
}
```
通过endPre确定isPre的方法的伪代码如下:
```java
isPre()
// Determines whether the string expression in this class is a prefix expression.
// Precondition: the class has a data field strExp that has been initialized with a string expression that contains no blank characters.
// Postcondition: return true if the expression is in prefix form otherwise return false.
size = length of expression strExp
lastChar = endPre(0, size - 1)
if(lastChar>=0 and lastChar == size -1 ){
    return true;
}else{
    return false;
}
```
计算前缀代数表达式的伪代码如下:
```java
evaluatePrefix(in strExp: String): float
// evaluate the prefix exprerssion strExp
// Precondition: strExp is a string consisting of a valid prefix expression containing no blanks.
// Postcondition: returns the value of the prefix expression.
ch - first character of expression strExp
delete first character of expression strExp
if(ch is an identifier){
    // base case - single identifier
    return value of the identifier;
}else{
    operand1=evaluatePrefix(strExp);
    operand2=evaluatePrefix(strExp);
    return operand1 op operand2;
}
```
定义后缀表达式的语法为:
\<后缀>=\<标识符>|\<后缀>\<后缀>\<操作符>
\<操作符>=+|-|*|/
\<标识符>=a|b|...|z
将起前缀表达式转换为后缀表达式的方法的伪代码如下:
```java
convert(in pre: string):string
// Converts a prefix expression pre to postfix form
// Precondition: The expression inn the string pre is a valid prefix expression
// PostCondition: Returns the equivalent postfix expression as a string
//check the first character of the given string
ch = first character of pre
delete first character of pre
if(ch is a lowercase letter){
    // base case - single identifier expression
    return ch as a string
}else{
    // do the conversion resursively
    postfix1=convert(pre)
    postfix2=convert(pre)
    return postfix1+postfix2+ch;
}
```
## 归纳和数学归纳法的关系
递归与数学归纳法之间存在密切关系，通过递归解决问题时，要指定一个或者多个基例的解，然后考虑如何从同类型的更小的问题的解道出任意搭戏哦问题的解。数学归纳法与此类似，通过证明基例（0或1）的属性，然后证明如果对于小与N的自然数，该属性为证真，对于任意自然数N，该属性必为真，从而证明自然数的属性。
经常用归纳来证明递归算法的正确性。
以下伪代码描述的递归算法实现的阶乘
```java
fact(in n:integer):integer
if(n is 0 ){
    return 0;
}else{
    return n*fact(n-1);
}
```
fact会下下列值
>fact(0)=0!=1 n=0
fact(n)=n!=n*(n-1)*...*1 n>0

- 基例：n=0时属性为真
现在要证明对于任意的k，属性为真，则对于k+1，属性为真
- 归纳假设：对于任意数n=k，属性为真即fact(k)=k(k-1)....1
- 归纳结论，对于n=k+1,属性为真，也就是证明fact(k+1)=(k+1)k(k-1)....1
根据fact方法定义，fact(k+1)=(k+1)*fact(k)=(k+1)k(k-1)....1， 证毕
前面介绍过汉诺塔问题的解决方案，基本算法的伪代码如下:
```java
solveTowers(in count:integer, in source:Pole, in destination:Pole, in spare:Pole)
if(count is 1){
    move a disk directly from source to destination
}else{
    solveTowers(count-1, source, spare, destination);
    solveTowers(1, source, destination, spare);
    solveTowers(count-1, spare, destination, source);
}
```
设 moves(N)是N个圆盘的移动次数，当N=1时，moves(N)=1
moves(N)=moves(N-1)+moves(1)+moves(N-1)=2<sup>N</sup>-1，下面根据数学归纳法证明这个公式
- 基例: N=1时 2<sup>1</sup>-1=1，所以属性为真，下面要证明，对于任意的数k，属性为真，那么对于k+1，属性为真。
- 归纳假设: 设对于任意的数N=k，属性为真，即moves(k)=2<sup>k</sup>-1;
- 归纳结论: 说明N=k+1属性为真，必须证明moves(k+1)=2<sup>k+1</sup>-1, 根据moves的递归关系
moves(k+1)=2moves(k)+1=2*(2<sup>k</sup>-1)+1=2<sup>k+1</sup>-1.证毕。
## 小结
- 回溯是一种解决问题的策略，涉及递归及一系列最终导出解的猜测，如果某种猜测行不通，则反向折回，替换猜测，并再次试探完成解决方案;
- 语法是定义语言的工具，语言是一个符号串集合，使用语法定义语言，经常可以构建直接基于语法的识别算法，语法通常都是递归的，因此可以简明扼要的描述大量语言;
- 代数表达式语言存在好几种，各有优劣，前缀与后缀表达式难于使用，但是语法简单，还消除了二义性。中缀表达式易于使用，但是需要括号、关联规则与优先级规则等，语法复杂;
- 数学归纳法与递归有密切的关系，可以用归纳来证明递归算法的正确性。
- 解决递归类问题的2种方案1.数学归纳法与2.循环不变式。
# 第7章 栈
栈具有后进先出的特点，栈与递归存在重要的关系。
## ADT 栈
在设计问题的解决方案时，可推演出用于解决问题的抽象数据类型的规范。
考虑打字场景\<-表示backspace就是退格。
>abcc\<-ddde\<-\<-\<-ef\<-fg

如何读取输入行并获得正确的输入，设计解决方案时，必须涉及到存储输入行的环节，先根据解决方案定义数据存储上的操作，初始的解决方案可能如下:
```java
// read the line, correcting mistake along the way
while(not end of line){
    Read a new character ch
    if(ch is not a '<-'){
        add ch to adt
    }else{
        remove from the adt the item added most recently
    }
}
```
得到ADT应该包含的操作:
- 向ADT添加新项;
- 从ADT中删除最近添加的项;
需要判断当ADT为空时，继续\<-的后果，结果就是什么也不操作,如果要倒叙展示输入的文字，则还要检索数据项
```java
// read the line, correcting mistake along the way
while(not end of line){
    Read a new character ch
    if(ch is not a '<-'){
        add ch to adt
    }else if(ADT is not empty){
        retrieve from adt the item added most recently and put it in ch
        write ch
        remove from the adt the item added most recently
    }else{
        ignore <-
    }
}
```
ADT的操作
- 确定ADT是否为空
- 从ADT中检索最近加入的项
这就是栈，栈包含的主要的操作
- 创建一个空栈
- 确定栈是否为空
- 向栈中加入新项;
- 从栈中删除最近加入的项;
- 从栈中检索最近加入的项;
- 从栈中删除所有项;
栈的伪代码表示
```java
// StackItemType is the type of the items stored in the stack
+createStack()
// create a empty stack
+isEmpty():Boolean {query}
// determines whether a stack is empty
+push(in newItem:StackItemType) throws StackException
// adds newItem to the top of the stack, throws StackException if the insertion is not successful
+pop():StackItemType throws StackException
// retrieves and then removes the top of the stack(the item that was added most recently).
// throws StackException if the deletion is not successful
+popAll()
// removes all items from the stack
+peek():StackItemType throws StackException
// retrieves the top of the stack. that is, peek retrieves the item that was added most recently.
// retrieves dose not change the stack, throws StackException if the retrieval is not successful
```
UML图就忽略了。
## ADT栈的简单应用
1. 检查括号匹配
匹配的条件
- 每遇到一个}都有前面遇到的{匹配;
- 达到字符串结尾时，各个{都有相应的匹配;
伪代码的解决方案如下:
```java
aStack.createStack();
balancedSoFar=true;
i=0;
while(balancedSoFar and i \< length of aString){
    ch=character at position i in aString
    ++i;
    // push an open brace
    if(ch is '{'){
        aStack.push('{');
    }
    // close brace
    else if(ch is '}'){
        if(!aStack.isEmpty()){
            openBrace=aStack.pop();
        }else{
            balancedSoFar=false;
        }
    }
}
if(balancedSoFar and aStack.isEmpty()){
    aString is balanced braces
}else{
    aString dose not have balanced brances;
}
```
更简单的解决方案：跟踪当前未匹配的左大括号的数目。
防故障编程: 
2. 识别语言中的字符串
识别某个字符串是否在下面的语言中
> L={w$w': w是除$外的字符串，w可能为空，w'=reverse(w)}

类似于回文，可以用栈解决下面是伪代码
```java
aStack.createStack();
// push the characters before $, that is the character in w onto the stack
i=0;
ch=character at position i in aString
while(ch is not '$'){
    aStack.push(ch)
    ++i;
    ch=character at position i in aString
}
// skip the $
++i;
// match the reverse of w
inLanguage=true;// assume string is in Language
while(inLanguage and i < length of aString>){
    ch=character at position i in aString
    try{
        stackTop=aStack.pop();
        if(stackTop equals ch){
            ++i;//characters match
        }else{
            // top of stack is not ch
            inLanguage=false;
        }
    }
    catch(StackException e){
        // aStack.pop() failed, aStack is empty(first half of string is shorter than second  half)
        inLanguage=false;
    }
}
if(inLanguage and aStack.isEmpty()){
    aString is in language
}else{
    aString is not in language;
}
```
## ADT栈的实现
定义接口规范
```java
package com.zyx.java.adt.chapter7;
public interface StackInterface<T> {
    /**
     * determines whether the stack is empty.
     * Precondition: None
     * Postcondition: Returns true if the stack is empty otherwise returns
     * false.
     * 
     * @return true or false
     */
    boolean isEmpty();
    
    /**
     * removes all the items from the stack.
     * Precondition: None
     * Postcondition: Stack is empty.
     */
    void popAll();
    
    /**
     * add an item to the top of a stack
     * Precondition: newItem is the item to be added
     * Postcondition: If insertion is successful, newItem is on the top of the
     * stack.
     * Exception: Some implementations may throw Stackexception when newItem
     * cannot be placed on the stack.
     * 
     * @param newItem
     * @throws StackException
     */
    void push(T newItem) throws StackException;
    
    /**
     * remove the top of a stack.
     * Precondition: None.
     * Postcondition: if the stack is not empty, the item that was added most
     * recently is removed from the stack and returned.
     * Exception: Throws StackException if the stack is empty.
     * 
     * @return
     * @throws StackException
     */
    T pop() throws StackException;
    
    /**
     * retrieves the top of a stack.
     * Precondition: none.
     * Postcondition: if the stack is not empty, the item that was added most
     * recently is returned. the stack ias unchanged.
     * Exception: Throws StackException if the stack is empty.
     * 
     * @return
     * @throws StackException
     */
    T peek() throws StackException;
    
}
```
1. 基于数组的实现
```java
package com.zyx.java.adt.chapter7;

/**
 * @version 1.0
 * @name: zhangyongxiang
 * @author: zhangyongxiang@baidu.com
 * @date 2022/5/26 02:02
 * @description:
 **/

public class StackArrayBased<T> implements StackInterface<T> {
    private final int MAX_STACK = 50;
    private T items[];
    private int top;
    
    public StackArrayBased() {
        items = (T[]) new Object[MAX_STACK];
        top = -1;
    }
    
    @Override
    public boolean isEmpty() {
        return top < 0;
    }
    
    @Override
    public boolean isFull() {
        return top == MAX_STACK - 1;
    }
    
    @Override
    public void popAll() {
        top = -1;
    }
    
    @Override
    public void push(final T newItem) throws StackException {
        if (!isFull()) {
            items[++top] = newItem;
        } else {
            throw new StackException("stack full");
        }
    }
    
    @Override
    public T pop() throws StackException {
        if (!isEmpty()) {
            return items[top--];
        } else {
            throw new StackException("stack empty");
        }
    }
    
    @Override
    public T peek() throws StackException {
        if (!isEmpty()) {
            return items[top];
        } else {
            throw new StackException("stack empty");
        }
    }
}
```
2. 基于引用的实现
```java
package com.zyx.java.adt.chapter7;

import com.zyx.java.adt.chapter5.Node;

/**
 * @version 1.0
 * @name: zhangyongxiang
 * @author: zhangyongxiang@baidu.com
 * @date 2022/5/26 02:14
 * @description:
 **/

public class StackReferenceBased<T extends Comparable<T>>
        implements StackInterface<T> {
    
    private Node<T> top;
    
    public StackReferenceBased() {
        top = null;
    }
    
    @Override
    public boolean isEmpty() {
        return top == null;
    }
    
    @Override
    public boolean isFull() {
        return false;
    }
    
    @Override
    public void popAll() {
        top = null;
    }
    
    @Override
    public void push(final T newItem) {
        top = new Node<>(newItem, top);
    }
    
    @Override
    public T pop() throws StackException {
        if (!isEmpty()) {
            final Node<T> temp = top;
            top = top.getNext();
            return temp.getItem();
        } else {
            throw new StackException("stack empty");
        }
    }
    
    @Override
    public T peek() throws StackException {
        if (!isEmpty()) {
            return top.getItem();
        } else {
            throw new StackException("stack empty");
        }
    }
}

```
3. 使用ADT列表的实现
```java
package com.zyx.java.adt.chapter7;

import com.zyx.java.adt.chapter5.LinkedList;
import com.zyx.java.adt.chapter5.ListInterface;

/**
 * @version 1.0
 * @name: zhangyongxiang
 * @author: zhangyongxiang@baidu.com
 * @date 2022/5/26 02:21
 * @description:
 **/

public class StackListBased<T extends Comparable<T>>
        implements StackInterface<T> {
    
    private ListInterface<T> list;
    
    public StackListBased() {
        list = new LinkedList<>();
    }
    
    @Override
    public boolean isEmpty() {
        return list.isEmpty();
    }
    
    @Override
    public boolean isFull() {
        return false;
    }
    
    @Override
    public void popAll() {
        list.removeAll();
    }
    
    @Override
    public void push(final T newItem) throws StackException {
        list.add(1, newItem);
    }
    
    @Override
    public T pop() throws StackException {
        if (!isEmpty()) {
            final T temp = list.get(1);
            list.remove(1);
            return temp;
        } else {
            throw new StackException("stack empty");
        }
    }
    
    @Override
    public T peek() throws StackException {
        if (!isEmpty()) {
            return list.get(1);
        } else {
            throw new StackException("stack empty");
        }
    }
}
```
4. 各种实现的比较
归根结底，ADT的实现都是基于数组或者基于引用。数组实现有容量限制。
## 应用: 代数表达式
1. 计算后缀表达式
ADT栈可以非常方便的解决后缀表达式，伪代码如下:
```java
for(each character ch in the string){
    if(ch is an operand){
        push value that operand ch represents onto stack
    }else{//ch is an operator named op
        //evaluate and push the result
        operand2=pop the top of the stack;
        operand1=pop the top of the stack;
        result=operand1 op operand2
        push result onto stack
    }
}
```
2. 将中缀表达式转换为后缀表达式
中缀表达式转换为后缀表达式的3个事实
- 操作数的先后顺序保持不变;
- 操作符相对于操作数只向右移；
- 删除所有小括号;
收腰任务是如何放置操作符。一种初始的方案为:
```java
initialize postfixExp to the null string
for(each character ch in the infix expression){
    switch(ch){
        case ch is an operand:
           append ch to the end of postfixExp;
           break;
        case ch is an operator:
           store ch until you know where to place it;
           break;
        case ch is '(' or ')':
           discard ch
           break;
    }
}
```
>小括号表示的含义是计算子表达式的值，忽略内部细节

考虑小括号、优先级与从左到右关联的中缀表达式的步骤
- 遇到操作数时，追加到postfixExp后面，后缀表达式操作数的顺序与在中缀表达式中一样；
- 使'('入栈;
- 遇到操作符时，若栈为空，操作符入栈，若非空，则使优先级更高的操作符出栈追加到postfixExp后面，遇到(或者优先级更低或者栈空时，停止，使新的操作符入栈，优先级相同，也要出栈，因为这是从左到右的规则;
- 遇到')'时，操作符出栈追加到postfixExp后，直到遇到匹配的'('为止；
- 到达字符串尾，将栈的剩余内容追加到postfixExp后面.
伪代码的解决方案是:
```java
initialize postfixExp to the null string
for(each character ch in the infix expression){
    switch(ch){
        case ch is an operand:
           postfixExp=postfixExp+ch
           break;
        case '(': //save '(' on stack
           aStack.push(ch);
           break;
        case ')':// pop stack until matching '('
           while(top of stack is not '('){
                postfixExp=postfixExp+aStack.pop();
           }
           openParen=aStack.pop();//remove open parenthesis
           break;
        case ch is an operator://process stack operators of greater precedence
           while(!aStack.isEmpty() and top of stack is not '(' and precedence(ch)<=precedence(top of stack)){
               postfixExp=postfixExp+aStack.pop();
           }
           aStack.push(ch);//save new operator
           break;
    }
}
// append to postfixExp the operators remaining in the stack
while(!aStack.isEmpty()){
    postfixExp=postfixExp+aStack.pop();
}
```
## 应用: 查找问题
对于每个客户请求，找出一个从始发城市到目的城市的航班，有3个文件:
- 城市名字;
- 城市名对，每对表示一个航班的始发城市和目的城市;
- 城市名对，每对表示一个始发城市到目的城市的请求;
![航班图数据](pic/flight-graph.png)
C1->C2表示C2与C1邻接，称为有向路径，但是C1不是与C2邻接的。
1. 使用栈的非递归解决方案
开发使用穷举算法，也就是尝试没种可能的航班。也就是回溯法，深度遍历类似。就是不断折返。算法的伪代码如下:
```java
aStack.createStack();
aStack.push(originCity);// push origin city onto stack
while(a sequence of flights from the origin to the destination has not been found){
    if(you need to backtrack from the city on the top of the stack){
        temp=aStack.pop();
    }else{
        select a destination city C for s flight from the city on the top of the stack;
        aStack.push(C)
    }
}
```
while循环的不变式是`栈包含从栈底城市出发到栈顶城市的有向路径`，已经访问过的城市无序再次访问，因为有2种情况
- 可能是一个loop，那么可以忽略loop,直接访问;
- 当前访问的节点的下游路径都已经尝试过，不能到达目的地，无序再次尝试;
所以需要对访问过的节点做标记,新的算法如下:
```java
aStack.createStack();
clear marks on all cities
aStack.push(originCity);// push origin city onto stack
mark the origin as visited
while(a sequence of flights from the origin to the destination has not been found){
    if(no flights exist from the city on the top of the stack to unvisited cities){
        temp=aStack.pop();
    }else{
        select a destination city C for s flight from the city on the top of the stack;
        aStack.push(C);
        mark C as visisted;
    }
}
```
判断循环的终止条件
```java
+searchS(in originCity: city, in  destinationCity:city)
// searches for a sequence of flights from originCity to destinationCity
aStack.createStack();
clear marks on all cities
aStack.push(originCity);// push origin city onto stack
mark the origin as visited
while(!aStack().isEmpty() and destination city is not at the top of the stack){
    if(no flights exist from the city on the top of the stack to unvisited cities){
        temp=aStack.pop();
    }else{
        select a destination city C for s flight from the city on the top of the stack;
        aStack.push(C);
        mark C as visisted;
    }
}
return !aStack.isEmpty();
```
可以将航班图抽象为一个ADT，这个ADT的操作有：将数据放入航班图、插入一个城市的临接城市、显示航班图、显示所有城市的列表、显示给定城市的所有临接城市、查找出发城市到目的城市的路径等。UML表示如下:
+createFlightMap();
// creates an empty flight map
+readFlightMap(in cityFileName:string, in flightFileName:string )
// reads flight information into the flight map
+displayFlightMap() {query}
// display flight information
+displayAllCities() {query}
// displays the names of all cities that HPAir serves
+displayAdjacentCities(in aCity:City) {query}
// display all cities that are adjacent to a given city
+markVisisted(in aCity:City)
// marks a city as visited
+unvisitAll()
// clears marks on all cities
+isVisited(in aCity:City):boolean {query}
// determines whether a city was visited
+insertAdjacent(in aCity:City, in asjCity: City)
// insert a city adjacent to another city in a flight map
+getNextCity(in fromCity:City, out nextCity:City):boolean
// returns the next unvisited city, if any, that is adjacent to a given city, returns true if an unvisited adjacent city was found, false otherwise
+isPath(in originCity:City, in destinationCity:City):boolean
// determines whether a sequence of flights exists between two cities
下面的java方法使用searchS算法实现isPath，使用Map存储航班图
```java
public boolean isPath(City originCity, City destinationCity){
/**
 * determines whether a sequence of flights between two cities exists.Nonrecursive stack version.
 * Precondition: originCity and destinationCity are the origin and destination cities, respectively.
 * Postcondition: return true if originCity to desitnationCity, otherwise returns false. cities visited during the
 * search are marked as visited in th flight map.
 * implementation notes: uses a stack for the cities of a potential path. calls unvisitAll, markVisited, and getNextCity
 */
 StackReferenceBased stack=new StackReferenceBased();
 City topCity, nextCity;
 stack.push(originCity);
 markVisited(originCity);
 topCity=stack.peek();
 while(!stack.isEmpty()&&topCity.compareTo(destinationCity)!=0){
     // loop invariant: stack contains a directed path from the origin city at the bottom of the stack to the city at the top of the stack
     // find an unvisited city adjacent to the city on the top if the stack
     nextCity=getNextCity(topCity);
     if(nextCity==null){
         stack.pop();
     }else{
         stack.push(nextCity);
         markVisited(nextCity);
     }
      topCity=stack.peek();
 }
 return !stack.isEmpty();
}
```
2. 递归解决方案
```java
public boolean isPath(City originCity, City destinationCity){
    City nextCity;
    boolean done;
    markVisited(originCity);
    // base case: the destinationCity is reached
    if(originCity.compareTo(destinationCity) == 0){
        return true;
    }else{// try a flight to each unvisited city
        done=false;
        nextCity=getNextCity(originCity);
        while(nextCity!=null&&!done){
            done=isPath(nextCity,destinationCity);
            if(!done){
                nextCity=getNextCity(originCity);
            }
        }
        return done;
    }
}
```
## 栈和递归的关系
ADT栈隐含递归概念，总是可以用栈来完成递归方法的操作。
## 小结
- ADT栈有后进先出的特性;
- 栈可以非常方便的计算后缀代数表达式;
# 第8章 队列
队列先进先出，通常用于解决涉及等待的问题。
## ADT队列
队列类似于人员排队，队列的操作只在2端发生，具有FIFO特性，包含的操作
## ADT队列的简单应用
1. 读取字符串
2. 识别回文
## 实现
1. 基于引用的实现
使用线性链表，
```java
public class QueueReferenceBased<T extends Comparable<T>>
        implements QueueInterface<T> {
    
    private Node<T> lastNode;
    
    private QueueReferenceBased() {
        this.lastNode = null;
    }
    
    @Override
    public boolean isEmpty() {
        return lastNode == null;
    }
    
    @Override
    public void enqueue(final T newItem) throws QueueException {
        final Node<T> newNode = new Node<>(newItem);
        if (isEmpty()) {
            newNode.setNext(newNode);
        } else {
            newNode.setNext(lastNode.getNext());
            lastNode.setNext(newNode);
        }
        lastNode = newNode;
    }
    
    @Override
    public T dequeue() throws QueueException {
        if (!isEmpty()) {
            final Node<T> firstNode = lastNode.getNext();
            if (firstNode == lastNode) {
                lastNode = null;
            } else {
                lastNode.setNext(firstNode.getNext());
            }
            return firstNode.getItem();
        } else {
            throw new QueueException("empty queue");
        }
    }
    
    @Override
    public void dequeueAll() {
        this.lastNode = null;
    }
    
    @Override
    public T peek() throws QueueException {
        if (!isEmpty()) {
            
            return lastNode.getNext().getItem();
        } else {
            throw new QueueException("empty queue");
        }
    }
    
    public static void main(final String[] args) throws QueueException {
        final QueueInterface<Integer> queue = new QueueReferenceBased<>();
        
        for (int i = 0; i < 9; i++) {
            queue.enqueue(i);
        }
    }
}
```
2. 基于数组的实现
队列的基于数组的实现可以实现循环队列，需要有一个front与end指针。一般使用环形数组，也就是循环数组。困难时检测队列为空还是满，因为队列为空与满的状态都是一样的，都是front超过end一个位置。使用模运算完成循环队列的增加.
- 有一种办法区分就是记录队列中的项数；
- 使用full标志;
- 留一个位置用于标志位，这个位置代表队头位置，就是表示head，这个head就是一直是无效数据的，因为数据已经在最近一次操作中移走了，当(back+1)%(MAX_QUEUE+1)时，则队列满，当front==back时，队列空。
```java
public class QueueArrayBased<T> implements QueueInterface<T> {
    
    private static final int MAX_QUEUE = 50;// maximum size of queue
    
    private final Object[] items;
    
    private int front;
    private int back;
    private int count;
    
    public QueueArrayBased() {
        this.items = new Object[MAX_QUEUE];
        front = 0;
        back = MAX_QUEUE - 1;
        count = 0;
    }
    
    @Override
    public boolean isEmpty() {
        return count == 0;
    }
    
    private boolean isFull() {
        return count == MAX_QUEUE;
    }
    
    @Override
    public void enqueue(final T newItem) throws QueueException {
        if (!isFull()) {
            back = (back + 1) % MAX_QUEUE;
            items[back] = newItem;
            ++count;
        } else {
            throw new QueueException("queue is full");
        }
    }
    
    @Override
    public T dequeue() throws QueueException {
        if (!isEmpty()) {
            final T element = (T) items[front];
            front = (front + 1) % MAX_QUEUE;
            --count;
            return element;
        } else {
            throw new QueueException("queue is empty");
        }
    }
    
    @Override
    public void dequeueAll() {
        front = 0;
        back = MAX_QUEUE - 1;
        count = 0;
    }
    
    @Override
    public T peek() throws QueueException {
        if (!isEmpty()) {
            return (T) items[front];
        } else {
            throw new QueueException("queue is empty");
        }
    }
}
```
3. 使用ADT列表的实现
ADT列表可以实现队列。队列头表示元素1，队列尾表示元素list.size()+1.
```java
public class QueueListBased<T extends Comparable<T>>
        implements QueueInterface<T> {
    
    private final ListInterface<T> list;
    
    public QueueListBased() {
        list = new LinkedList<>();
    }
    
    @Override
    public boolean isEmpty() {
        return list.isEmpty();
    }
    
    @Override
    public void enqueue(final T newItem) throws QueueException {
        list.add(list.size() + 1, newItem);
    }
    
    @Override
    public T dequeue() throws QueueException {
        if (!isEmpty()) {
            final T element = list.get(1);
            list.remove(1);
            return element;
        } else {
            throw new QueueException("queue is empty");
        }
    }
    
    @Override
    public void dequeueAll() {
        list.removeAll();
    }
    
    @Override
    public T peek() throws QueueException {
        if (!isEmpty()) {
            return list.get(1);
        } else {
            throw new QueueException("queue is empty");
        }
    }
}
```
4. JCF接口Queue
JCF提供了Queue接口，继承与Collection接口，还添加了一些自己的方法:
- poll()与remove()移除队头，如果为空，poll()返回null，remove()抛出异常;
- element()与peek()检索队头，如果为空，element()抛出异常，peek()返回null;
- add()与offer()添加元素，添加失败时，add()返回未检查异常，offer()返回false;
Queue的实现有LinkedList与PriorityQueue，LinkedList用作队列实现要注意，LinkedList允许元素为null，poll返回null的时候要注意区分，确认队列的大小，最好不要有null元素。
5. 比较实现
## 基于位置的ADT概览
## 模拟应用
## 小结
- 队列操作的定义使ADT队列具有先进先出的特性;
- 队列的插入与删除操作需要高效的访问队列的2端，因此，队列的基于引用的实现使用循环链表、包含头引用与尾引用的线性链表;
- 队列的基于数组的实现存在右向移动的倾向，使得队列满了实际却不满，最好的方式是使用循环队列;
- 如果使用循环数组实现队列，需要能够判断队空还是队满，可以对队列计数、使用full标志、保持一个数组位置为标识位;
- 现实系统的模型常使用队列，特别是事件驱动的程序;
# 第9章 高级Java主题
## 继承
继承指一个类从以前的类继承属性的能力，实际是类之间的关系，通过继承，定义新类时可以重用已经开发的软件组件，不能直接访问超类的私有成员，Java有4中访问修饰符级别，代表不同的访问权限。类有2种基本的关系:
- is-a, 继承就是is-a的关系， 可以用子类实例替换超类实例，这是完全兼容的;
- has-a, 包含关系。
## 动态绑定与抽象类
多态性就是根据实际运行对象决定行为而不是编译时确定，也叫做动态绑定。
## ADT列表与有序表
## Java范型
基本类型不能作为范型类型的参数，范型类型不能实例化数组。？代表未知的类型，是作为范型通配符存在的。注意extends与super的区别，以及结合?的使用.
## 迭代器
迭代器是一个可以访问对象集合的对象，当是每次只访问一个对象，迭代器遍历对象集合中的每个对象。
## 小结
- 类可以有超类也可以有子类，子类继承前面定义的超类的所有成员，但是只能访问公有与受保护的成员，子类只能通过超类的方法访问私有成员，类与子类的方法都可以访问受保护的成员;
- 在继承时，超类的公有与受保护成员依然是子类的公有与受保护成员，这样的子类与超类兼容，可使用超类的地方就可以使用子类的实例，超类与子类之间存在is-a关系;
- 如果子类的方法与超类的方法具有相同的参数声明，则子类的方法重写超类的方法，若超类将一个方法声明为final，则不能重写;
- 类的抽象方法可以在子类中实现;
# 第10章 算法的效率与排序
在计算机科学的高级主题中，分析算法的基本数学技术占重要位置，可用来规范的证明一个算法优于另一个算法.
## 确定算法的效率
需要在算法的效率与可维护性方面取得平衡，算法分析是用来比较不同解决方法的效率的工具，算法的效率在解决方案的总成本中占支配地位，算法的效率主要看时间与空间占用，时间效率是重点。时间效率的比较:
- 应独立于代码实现;
- 独立于运行的计算机;
- 独立于使用的数据
1. 算法的执行时间
算法的执行时间与它所需要的操作次数有关，统计算法的操作次数是估算算法效率的方式。
2. 算法增率
算法的时间要求按照规模比例变化，称为增率（growth rate），这种方式独立于计算机与代码实现等因素，可用于客观的评估算法的优劣。
3. 数量阶分析和大$O$表示法
如果算法A需要的时间与$f(n)$成正比，则称$f(n)$阶，表示为$O(f(n))$，函数$f(n)$称为算法的增率函数(growth-rate function)，该表示法使用大写字母$O$来表示阶(order)，故称为大$O$表示法，若规模为$n$的问题需要的时间与$n$成正比，则问题表示为$O(n)$。若存在常量$k$与$n_0$，使算法A在解决问题规模$ n\geq {n}_{0} $的问题时，需要的时间单元不大于$k*f(n)$，则算法A为$f(n)$阶，表示为$O(f(n))$。
常见增率函数按增速排列:
$$ O(1)<O({log}_{2}n)<O(n)<O(n*{log}_{2}n)<O({n}^{2})<O({n}^{3})<O({2}^{n}) $$
- $O(1)$, 问题的时间要求恒定不变，不受问题规模n的影响
- $O(log_2n)$，问题的规模增加时，对算法的时间要求将缓慢增加
- $O(n)$，随问题规模的增加而增加
- $O(n*log_2n)$，比线性的快
- $O(n^2)$，随问题规模的增加而快速的增加，通常是2个循环这种;
- $O(n^3)$，比上面的·更快
- $O(2^n)$，穷举法，增长速率快

对大问题，算法的效率主要由增率决定。
- 可忽略算法增率函数的低阶项;
- 可忽略算法增率函数中的高阶项的倍数常量;
- $O(f(n)) + O(g(n))=O(f(n)+g(n))$ 可组合增率函数

问题的规模相同，可能问题不同，时间要不同，算法分最坏情况与平均情况。
- 最坏情况分析(worst-case analysis)
- 平均情况分析(average-case ananlysis)

4. 正确分析问题
最适当的ADT实现主要取决于应用程序执行操作的频率。只有在问题规模足够大的情况下，算法的增率才有意义，规模小，随便哪种实现都差不多。算法要在执行时间要求与存储空间要求之间做权衡，只考虑效率的显著的差别，

5. 查找算法的效率

## 排序算法及其效率
排序是指按升序或降序组织数据集合的过程，算法分2类:
- 内部排序，数据集合全部在内存中
- 外部排序，不全在内存中

### 选择排序
类似于扑克牌排序过程，查找剩余元素的最大项与最后一个元素交换，然后递归处理剩余的未排序的元素。直到最后剩余一个元素就不需要处理了。
java代码如下:
```java
/**
     * sorts the items in an array into ascending order.
     * Precondition: theArray is an array of n items
     * Postcondition: theArray is sorted into ascending order.
     * 
     * @param theArray
     * @param n
     * @param <T>
     */
    public static <T> void selectionSort(final Comparable<T>[] theArray,
            final int n) {
        for (int last = n - 1; last >= 1; last--) {
            final int largest = indexOfLargest(theArray, last);
            final Comparable<T> tmp = theArray[largest];
            theArray[largest] = theArray[largest];
            theArray[largest] = tmp;
        }
    }
    
    /**
     * Finds the largest item in an array
     * Precondition: theArray is an array of size items
     * size>=1
     * 
     * @param theArray
     * @param maxIndex
     * @return
     * @param <T>
     */
    private static <T> int indexOfLargest(final Comparable<T>[] theArray,
            final int maxIndex) {
        int largest = 0;
        for (int index = largest; index <= maxIndex; index++) {
            if (theArray[index].compareTo((T) theArray[largest]) > 0) {
                largest = index;
            }
        }
        return largest;
    }
```
选择排序的增率函数是$O(n^2)$，排序算法中的基本操作室比较、交换与移动元素，考虑这3种操作的次数，因为Java是引用的方式，所以只有比较操作的成本最好，移动与交换成本不高，不依赖数据肚饿初始的顺序，只适用较小的n值。
### 冒泡排序
冒泡排序比较相邻项，若为逆序就交换它们。代码如下:
```java
    /**
     * sorts the items in an array into ascending order.
     * Precondition: theArray is an array of n items
     * Postcondition: theArray is sorted into ascending order.
     * 
     * @param theArray
     * @param n
     * @param <T>
     */
    public static <T> void bubbleSort(final Comparable<T>[] theArray,
            final int n) {
        
        boolean sorted = false;
        
        for (int pass = 1; pass < n && !sorted; pass++) {
            sorted = true;
            for (int index = 0; index < n - pass; index++) {
                final int nextIndex = index + 1;
                if (theArray[index].compareTo((T) theArray[nextIndex]) > 0) {
                    swap(theArray, index, nextIndex);
                    sorted = false;
                }
            }
        }
    }
```
冒泡排序最坏情况下是$O(n^2)$时间复杂度，最好情况下就是已经有序，此时执行$n-1$次比较，时间复杂度是$O(n)$.
### 插入排序
插入排序将数据分为已排序区域与未排序区域，每次从未排序区域取出一个值放到已排序的区域，直到未排序区域的元素为空，第一次时theArray[0]就是已排序区域了，因为只有一个元素。代码实现如下：
```java
    /**
     * sorts the items in an array into ascending order.
     * Precondition: theArray is an array of n items
     * Postcondition: theArray is sorted into ascending order.
     *
     * @param theArray
     * @param n
     * @param <T>
     */
    public static <T> void insertionSort(final Comparable<T>[] theArray,
            final int n) {
        for (int unsorted = 1; unsorted < n; unsorted++) {
            final Comparable<T> nextItem = theArray[unsorted];
            int loc = unsorted;
            while (loc > 0 && nextItem.compareTo((T) theArray[loc - 1]) < 0) {
                theArray[loc] = theArray[loc - 1];
                loc--;
            }
            theArray[loc] = nextItem;
        }
    }
    
```
插入排序的阶是$O(n^2)$。对于小于25个项的数组，插入排序简单易行，超过这个数，增率比较大。
### 归并排序
归并排序与快速排序是2种重要的分而治之排序算法。归并排序也适用于外部文件。归并排序是一种递归排序算法。无论原始顺序如何，归并排序性能不变，将数据一分为2，2个子数组排序，排好后，通过临时数组的方式将2个子数组合并。归并排序的伪代码如下:
```java
+mergeSort(inout theArray: itemArray, in first:integer, in last:integer)
// sorts theArray[first...last] by 
// 1. sorting the first half of the array
// 2. sorting the second half of the array
// 3. merging the two sorted halves
if(first<last){
    mid=(first+last)/2
    mergesort(theArray, first, mid)
    mergesort(theArray, mid+1, last)
    merge(theArray, first, mid last)
}
```
java代码如下:
```java
    /**
     * merges two sorted array segments theArray[first...mid] and
     * theArray[mid+1...last] into one sorted array.
     * Precondition: first<=mid<=last. the subarrays theArray[first...mid] and
     * theArray[mid+1...last]
     * are each sorted in increasing order.
     * Postcondition: theArray[first...last] is sorted.
     * Implementation note: This method merges the two subarrays
     * into a temporary array and copies the result into the original arrat
     * anArray.
     * 
     * @param theArray
     * @param first
     * @param mid
     * @param last
     * @param <T>
     */
    private static <T> void merge(final Comparable<T>[] theArray,
            final int first, final int mid, final int last) {
        final Comparable<T>[] tempArray = new Comparable[theArray.length];
        int first1 = first;
        final int last1 = mid;
        int first2 = mid + 1;
        final int last2 = last;
        int index = first1;
        while (first1 <= last1 && first2 <= last2) {
            if (theArray[first1].compareTo((T) theArray[first2]) <= 0) {
                tempArray[index++] = theArray[first1++];
            } else {
                tempArray[index++] = theArray[first2++];
            }
        }
        while (first1 <= last1) {
            tempArray[index++] = theArray[first1++];
        }
        while (first2 <= last2) {
            tempArray[index++] = theArray[first2++];
        }
        for (index = first; index <= last; index++) {
            theArray[index] = tempArray[index];
        }
    }
    
    /**
     * sorts the items in an array into ascending order
     * Precondition: theArray[first...last] is an array
     * Postcondition: theArray[first...last] is sorted in ascending order
     * 
     * @param theArray
     * @param first
     * @param last
     * @param <T>
     */
    private static <T> void mergeSort(final Comparable<T>[] theArray,
            final int first, final int last) {
        if (first < last) {
            final int mid = (first + last) / 2;
            mergeSort(theArray, first, mid);
            mergeSort(theArray, mid + 1, last);
            merge(theArray, first, mid, last);
        }
    }
```
归并排序的时间复杂度是$O(n{log}_{2}n)$。
### 快速排序
快速排序的重点就是枢轴项，左侧都小于枢轴项，右侧的都大于枢轴项，快速排序的算法伪代码如下:
```java
+quicksort(inout theArray: ItemArray, in first: integer, in last: integer){
    // sorts theArray[first...last]
    if(first<last>){
        choose a pivot item p from theArray[first...last]
        Partition the items of theArray[first...last]
        quicksort(theArray,first,pivot-1);
        quicksort(theArray,pivot+1,last);
    }
}
```
与第三章介绍的查找第$k$个最小整数问题的伪代码比较如下:
```java
+kSmall(in k:integer,in theArray: ItemArray, in first: integer, in last: integer){
    // returns the kth smallest value in theArray[first...last]
    choose a pivot item p from theArray[first...last]
    Partition the items of theArray[first...last]
    if(k<pivotIndex - first + 1){
        return kSmall(k,theArray,first, pivotIndex-1)
    }else if(k == pivotIndex - first + 1){
        return p;
    }else {
        return kkSmall(k-(pivotIndex-first+1), theArray, pivotIndex+1,last);
    }
}
```
围绕枢轴项划分数组是难点所在，选择theArray[first]作为数组的枢轴项，且定义$S_1$是小于枢轴项的集合，$S_2$是大于等于枢轴项的集合，定义数组的索引first、lastS1、firstUnknown与last通过这些索引划分数组，分成$S_1$、$S_2$与未处理的区域。如下图:
![划分算法的不变式](pic/快速排序.drawio.png)
在整个划分的过程中
> 区域S1的项都是小与枢轴项，区域S2的项都大于等于枢轴项

为了使不变式在开始执行时为真，需要设置索引的形式如下:
> lastS1=first
> firstUnknown=first+1

划分算法的每个步骤都分析未知区域的一项，确定它是属于$S_1$还是$S_2$，下面是划分算法的伪代码:
```java
+partition(inout theArray: ItemArray, in first:integer, in last: integer){
    // returns the index of the pivot element after partitioning theArray[first...last]
    // initialize
    Choose the pivot and swap it with theArrayp[first]
    p=theArray[first];// p is the pivot
    lastS1=first;// set S1 and S2 empty
    firstUnknown=first+1; // set unkown region to theArray[first+1...last]
    // determine the region S1 and S2
    while(firstUnknown<=last){
        // consider the placement of the leftmost item in the unkown region
        if(theArray[firstUnknown]<p){
            move theArray[firstUnkown] into S1
        }else{
            move theArray[firstUnkown] into S2
        }
    }
    place pivot in proper position between S1 and S2, and mark its new location
    swap theArray[first] with theArray[lastS1]
    return lastS1;// the index of the pivot element
}
```
考虑算法的2种操作
1. 将theArray[firstUnkown]移入S1
S2在S1与未知区域之间，可以体通过移动元素的方式实现，讲S2的第一项theArray[lastS1+1]与theArray[firstUnkown]交换，使lastS1加1，theArray[firstUnkown]的项位于S1的最右端，使firstUnkown加1，那么之前S2最左端的成员就会变成S2最右端的成员。
![](pic/快速排序-第%202%20页.drawio.png)
2. 将theArray[firstUnkown]移入S2
因为S2与未知区域相邻，所以firstUnknown+1即可。

最后，lastS1是S1最右端，交换theArray[first]与theArray[lastS1]并返回lastS1，此时枢轴项放入正确的位置。

用上面的不变式证明划分算法的正确性，需要4个步骤:
- 循环开始执行前，不变式必为true，因为S1与S2都是空的，所以不变式为true;
- 循环的执行，不变式必为true，即要说明若不变式在执行循环的任一迭代前为true，则迭代后必为true。划分算法中循环的每次迭代都根据某一项是否小于枢轴项从而将该项从未知区域移到S1与S2，移动前为true，则移动后也是true;
- 不变式必须证明算法的正确性，即要说明，若循环终止时不变式为true，则算法正确，划分算法中终止条件是未知区域为空，如果位置区域为空，则数组项要么在S1中要么在S2中，划分算法完成任务;
- 循环必须终止，即要说明循环经经过有限次的迭代后终止，划分算法中，每次迭代位置区域-1，因此循环会终止.

下面的Java方法实现了快速排序
```java
 
    /**
     * choose a pivot for quicksort's partition algorithm and swaps it with the
     * first item in an array
     * Precondition: theArray is an array
     * Postcontion: theArray[first] is the pivot
     * 
     * @param theArray
     * @param first
     * @param last
     * @param <T>
     */
    private static <T> void choosePivot(final Comparable<T>[] theArray,
            final int first, final int last) {}
    
    /**
     * partitions an array for quicksort
     * Precondition: theArray[first...last] is an array, first<=last
     * Postcondition: returns the index of the pivot element of
     * theArray[first...last]
     * Upon completion of the method, this will be the index value lastS1 such
     * that
     * S1=theArray[first...lastS1-1]<pivot
     * theArray[lastS1]==pivot
     * S2=theArray[lastS1+1...last]>=pivot
     * 
     * @param theArray
     * @param first
     * @param last
     * @return
     * @param <T>
     */
    private static <T> int partition(final Comparable<T>[] theArray,
            final int first, final int last) {
        Comparable<T> tempItem;
        // place pivot in theArray[first]
        choosePivot(theArray, first, last);
        final Comparable<T> pivot = theArray[first];
        // initially everything but pivot is in unknown
        int lastS1 = first;// index of last item of S1
        // move one item at a time until unknown region is empty, firstUnknown
        // is the index of first item in unknown region
        for (int firstUnknown = first
                + 1; firstUnknown <= last; firstUnknown++) {
            // invariant: theArray[first...lastS1-1]<pivot
            // theArray[lastS1+1...last]>=pivot
            // move item from unknown to proper region
            if (theArray[firstUnknown].compareTo((T) pivot) < 0) {
                lastS1++;
                swap(theArray, firstUnknown, lastS1);
            }
        }
        swap(theArray, first, lastS1);
        
        return lastS1;
    }
    
    /**
     * Sorts the items in an array into ascending order
     * Precondition: theArray[first...last] is an array
     * Postcondition: theArray[first...last] is sorted
     * 
     * @param theArray
     * @param first
     * @param last
     * @param <T>
     */
    private static <T> void quicksort(final Comparable<T>[] theArray,
            final int first, final int last) {
        final int pivotIndex;
        if (first < last) {
            pivotIndex = partition(theArray, first, last);
            quicksort(theArray, first, pivotIndex - 1);
            quicksort(theArray, pivotIndex + 1, last);
        }
    }
```
在最坏情况下，也就是有序的情况下，快排是$O(n^2)$阶的，除非数组已经有序，否则快排总是最优的。
### 基数排序
radix sort，一个简单的例子就是：给一个扑克牌排序，首先将相同的排面值分到一组，一共13组，A，2，3...
然后按面值将每组排好序，然后每次取出一张分到4种纸牌花色中，这样，最终排序是按照花色与大小排序的。
这个书没有做过多的介绍。

各种排序算法的时间比较如下:
![排序算法的对比](pic/sort-algorithms.png)

排序算法是否稳定关系是否支持第二次排序。
## 小结
- 数量阶分析和大$O$表示法度量算法的时间要求，算法的时间要求可以使用增率函数，变成一个问题规模的函数，使用这种办法可以不考虑无法控制的计算机速度和编程技巧等因素来分析算法的效率;
- 在问题规模较大的情况下，通过分析增率函数来比较算法的效率，只有增率函数的显著差异才有意义;
- 最坏情况分析考虑的是，对于指定规模的问题，算法需要的最大工作量，而平均情况分析考虑的是算法需要的预期工作量;
- 选择排序、冒泡排序、插入排序都是$O(n_2)$阶算法；
- 快速排序与归并排序是2种非常有效的递归排序算法，在平均情况下，快速排序是已知最快的排序算法，但是在最坏情况下比归并排序慢，归并排序在所有情况下的性能都是一致的，但是归并排序需要额外的空间;
- 一般的，不应仅通过研究某个实现的运行时间来分析算法，运行时间受多种因素的影响，如编程风格、计算机和应用于程序运行的数据;
- 在比较各种解决方案的效率时，要着眼于显著的区别，这个规则与计算机程序的多维成本相符;
- 使用大$O$表示法的时候要记住，$O(f(n))$表示一个不等量，它不是函数，只是一种表示方法，意指是$f(n)$阶
- 如果问题的规模很小，不必做过多的分析，应将着眼点放在算法的简单性上;

# 第11章 树
线性ADT的主要操作如下:
- 讲数据插入到数据集合中;
- 从数据集合中删除数据;
- 从数据集合中查询数据

ADT列表、栈、队列都是面向位置的，栈与队列对位置坐了特殊的限制，比如栈是只能在一端操作，队列只能在2端操作，有序表是面向值的。
## 术语
树可以用来表示关系，树本质上有层次的，存在根节点、父子节点、叶节点的定义。节点之间的父子关系归为祖先(ancestor)与子孙(descendant)关系，树的根是树中每个节点的祖先，子树是树的一个节点加上该节点的所有子孙，因为树本质上体现了层次结构可以表示具有层次特性的信息。
树的定义：
树是一个或者多个节点的集合。它的定义是递归的，
- 单个根节点是一个树;
- 由已存在的树作为子树来构成的更大的树

二叉树是特殊的一般树，它的定义如下: 就是规定节点的子树最多有2个，子树可以为空.
二叉查找树是一个按节点值排序的二叉树，对于各个节点$n$，二叉查找树满足3个属性:
- $n$的值大于左子树$T_L$中所有节点的值;
- $n$的值小于右子树$T_R$中所有节点的值;
- $T_L$与$T_R$都是二叉查找树;

树的高度的定义: 根节点到叶节点最长路径上的节点数。还可以使用级别的方式定义树的高度:
- 若$n$是$T$的根，则$n$在第1级
- 若$n$不是$T$的根，则$n$的级别比其父节点的级别高1;

树的高度是一个递归定义$$height(T)=1+max{height(T_L), height(T_R)}$$
满二叉树，就是完整的所有节点的二叉树，它的递归定义如下:
- 若$T$为空，则$T$是高度为0的满二叉树;
- 若$T$非空，且高度$h$>0，若根的2个子树都存在且都是高度$h-1$的满二叉树，则$T$是满二叉树;

完全二叉树，就是按层次不会遍历，不会出现中间节点缺失的二叉树，满二叉树也是完全二叉树。二叉树的任意一个节点的2个子树的高度差<=1，则是平衡二叉树也叫做高度平衡二叉树。
## ADT二叉树
所有二叉树都要实现的公共操作:
- 构建一颗空二叉树;
- 根据给定元素构建一颗单节点二叉树;
- 从二叉树中删除所有节点，使其为空;
- 确定二叉树是否为空;
- 确定哪个数据是二叉树的根;
- 为二叉树的根设置数据

除了以上的基本操作外，还需要一些额外的操作，总的操作如下:

- +createBinaryTree()// creates an empty binary tree
- +createBinaryTree(in rootItem: TreeItemType)// create a one-node binary tree whose root contains rootItem
- +makeEmpty()// removes all of the nodes from a binary tree, leaving an empty tree
- +isEmpty(): boolean {query} //determines whether a binary tree is empty
- +getRootItem(): TreeItemType throws TreeException {query}// retrieves the data item in the root of a nonempty binary tree, throws TreeException if the tree is empty
- +setRootItem(in rootItem: TreeItemType) throws UnsupportedOperationTreeException// sets the data item in the root of a binary tree, throws UnsupportedOperationTreeException if the method is not implemented.
- +createBinaryTree(in rootItem: TreeItemType, in leftTree: BinaryTree, in rightTree: BinaryTree)//creates a binary tree whose root contains rootItem and has leftTree and rightTree, respectively, as its left and right subtrees.
- +setRootData(in newItem: TreeItemType) //replace the data item in the root of a binary tree with newItem, if the tree is not empty, however, if the tree is empty, creates  a root node whose data item is newItem and inserts the new node into the tree.
- +attachLeft(in newItem: TreeItemType) throws TreeException // attaches a left child containing newItem to the root of a binary tree, Throws TreeException if the binary tree is empty (no root to attach to) or a left subtree already exists (should explicitly detach it first)
- +attachRight(in newItem: TreeItemType) throws TreeException // attaches a right child containing newItem to the root of a binary tree, Throws TreeException if the binary tree is empty (no root to attach to) or a right subtree already exists (should explicitly detach it first)
- +attachLeftSubtree(in leftTree: BinaryTree) throws TreeException // attaches leftTree as the left subtree of the root of a binary tree and makes leftTree empty so that it cannot be used as a reference into this tree, Throws TreeException if the binary tree is empty (no root to attach to) or a left subtree already exists (should explicitly detach it first)
- +attachRightSubtree(in rightTree: BinaryTree) throws TreeException // attaches rightTree as the right subtree of the root of a binary tree and makes leftTree empty so that it cannot be used as a reference into this tree, Throws TreeException if the binary tree is empty (no root to attach to) or a left subtree already exists (should explicitly detach it first)
- +detachLeftSubtree(): BinaryTree throws TreeException// detaches and returns the left subtree of a bianry tree's root throws TreeException if the binary tree is empty(no root node to detach from)
- +detachRightSubtree(): BinaryTree throws TreeException// detaches and returns the right subtree of a bianry tree's root throws TreeException if the binary tree is empty(no root node to detach from)

二叉树的遍历访问树中每一个节点，根据二叉树的递归特性可以设计递归遍历算法，形式为：
```java
+traverse(in binTree: BinaryTree)
// traverses the binary tree binTree
if(binTree is not empty){
    traverse(Left subtree of binTree's root);
    traverse(Right subtree of binTree's root);
}
```
根据访问根节点的顺序，定义了preorder、inorder、postorder3种遍历方式，如果二叉树对应代数表达式，则3种遍历方式分别对应前缀、中缀与后缀表达式。

二叉树有3种表示方式：
1. 使用数组表示二叉树
若使用Java类来定义树的节点，可以通过树节点的数组表示二叉树，节点包含数据部分与2个索引，比如下面的Java代码:
```java
@Data
public class TreeNode<T> {
    private T item;
    // 若没有左子节点，则=-1
    private int leftChild;
    // 若没有右子节点，则=-1
    private int rightChild;
}
public abstract class BinaryTreeArrayBased<T> {
    protected final int MAX_NODES = 100;
    
    protected ArrayList<TreeNode<T>> tree;
    // 树根在数组tree内的索引，若树为空=-1，
    protected int root;
    
    protected int free;
}
```
插入与删除操作会使树发生变化，故节点可能不是数组的连续元素，该实现要求建立一个可用节点列表，即空闲表(free list)，要将新节点插入树中，首先从空闲列表中获得一个可用的节点，要从树中删除一个节点，则将其放入空闲列表，以便后面重用该节点，free变量是空闲列表中第一个节点的索引，空闲表中各个节点的rightChild字段是空闲表中下一节点的索引。
2. 使用数组表示完全二叉树
完全二叉树使用标准分级方案对节点编号，根节点的编号是1，按照层次从左到右分别递增编号，按照编号将节点放入数组$tree$中，$tree[i]$包含编号$i$的节点，根据编号的规则，则$tree[i]$的左子节点的编号是$tree[2i+1]$,右子节点的编号是$[2i+2]$, 父节点的编号是$tree[(i-1)/2]$，必须是完全二叉树才可以;
3. 基于引用的表示
Java引用来链接树的节点，代码如下:
```java
@Data
class TreeNode<T> {
    private T item;
    private TreeNode<T> leftChild;
    private TreeNode<T> rightChild;
}
```
二叉树基于引用表示的实现:
首先定义二叉树基类如下:
```java
@Data
class TreeNode<T> {
    private T item;
    
    private TreeNode<T> leftChild;
    
    private TreeNode<T> rightChild;
    
    public TreeNode(final T item) {
        this(item, null, null);
    }
    
    private TreeNode(final T item, final TreeNode<T> leftChild,
                     final TreeNode<T> rightChild) {
        this.item = item;
        this.leftChild = leftChild;
        this.rightChild = rightChild;
    }
}
```
接下来定义二叉树抽象类的共同操作:
```java
public abstract class BinaryTreeBasis<T> {
    
    private TreeNode<T> root;
    
    public BinaryTreeBasis() {}
    
    private BinaryTreeBasis(final T rootItem) {
        this.root = new TreeNode<>(rootItem);
    }
    
    public boolean isEmpty() {
        return root == null;
    }
    
    public void makeEmpty() {
        root = null;
    }
    
    public T getRootItem() throws TreeException {
        if (root == null) {
            throw new TreeException("TreeException: Empty tree");
        } else {
            return root.getItem();
        }
    }
    
    public abstract void setRootItem(T newItem);
}
```
定义一个一般的二叉树实现:
```java
public class BinaryTree<T> extends BinaryTreeBasis<T> {
    
    public BinaryTree() {}
    
    public BinaryTree(final T rootItem) {
        super(rootItem);
    }
    
    private BinaryTree(final TreeNode<T> rootNode) {
        root = rootNode;
    }
    
    public BinaryTree(final T rootItem, final BinaryTree<T> leftTree,
            final BinaryTree<T> rightTree) {
        super(rootItem);
        attachLeftSubtree(leftTree);
        attachRightSubtree(rightTree);
    }
    
    public void attachLeft(final T newItem) {
        if (!isEmpty() && root.getLeftChild() == null) {
            root.setLeftChild(new TreeNode<>(newItem));
        }
    }
    
    public void attachRight(final T newItem) {
        if (!isEmpty() && root.getRightChild() == null) {
            root.setRightChild(new TreeNode<>(newItem));
        }
    }
    
    private void attachLeftSubtree(final BinaryTree<T> leftTree)
            throws TreeException {
        if (isEmpty()) {
            throw new TreeException("empty tree");
        } else if (root.getLeftChild() != null) {
            throw new TreeException("left tree already exists");
        } else {
            root.setLeftChild(leftTree.root);
            leftTree.makeEmpty();
        }
    }
    
    private void attachRightSubtree(final BinaryTree<T> rightTree)
            throws TreeException {
        if (isEmpty()) {
            throw new TreeException("empty tree");
        } else if (root.getRightChild() != null) {
            throw new TreeException("left tree already exists");
        } else {
            root.setRightChild(rightTree.root);
            rightTree.makeEmpty();
        }
    }
    
    public BinaryTree<T> detachLeftSubtree() throws TreeException {
        if (isEmpty()) {
            throw new TreeException("empty tree");
        } else {
            final BinaryTree<T> left = new BinaryTree<>(root.getLeftChild());
            root.setLeftChild(null);
            return left;
        }
    }
    
    public BinaryTree<T> detachRightSubtree(final BinaryTree<T> rightTree)
            throws TreeException {
        if (isEmpty()) {
            throw new TreeException("empty tree");
        } else {
            final BinaryTree<T> right = new BinaryTree<>(root.getRightChild());
            root.setRightChild(null);
            return right;
        }
    }
    
    @Override
    public void setRootItem(final T newItem) {
        if (root == null) {
            root = new TreeNode<>(newItem);
        } else {
            root.setItem(newItem);
        }
    }
}
```
迭代器访问树节点的顺序依赖于树的遍历操作，前中后；实现树迭代器需要实现Iterator接口，里面有3个方法，在`BinaryTreeBasis`中实现就可以，下面是TreeIterator的定义:
```java
public class TreeIterator<T> implements Iterator<T> {
    
    private final BinaryTreeBasis<T> binTree;
    
    private TreeNode<T> currentNode;
    
    private final LinkedList<TreeNode<T>> queue;
    
    TreeIterator(final BinaryTreeBasis<T> binTree) {
        this.binTree = binTree;
        currentNode = null;
        queue = new LinkedList<>();
    }
    
    @Override
    public boolean hasNext() {
        return !queue.isEmpty();
    }
    
    @Override
    public T next() {
        currentNode = queue.pollFirst();
        return currentNode.getItem();
    }
    
    public void setPreorder() {
        queue.clear();
        preorder(binTree.root);
    }
    
    void setInorder() {
        queue.clear();
        inorder(binTree.root);
    }
    
    public void setPostorder() {
        queue.clear();
        postorder(binTree.root);
    }
    
    private void preorder(final TreeNode<T> treeNode) {
        if (treeNode != null) {
            queue.add(treeNode);
            preorder(treeNode.getLeftChild());
            preorder(treeNode.getRightChild());
        }
    }
    
    private void inorder(final TreeNode<T> treeNode) {
        if (treeNode != null) {
            inorder(treeNode.getLeftChild());
            queue.add(treeNode);
            inorder(treeNode.getRightChild());
        }
    }
    
    private void postorder(final TreeNode<T> treeNode) {
        if (treeNode != null) {
            postorder(treeNode.getLeftChild());
            postorder(treeNode.getRightChild());
            queue.add(treeNode);
        }
    }
}
```
```java
public class Demo {
    public static void main(final String[] args) {
        final BinaryTree<Integer> tree3 = new BinaryTree<>(70);
        final BinaryTree<Integer> tree1 = new BinaryTree<>();
        tree1.setRootItem(40);
        tree1.attachLeft(30);
        tree1.attachRight(50);
        final BinaryTree<Integer> tree2 = new BinaryTree<>();
        tree2.setRootItem(20);
        tree2.attachLeft(10);
        tree2.attachRightSubtree(tree1);
        final BinaryTree<Integer> binTree = new BinaryTree<>(60, tree2, tree3);
        final TreeIterator<Integer> btIterator = new TreeIterator<>(binTree);
        btIterator.setInorder();
        System.out.println(Iterators.toString(btIterator));
        final BinaryTree<Integer> leftTree = binTree.detachLeftSubtree();
        final TreeIterator<Integer> leftIterator = new TreeIterator<>(leftTree);
        leftIterator.setInorder();
        System.out.println(Iterators.toString(leftIterator));
        btIterator.setInorder();
        System.out.println(Iterators.toString(btIterator));
    }
}
```
非递归遍历的难点是访问某个节点后如何确定下一个节点，看下递归方案inorder
```java
private void inorder(final TreeNode<T> treeNode) {
        if (treeNode != null) {
            inorder(treeNode.getLeftChild());// point1
            queue.add(treeNode);
            inorder(treeNode.getRightChild());// point2
        }
    }
```
treeNode引用树中当前节点的位置，按照递归方法隐式使用的栈，inorder新的子节点入栈，任何时间，栈都包含从树根到当前节点$n$的路径上的节点，$n$的引用在栈顶，根的引用在栈底。从子树返回时，如果是左子树返回，说明遍历完左子树，栈出，回到point1节点，显示$p$数据后，进入point2递归调用，这有2个现象:
- 引用的隐式递归栈用来查找遍历程序必然回溯的节点$p$;
- 一旦返回到$p$，要么访问节点要么进一步回溯，看是从左子树返回的还是从右子树返回的.

可以用迭代操作与显式栈模拟这些操作，下面的伪代码描述这个过程:
```java
+inorderTraverse(in treeNode: TreeNode)
// Nonrecursively traverses a binary tree in inorder
Create an empty stack visitStack;
curr=treeNode;
done=false;
while(!done){
    if(curr!=null){
        // place reference to node on stack before
        // traversing node's left substree
        visitStack.push(curr);
        // traverse the left subtree
        curr=curr.getLeft();
    }else{
        // backstack from the empty subtree and visit the node at the top of the stack, however , if the stack is empty, you are done
        if(!visitStack.isEmpty()){
            curr=visitStack.pop();
            queue.enqueue(curr);
            // traverse the right subtree of the node just visited
            curr=curr.getRight();
        }else{
            done=true;
        }
    }
}
```
## ADT 二叉查找树
二叉查找树是按值组织树，不是按照层次，也有递归定义的特点。可以根据值查找，效率比较快，树中存储的实例包含多个不同信息字段的情况下，经常使用二叉查找树，标识查找记录的信息叫做查找关键字，查找关键字的值不可以修改，修改了要重新组织树，二叉查找树根据查找关键字的值执行插入、删除与检索，遍历与普通的二叉树是一样的.
BinarySearchTree继承于BinaryTreeBasis，多余的操作有:
- +insert(in newItem: TreeItemType)// inserts newItem into a binary search tree whose items have distinct search keys that differ from newItem's search key
- +delete(in searchKey: KeyType) throws TreeException// deletes from a binary search tree the item whose search key equals searchKey, if no such itemm exists, the operation fails and throws TreeException
- +retrieve(in searchKey: KeyType): TreeItemType//returns the item in a binary search tree whose search key equals searchKey, returns null if no such item exists
### ADT二叉查找树操作的算法
二叉查找树的所有操作的算法基础都是下面的伪代码描述的:
```java
+search(in bst: BinarySearchTree, in searchKey: KeyType){
    //searches the bianry search tree bst for the item whose search key is searchKey
    if(bst is empty){
        the desired record is not found
    }else if(searchKey== key of root s item){
        the desired record is found
    }else if(searchKey<key of root s item){
        search(left subtree of bst, searchKey);
    }else{
        search(right subtree of bst, searchKey);
    }
}
```
二叉查找树的形状有很多种，但是都符合二叉查找树的定义，通常越接近完全二叉树的查找树效率越高.
1. 插入
插入新节点与search操作一样，但是遇到null的地点就是插入新节点的位置，因为search总是在空子树处终止，一种简单的伪代码的表示:
```java
+insertItemm(in treeNode: TreeNode, in newItem: TreeItemType){
    // inserts newItem into the binary search tree of which treeNode is the root
    if(treeNode is null){
        create a new node and let treeNode reference it 
    }else if(newItem.getKey < treeNode.getItem.getKey){
        treeNode.setLeft(insertItemm(treeNode.getLeft(),newItem))
    }else{
        treeNode.setRight(insertItemm(treeNode.getRight(),newItem))
    }
    return treeNode;
}
```
2. 删除
首先我们想到的解决方案就是用搜索算法搜到某个节点，然后删掉它，但是存在的问题就是这个节点的子节点如何处理，分为3种情况:
- $N$是叶节点: 直接删除就好，父节点的应用设置为null;
- $N$只有一个子节点: 2种情况，存在左子节点或者右子节点，直接使用子节点代替删除的节点就可以了，这样中间的节点就没有了，或者使用值覆盖的方式，还是保持了二叉查找树的性质;
- $N$有2个子节点: 因为有2个子节点，不知道使用哪个节点代替父节点，我们可以使用值移动的方式删除关键字而不是删除节点，直到找到一个容易删除的节点，一个简单的策略是:
  - 在树中定位另一个节点$M$，$M$比$N$更容易删除;
  - 将$M$中的项复制到$N$，从而有效的从树中删除$N$的原始项;
  - 从树中删除节点$M$
更容易删除的节点是叶节点活着只有一个子节点的节点，简单的将这2个节点的数据复制到要删除的祖先节点会破坏二叉查找树的性质，一种解决办法就是就是找到要删除节点的中序后继或者中序前驱节点，替换，这样不会破坏二叉查找树的性质。因为中序后继是右子树的最左面的节点，肯定没有左节点，中序前驱是左子树的最右面的节点，肯定没有右子节点，所以可以用最简单的方式删除.简单的伪代码表示如下:
```java
+deleteItem(in rootNode: TreeNode, in searchKey: KeyType){
    // deletes from the binary search tree with root
    // rootNode the item whose search key equals searchKey
    // returns the root node fo the resulting tree
    // if no such item exists, the operation fails and throws TreeException
    if(rootNode is null){
        throw TreeException;
    }else if(searchkey equals the key in rootNode item){
        //delete the rootNode, a new root of the tree is returned
        newRoot=deleteNode(rootNode);
        return newRoot;
    }else if(searchkey is less than the key in rootNode item){
        newLeft=deleteItem(rootNode.getLeft(),searchKey);
        rootNode.setLeft(newLeft);
        return rootNode;
    }else{
        newRight=deleteItem(rootNode.getRight(),searchKey);
        rootNode.setRight(newRight);
        return rootNode;
    }
}
+deleteNode(in treeNode: TreeNode): TreeNode
// deletes the item in the node referenced by treeNode
// returns the root node of the resulting tree
    if(treeNode is leaf){
        return null;
    }else if(treeNode has only one child c){
        //c replaces treeNode as the child of treeNode's parent
        if(c is the left child of treeNode){
            return treeNode.getLeft();
        }else{
            return treeNode.getRight();
        }
    }else{
        // treeNode has two children
        // find the inorder successor of the search key in treeNode: it is in the leftmost node of the subtree rooted at treeNode's right child
        replacementItem=findLeftMost(treeNode.getRight()).getItem();
        replacementrChild=deleteLeftMost(treeNode.getRight());
        treeNode.item=replacementItem;
        treeNode.right=replacementrChild;
        return treeNode;
    }
+findLeftMost(in treeNode: TreeNode): TreeNode
// returns the item that is the leftmost descendant of the tree rootedao treeNode
    if(treeNode.getLeft() == null){
        return treeNode;
    }else{
        return findLeftMost(treeNode.getLeft());
    }
+deleteLeftMost(in treeNode: TreeNode):TreeNode
// deletes the node that is the leftmost descendant of the tree rooted at treeNode returns subtree of deleted node
    if(treeNode.getLeft()==null){
        // this is the node you want; it has no left child, but it might have a right subtree
        return treeNode.getRight();
    }else{
        replacementLChild=deleteLeftMost(treeNode.getLeft())
        treeNode.setLeft(replacementLChild);
        return treeNode;
    }
```
3. 检索
就是简单的搜索算法;
4. 遍历
### ADT二叉树的基于引用的实现
基于引用的实现:
```java
public class BinarySearchTree<T extends KeyedItem<KT>, KT extends Comparable<? super KT>>
        extends BinaryTreeBasis<T> {
    public BinarySearchTree() {
        // default constructor
    }
    
    public BinarySearchTree(final T rootItem) {
        super(rootItem);
    }
    
    @Override
    public void setRootItem(final T newItem) {
        throw new UnsupportedOperationException();
    }
    
    public void insert(final T newItem) {
        root = root = insertItem(root, newItem);
    }
    
    public T retrieve(final KT searchKey) {
        return retrieveItem(root, searchKey);
    }
    
    public void delete(final KT searchKey) throws TreeException {
        root = deleteItem(root, searchKey);
    }
    
    public void delete(final T item) throws TreeException {
        root = deleteItem(root, item.getSearchKey());
    }
    
    private TreeNode<T> deleteItem(TreeNode<T> treeNode, final KT searchKey) {
        final TreeNode<T> newSubtree;
        if (treeNode == null) {
            throw new TreeException("tree is empty");
        } else {
            final T nodeItem = treeNode.getItem();
            if (searchKey.compareTo(nodeItem.getSearchKey()) == 0) {
                treeNode = deleteNode(treeNode);
            } else if (searchKey.compareTo(nodeItem.getSearchKey()) < 0) {
                newSubtree = deleteItem(treeNode.getLeftChild(), searchKey);
                treeNode.setLeftChild(newSubtree);
            } else {
                newSubtree = deleteItem(treeNode.getRightChild(), searchKey);
                treeNode.setRightChild(newSubtree);
            }
        }
        return treeNode;
    }
    
    private TreeNode<T> deleteNode(final TreeNode<T> tNode) {
        final T replacementItem;
        // test for a leaf
        if (tNode.getLeftChild() == null && tNode.getRightChild() == null) {
            return null;
        } else if (tNode.getLeftChild() == null) {
            return tNode.getRightChild();
        } else if (tNode.getRightChild() == null) {
            return tNode.getLeftChild();
        } else {
            replacementItem = findLeftmost(tNode.getRightChild());
            tNode.setItem(replacementItem);
            tNode.setRightChild(deleteLeftmost(tNode.getRightChild()));
        }
        return null;
    }
    
    private T findLeftmost(final TreeNode<T> tNode) {
        if (tNode.getLeftChild() == null) {
            return tNode.getItem();
        } else {
            return findLeftmost(tNode.getLeftChild());
        }
    }
    
    private TreeNode<T> deleteLeftmost(final TreeNode<T> tNode) {
        if (tNode.getLeftChild() == null) {
            return tNode.getRightChild();
        } else {
            tNode.setLeftChild(deleteLeftmost(tNode.getLeftChild()));
            return tNode;
        }
    }
    
    private T retrieveItem(final TreeNode<T> treeNode, final KT searchKey) {
        final T treeItem;
        if (treeNode == null) {
            treeItem = null;
        } else {
            final T nodeItem = treeNode.getItem();
            if (searchKey.compareTo(nodeItem.getSearchKey()) == 0) {
                treeItem = nodeItem;
            } else if (searchKey.compareTo(nodeItem.getSearchKey()) < 0) {
                treeItem = retrieveItem(treeNode.getLeftChild(), searchKey);
            } else {
                treeItem = retrieveItem(treeNode.getRightChild(), searchKey);
            }
        }
        return treeItem;
    }
    
    private TreeNode<T> insertItem(TreeNode<T> treeNode, final T newItem) {
        TreeNode<T> newSubtree = null;
        if (treeNode == null) {
            // position of insertion found,
            treeNode = new TreeNode<>(newItem);
        }
        final T nodeItem = treeNode.getItem();
        if (newItem.getSearchKey().compareTo(nodeItem.getSearchKey()) < 0) {
            newSubtree = insertItem(treeNode.getLeftChild(), newItem);
            treeNode.setLeftChild(newSubtree);
        } else {
            newSubtree = insertItem(treeNode.getRightChild(), newItem);
            treeNode.setRightChild(newSubtree);
        }
        return treeNode;
    }
}
```
### 二叉查找树的效率
二叉查找树的操作中涉及到值的比较，比较的次数与路径上的节点数相同，也就是二叉树的高度，二叉树的最大高度就是节点数，也就是每个节点只有一个子节点，计算树的最小高度的定理如下:
- 当$ h\geq 0 $高度为$h$的满二叉树包含$ {2}^{h}-1 $个节点
- 高度为$h$的二叉树最多包含$ {2}^{h}-1 $个节点;
- 包含$n$个节点的二叉树的最小高度是$ \lceil \log_{2} {(n+1)}\rceil  $
### 树排序
原理很简单，就是利用二叉查找树的原理，中序遍历;
```java
+treesort(inout anArray: ArrayType, in n: integer)
// sorts the n integers in array anArray into ascending order
    Insert anArray's elements into a binary search tree bTree
    Traverse bTree inorder, as you visit bTree's nodes, copy their data items into successive locations of anArray
```
平均时间复杂度是$O(n*log_{2}{n})$.
### 将二叉树保存到文件中
- 保存二叉查找树，然后恢复到原始形状，用二叉树的先序顺序保存树，恢复时也按照先序顺序插入二叉查找树，则恢复的树与原来一样;
- 中序遍历将树保存到文件中，通过观察中序遍历的数据吗，可以发现，此时数据符合二叉查找算法的特点，每次分一半可以确保树的高度最小，所以以中间节点为树根，再找左面数据与右面数据的中间节点，构造二叉查找子树，最后得到满二叉树或者非严格定义的完全二叉树。下面是伪代码，就跟二叉查找的过程差不多:
```java
+readTree(in inputFile: FileType , in n: integer): TreeNode
    // builds a minimum-height binary search tree from n sorted values in a file, will return the tree's root
    if(n>0){
        treeNode=reference to new node with null child references
        // construct the left subtree
        Set treeNode's left child to readTree(inputFile, n/2)
        Read item from file into treeNode's item
        // construct the right subtree
        Set treeNode's right child to readTree(inputFile, (n-1)/2)
    }
    return treeNode
```
### JCF的二叉树查找算法
Java集合框架提供了2个二叉树查找方法都在Collections类中作为静态方法存在,一个可以查找Comparable数组，一个基于Comparator查找。如果找到元素，返回index，没找到返回插入点的负值-(insertIndex)-1，如果List实现了RandomAccess接口，那么使用二叉查找法，如果没有则遍历搜索。
## 一般树
$n$元树是二叉树的泛化，一种表示形式是使用二叉树节点表示，左引用指向节点的第一个子节点，右引用指向下一个兄弟节点，当然如果能确定最大的子节点数$n$，那么也可以直接引用.
## 小结
- 二叉树以层次结构组织数据;
- 二叉树的实现基于引用，若是完全二叉树，也可以使用数组的方式;
- 二叉查找树允许使用类似于二叉查找的算法来查找包含指定值的项;
- 二叉查找树的形状多种多样；
- 二叉查找树的中序遍历按有序的查找关键字的顺序访问树的节点;
- 树排序算法使用二叉查找树的插入与遍历操作，有效的排序数组;
- 若执行节点的中序遍历，将二叉查找树的数据保存在文件中，可将树恢复为最小高度的二叉查找树，若执行节点的先序遍历，将二叉查找树的数据保存在文件中，则可将树恢复到原始形状。
# 第12章 表与优先队列
ADT表适合通过值来管理数据的问题
## ADT表
ADT表用于查找信息基于查找关键字。基本操作有:
- 创建空表;
- 确定表是否为空;
- 确定表中的项数;
- 将新项插入表;
- 从表中删除包含给定关键字的项;
- 从表中检索给定关键字的项;
- 按有序的查找关键字顺序遍历表项;
一个城市表的例子如下:
首先定义表项与其查找关键字
```java
public class City extends KeyedItem<String> {
    private final String city;
    private String country;
    
    private int pop;
    
    public City(final String searchKey, final String city) {
        super(searchKey);
        this.city = city;
    }
    
    public String getCountry() {
        return country;
    }
    
    public void setCountry(final String country) {
        this.country = country;
    }
    
    public int getPop() {
        return pop;
    }
    
    public void setPop(final int pop) {
        this.pop = pop;
    }
}
```
然后定义表的接口:
```java
/**
 * Precondition for all operations:
 * No two items of the table have the same search key.
 * the table's items are sorted by search key.
 **/

public interface TableInterface<T extends KeyedItem<KT>, KT extends Comparable<? super KT>> {
    
    /**
     * Determines whether a table is empty
     * Postcondition: Returns true if the table is empty;otherwise returns
     * false.
     */
    boolean tableIsEmpty();
    
    /**
     * Determines the length of a table
     * Postcondition: Returns the number of items in the table.
     */
    int tableLength();
    
    /**
     * Inserts an item into a table in its proper sorted order according to the
     * item's search key
     * Precondition: the item to be inserted into the table is newItem, whose
     * search key differs from
     * all search keys presently in the table.
     * Postcondition: If the insertion was successful, newItem is in its proper
     * order in the table. otherwise the table
     * is unchanged, and TableException is thrown.
     */
    void tableInsert(T newItem) throws TableException;
    
    /**
     * deletes an item with a given search key from a table.
     * Precondition: searchKey is the search key of the item to be deleted.
     * Postcondition: if the item whose search key equals searchkey existed in the table, the item was
     * deleted and method returns true, Otherwise, the table is unchanged and the method return false.
     */
    boolean tableDelete(KT searchKey);

    /**
     * 
     * @param searchKey
     * @return
     */
    KeyedItem<KT> tableRetrieve(KT searchKey);
}
```
ADT实现要么基于数组，要么基于引用，即用数组或者链表来存储ADT的项，这些称为线性实现，因为逐一表示数据结构中的各个项，应用程序的要求影响ADT实现的选择，因为操作在不同的实现下的效率不同，还要计算每个操作执行的频率；需要考虑的3个因素:
- 需要什么操作;
- 这些操作的执行频率;
- 操作要求的响应时间。

- ADT表的基于数组的无序实现插入数据项快，删除时需要移动数据，因为是无序的，检索时需要顺序遍历;
- ADT表的基于有序数组的实现，插入/删除都需要移动数据，检索时可以用使用二分查找;
- ADT表基于引用的无序实现插入数据项快，删除需要顺序查找不需要移动数据，检索也需要顺序查找;
- ADT表的基于引用的有序实现插入/删除都需要顺序查找，不移动数据，检索也需要顺序查找.

项不多的情况下，可以使用线性实现，因为此时简单性与清晰性比效率显得更重要。使用二叉查找树实现表与线性实现有优势，集合了优点，摒弃了缺点.有序数组实现表的源代码如下:
```java

/**
 * ADT table，sorted array-based implementation,
 * Assumption: A table contains at most one item with a given search key at any
 * time
 */
public class TableArrayBased<T extends KeyedItem<KT>, KT extends Comparable<? super KT>>
        implements TableInterface<T, KT> {
    private final int MAX_TABLE = 100; // maximum size of table
    protected ArrayList<T> items; // table items
    
    public TableArrayBased() {
        items = new ArrayList<>(MAX_TABLE);
    }
    
    @Override
    public boolean tableIsEmpty() {
        return items.size() == 0;
    }
    
    @Override
    public int tableLength() {
        return items.size();
    }
    
    @Override
    public void tableInsert(final T newItem) throws TableException {
        if (tableLength() < MAX_TABLE) {
            // there is room to insert; locate the position where newItem
            // belongs
            final int spot = position(newItem.getSearchKey());
            if (spot < tableLength() && items.get(spot).getSearchKey()
                    .compareTo(newItem.getSearchKey()) == 0) {
                throw new TableException();
            } else {
                items.add(spot, newItem);
            }
        } else {
            throw new TableException();
        }
    }
    
    @Override
    public boolean tableDelete(final KT searchKey) {
        final int spot = position(searchKey);
        if (spot < tableLength()
                && items.get(spot).getSearchKey().compareTo(searchKey) == 0) {
            items.remove(spot);
            return true;
        }
        return false;
    }
    
    @Override
    public KeyedItem<KT> tableRetrieve(final KT searchKey) {
        final int spot = position(searchKey);
        if (spot < tableLength()
                && items.get(spot).getSearchKey().compareTo(searchKey) == 0) {
            return items.get(spot);
        }
        return null;
    }
    
    private int position(final KT searchKey) {
        int pos = 0;
        while (pos < tableLength()
                && items.get(pos).getSearchKey().compareTo(searchKey) > 0) {
            pos++;
        }
        return pos;
    }
}
```
ADT表基于二叉查找树的实现如下:
```java
public class TableBSTBased<T extends KeyedItem<KT>, KT extends Comparable<? super KT>>
        implements TableInterface<T, KT> {
    // binary search tree that contains the table's items
    private final BinarySearchTree<T, KT> bst;
    
    protected int size; // number of items in the table
    
    public BinarySearchTree<T, KT> getBst() {
        return bst;
    }
    
    TableBSTBased() {
        bst = new BinarySearchTree<T, KT>();
        size = 0;
    }
    
    @Override
    public boolean tableIsEmpty() {
        return size == 0;
    }
    
    @Override
    public int tableLength() {
        return size;
    }
    
    @Override
    public void tableInsert(final T newItem) throws TableException {
        if (bst.retrieve(newItem.getSearchKey()) == null) {
            bst.insert(newItem);
            size++;
        } else {
            throw new TableException();
        }
    } // end tableInsert
    
    @Override
    public boolean tableDelete(final KT searchKey) {
        try {
            bst.delete(searchKey);
        } catch (final TreeException e) {
            return false;
        }
        size--;
        return true;
    }
    
    @Override
    public KeyedItem<KT> tableRetrieve(final KT searchKey) {
        return bst.retrieve(searchKey);
    }
}
```
## ADT优先队列: ADT表的变体
具有优先级的ADT表，日常生活中有很多的案例，比如，排队看病、任务优先级等。它的基本操作有:
- 构建空优先队列;
- 确定优先队列是否为空;
- 将新项插入优先队列;
- 检索然后删除优先队列中具有最高优先级值的项.
优先级就类似于检索关键字。与ADT表的操作有2点不同:
- 检索然后删除优先队列中具有最高优先级值的项，没有像表那样，传递搜索关键字参数;
- 检索然后删除优先队列中具有最高优先级值的项不能删除指定搜索关键字的项;
使用线性ADT表实现ADT优先队列，在插入时都是$O(n)$的时间复杂度，比较高。检索是最方便的，都是$O(1)$的时间复杂度。使用二叉查找树是最方便的，插入与检索都是$O(log_2n)$，检索就是删除最右节点的操作，最右节点的子节点至多为1，一种最简单的实现方案是堆.
### 堆
堆不同二叉查找树的地方:
- 堆不是严格有序的;
- 堆是完全二叉树;
堆也是树，也符合递归定义逻辑:
- 堆的根节点的关键字>=子树的关键字;
- 子树也是堆;
分为最大堆与最小堆。操作的伪代码如下:
- +createHeap()// creates an empty heap
- +heapIsEmpty():Boolean {query} // determines whether a heap is empty
- +heapInsert(in newItem: HeapItemType) throws HeapException // inserts nwItem into a heap, Throws HeapException if heap is full
- +heapDelete(): HeapItemType // Retrieves and then deletes a heap's root item.this item has the largest search key
堆是完全二叉树，可以用数组表示。items表示数组，size表示堆的大小.
- heapDelete: 最大的查找关键字是树根，很容易检索，删除树根，留下2个分离的堆，需要将剩余的节点转换为新的堆。此时最容易检索的节点是最后一个节点，把最后一个节点复制到根节点，这时候还是完全二叉树，子树是堆，只有根节点不符合条件，这样的堆叫做半堆(semiheap)，半堆转换为堆类似于冒泡排序，逐渐下沉到合适的位置。交换一次后，子树变成半堆，这是一个递归的处理逻辑。伪代码如下:
```java
+heapRebuild(inout items: ArrayType, in root:integer, in size:integer)
 //converts a semiheap rooted at index root into a heap
 // recursively trickle the item at index root down to its proper position by swapping it with its larger child,
 // if the child is larger than the item. If the item is at a leaf, nothing needs to be done.
 if(the root is not a leaf){
    // root must have a left child
    child=2*root+1
    if(the root has a right child){
        rightChild=child+1
        if(items[rightChild].getKey()>items[child].getKey()){
            child=rightChild
        }
    }
    // if the item in the root has a smaller search key than the search key of the item in the larger child, swap items
    if(items[root].getKey()>items[child].getKey()){
        Swap items[root] and items[child]
        heapRebuild(items,child,size)
    }
 }
```
时间复杂度是$log_2n$，最大交换次数就是从根节点交换到叶节点，也就是树的最大高度。
- heapInsert: 与heapDelete的操作相反，为了保持完全二叉树，在最后插入新的项，然后根据(i-1)/2定位父节点来上移。也是一种冒泡操作。伪代码如下:
```java
// insert newItem into the bottom of the tree
items[size]=newItem
// trickle new item up to appropriate spot in the tree
place=size
parent=(place-1)/2
while(parent>=0 and items[place]>items[parent]){
    swap items[place] and items[parent]
    place=parent
    parent=(parent-1)/2
}
increment size
```java
public class Heap<T> {
    
    private final ArrayList<T> items;
    
    private Comparator<? super T> comparator;
    
    private Heap() {
        items = new ArrayList<>();
    }
    
    public Heap(final Comparator<? super T> comparator) {
        this();
        this.comparator = comparator;
    }
    
    private boolean heapIsEmpty() {
        return items.size() == 0;
    }
    
    public void heapInsert(final T newItem) {
        items.add(newItem);
        int place = items.size() - 1;
        int parent = (place - 1) / 2;
        while (parent >= 0
                && compareItems(items.get(place), items.get(parent)) > 0) {
            final T temp = items.get(parent);
            items.set(parent, items.get(place));
            items.set(place, temp);
            place = parent;
            parent = (place - 1) / 2;
        }
    }
    
    public T heapDelete() {
        T rootItem = null;
        final int loc;
        if (!heapIsEmpty()) {
            rootItem = items.get(0);
            loc = items.size() - 1;
            items.set(0, items.get(loc));
            items.remove(loc);
            heapRebuild(0);
        }
        return rootItem;
    }

    // if the root is not a leaf and the root's search key is less than the
    // larger of search keys in the root's children
    private void heapRebuild(final int root) {
        int child = 2 * root + 1;// index of root's left child if any
        if (child < items.size()) {
            // root is not a leaf, so it has a left child at child
            final int rightChild = child + 1;
            // if root has a right child, find larger child
            if (rightChild < items.size() && compareItems(items.get(rightChild),
                    items.get(child)) > 0) {
                child = rightChild;
            }
            if (compareItems(items.get(root), items.get(child)) < 0) {
                final T temp = items.get(root);
                items.set(root, items.get(child));
                items.set(child, temp);
                heapRebuild(child);
            }
        }
    }
    
    private int compareItems(final T item1, final T item2) {
        if (comparator == null) {
            return ((Comparable<T>) item1).compareTo(item2);
        } else {
            return comparator.compare(item1, item2);
        }
    }
} 
```

### 使用堆实现ADT优先队列
ADT优先队列的操作使用堆操作完美匹配，核心实现源码如下:
```java
public class PriorityQueue<T> {
    private final Heap<T> h;
    
    public PriorityQueue() {
        this.h = new Heap<>();
    }
    
    public PriorityQueue(final Comparator<T> comparator) {
        this.h = new Heap<>(comparator);
    }
    
    public boolean pqIsEmpty() {
        return h.heapIsEmpty();
    }
    
    public void pqInsert(final T newItem) {
        h.heapInsert(newItem);
    }
    
    public T pqDelete() {
        return h.heapDelete();
    }
}
```
堆不能替代二叉查找树成为表的实现，如果多项具有相同的优先级值，按出现的先后顺序排序处理相同优先级值的项，可以在节点中存储队列。
### 堆排序
使用堆类排序数组，需要首先将数组构建为堆，heapRebuild将半堆转化为堆，从后向前，每个都是半堆，一直向上就转化为堆了。算法说明如下:
```java
for ( index = n-1 down to 0)
    // Assertion: the tree rooted at index is a semiheap
    heapRebuild(anArray, index, 0)
    // Assertion: the tree rooted at index is a heap
```
index通常可以设置为(n-1)/2，转化为堆后，数组分为2个片区，左片区是堆，右片区是已经排序的元素，堆排序算法的不变式:
- 在步骤$k$后，Sorted区域包含anArray的$k$个最大值且有序;
- Heap区域中的项构成堆.
交换anArray[0]与anArray[last]，此时last位置是已经排序的项，last--，此时左侧的heap区构成新的半堆，使用HeapRebuild转换为堆.伪代码如下:
```java
+heapSort(in anArray: ArrayType, in n:integer)
// sorts anArray[0...n-1]
    // build initial heap
    for(index=n-1 down to 0){
        // invariant: the tree rooted at index is a semiheap
        heapRebuild(anArray,index,n)
    }
    last=n-1
    for(step=1 through n){
        Swap anArray[0 and anArray[last]
        last--
        heapRebuild(anArray,0,last)
    }
```
## JCF中的表和优先队列
JCF中类似于表的操作就是map，只是形式稍微有点不一样，Map的实现包含HashMap与TreeMap。
### JCF的map接口
## 小结
- ADT表支持面向值的操作;
- 表的基于数组与基于引用的线性实现只适用于特定的情形，如表小等;
- 二叉查找树是表的基于引用的非线性实现;
# 表的高级实现方案
散列是一种高级实现方案
## 平衡查找树
二叉查找树的效率取决于树高，按照前面章节的说法，插入或者删除元素的顺序会影响树高，通常都会使用二叉查找树的平衡变体的版本。
### 2-3树
2–3树是一种树型数据结构，内部节点（存在子节点的节点）要么有2个孩子和1个数据元素，要么有3个孩子和2个数据元素，叶子节点没有孩子，并且有1个或2个数据元素。节点有2-3个子节点，叶子节点都在同一层，与满二叉树类似，同为高度$h$的树，2-3树的节点数比满二叉树多，也就是说$n$个节点的2-3树的高度不大于$\lceil \log_{2}{(n+1)} \rceil $，2-3树也是递归定义的，若按照元素排序，则称为查找树。
如果一个内部节点拥有一个数据元素、两个子节点，则此节点为`2节点`。如果一个内部节点拥有两个数据元素、三个子节点，则此节点为`3节点`。当且仅当以下叙述中有一条成立时，$T$为2–3树:
- $T$为空，即T不包含任何节点;
- $T$为拥有数据元素$a$的2节点，若$T$的左孩子为$L$、右孩子为$R$，则
  - $L$和$R$是等高的2–3树；
  - $a$大于$L$中的所有数据元素；
  - $a$小于等于$R$中的所有数据元素。
- $T$为拥有数据元素$a$和$b$的3节点，其中a<b，若$T$的左孩子为$L$、中孩子为$M$、右孩子为$R$，则
  - $L$、$M$、和$R$是等高的2–3树；
  - $a$大于$L$中的所有数据元素，并且小于等于$M$中的所有数据元素；
  - $b$大于$M$中的所有数据元素，并且小于等于$R$中的所有数据元素。
2-3树的节点定义如下:
```java
public class TwoThreeTreeNode<T> {
    private T smallItem;
    private T midItem;
    private T largeItem;
    private final TwoThreeTreeNode<T> leftChild;
    private TwoThreeTreeNode<T> midChild;
    private final TwoThreeTreeNode<T> rightChild;
```
1. 遍历2-3树
   中序遍历的方式遍历
   ```java
   +inorder(in ttTree: TwoThreeTree)
   // traverses the nonempty  2-3 tree, ttTree, in sorted search-key order
   if(ttTree''s root node r is a left){
     visit the data item(r)
   }else if(r has two data items){
      inorder(left subtree of ttTree''s root)
      visit the first data item
      inorder(mid subtree of ttTree''s root)
      visit the second data item
      inorder(right subtree of ttTree''s root)
   }else{
      inorder(left subtree of ttTree''s root)
      visit the data item
      inorder(right subtree of ttTree''s root)      
   }
   ```
2. 查找2-3树
   算法与二叉查找树类似，2-3树比二叉查找树的优势就是2-3树与查找最短的二叉查找树的效率相同。但是也并不比二叉查找树的效率更高，主要是因为比较的节点次数都是差不多的，优势在于2-3树比较容易实现平衡，
3. 2-3树插入
   首先查找到递归终止的叶节点，如果节点只有一项，则加入变成2项，如果已有2项，则3者中的中间项上升到父节点，其余2项变成父节点的字节点，如果父节点项数>2则，则父节点执行此递归处理，此时父节点可能出现4个节点的情况，那么左面2项归左节点，右面2项归右节点。直至树满足2-3树条件要求，只要从根到插入新项的节点路径上存在只有一项的节点，则树高不会增长，如果都包含2个项，则要增加树高，到达根节点时，拆分出一个新的root节点。
   ```java
   +insertItem(in ttTree: TwoThreeTree, in newItem: TreeItemType)
   // inserts newItem into a 2-3 tree ttTree whose Items have distinct search keys that differ from newItem's search key
   let sKey be the search key of newItem
   Locate the leaf leafNode in which sKey belong ttTree
   Add newItem to leafNode
   if (leafNode now has three items){
      split(leafNode)
   }
   +split(inout n:TreeNode)
   // splits node n, which contains 3 items, Note: if n is not a leaf, it has 4 chidlren
   if (n is the root){
      create a new node p
   }else{
      Let p be the parent of n
   }
   replace node n with two nodes, n1 and n2, so that p is their parent
   Given n1 the item in n with the smallest search-key value
   Given n2 the item in n with the largest search-key value
   if(n is not a leaf){
      n1 becomes the parent of n's two leftmost children
      n2 becomes the parent of n's two rightmost children
   }
   move the item in n that has the middle search-key value up to p
   if (p now has three items){
      split(p)
   }
   ```
4. 2-3树的删除
   2-3树删除节点时，首先定位到节点$n$,如果不是叶节点，则查找中序后继，并与$n$交换，然后开始删除叶节点，如果叶节点包含2个值，只要删除一个就可以，如果删除后变成空节点，则需执行节点归并，首先检查兄弟节点，如果兄弟节点包含2项的节点则，在兄弟节点，空节点、父节点之间平衡值，如果没有，则将父节点的值下移到兄弟节点，并删除空节点，此时如果父节点不可用，则递归的执行节点的删除过程。删除算法的伪代码如下:
   ```java
   +deleteItem(in ttTree: TwoThreeTree, in searchKey: KeyType)
   // deletes from  the 2-3 tree the item whose search key equals searchKey. If the deletion is successful, the method returns true, If no such item exists, the operation fails and return false.
   Attempt to locate item theItem whose search key equals searchKey
   if (theItem is present){
      if (theItem is not in a leaf){
          swap item theItem with its inorder successor, which will be in a leaf theLeaf
      }
      // the deletion always begins at a leaf
      Delete item theItem from leaf theLeaf
      if (theLeaf now has no items){
        fix(theLeaf)
      }
      return true
   }
   return false
   +fix(in n: TreeNode)
   // Completes the deletion when node n is empty by either removing the root, redistributing values, or merging nodes. Note:if n is internal， it has one child
   if (n is the root){
     remove the root
   }else{
     Let p be the parent of n
     if (some sibling of n has two items){
        Distribute items appropriately among n, the sibling, and p
        if (n is internal){
            Move the appropriate child from sibling to n
        }
     }else{
        Choose an adjacent sibling s of n
        bring the appropriate item down from p into s

        if(n is internal){
            Move n''s child to s
        }
        remove node n
        if (p is now empty){
            fix(p)
        }
     }
   }
   ```
### 2-3-4树
定义与2-3树类似，比2-3树需要更少的树高。
- 查找遍历2-3-4树，与2-3树类似;
- 插入2-3-4树，主要的不同的是在插入的路径上碰到4-节点就直接拆分;
- 从2-3-4树中删除，
### 红黑树
2-3-4树是平衡的，且插入与删除操作只需要从根到叶节点遍历一次树，有一种特殊的二叉查找树，可以用来表示2-3-4树，就是红黑树，红黑树将2-3-4树中的各个3-节点-4节点表示为等效的二叉树，为了区分原始2-3-4树的2-节点与3-节点和4-节点生成的2-节点，使用红黑子节点引用，原始2-3-4树的所有子节点引用为黑，使用红子节点引用来链接拆分3-节点和4-节点生成的2-节点，红黑树的节点与二叉查找树的节点类似，但必须存储引用的颜色.
1. 查找与遍历红黑树
   因为红黑树是二叉查找树，所以可以使用二叉查找树的算法执行查找与遍历.
2. 红黑树的插入与删除
   将2-3-4树的插入算法调整为适用于红黑表示，要识别红黑形式的4-节点，只需要查找包含2个红引用的节点。这里还要仔细参考其他的文章.
### AVL树
AVL树是形式最古老的平衡二叉树，一种获得最小二叉查找树的方法是前序保存树到文件并恢复，此时恢复的树是具有最小高度的二叉查找树，但是每次插入后都执行这样的操作，成本太高，AVL树是一个折中，它维护接近最小高度的二叉查找树，基本策略是监视二叉查找树，插入与删除于普通查找树一样，然后检查树是是否仍为AVL树，也就是左右子树的高度差<=1，如果有，则重新排列平衡。排列平衡有2种方式(这里讲的太粗略了，啥也没看懂)
### 散列
地址计算器也就是散列函数(hash function)与散列表(hash table)。散列函数必须取出任意一个整数$x$，并将其映射到可用作数组索引的整数，散列函数:
- 计算简单快捷;
- 将各个项均匀的分布在散列表;
#### 散列函数
- 选择数字，从查找关键字选择固定的某位数字构成表的索引，这种方案的确定是不够均匀;
- 叠加，数字求和，分组求和;
- 模运算，一般，tableSize要选择质数，这样可以让表项均匀的分配到表中;
- 将字符串转换为整数有很多中方式，比如Horner原则
#### 解决冲突
冲突有2种解决方法:
- 将散列表中的另一个位置分配给新项;
- 更改散列表的结构，使数组位置table[i]可容纳多个项.
1. 开放寻址法
   其思想是若散列函数指示一个散列表中已经占用的位置，则探测其他空位置来放置新项，关键在于怎么探测新的地址，有3种方案:
   - 线性探测，就是顺序查找散列表的空位置，这种方案的缺点是表项在散列表中聚到一起，称为主要聚集，导致探测查找时间增加;
   - 二次探测，线性探测的调整版，可以消除主要聚集，主要的思路就是不连续探测位置，而是为下一个位置的选择增加系数，比如$n^{2}$，n从1开始，二次探测也会产生聚集，称为次要聚集;
   - 双散列，双散列的不同就是探测序列步长的确定依赖于关键字，定义为二次散列，所以也叫双散列，原则就是$h_{2} (key)\ne 0$与$h_{1} \ne h_{2} $，若表大小与探测步伐大小互质(最大公约数为1)则总能访问所有的表位置，散列表的大小是一个质数，所以与所有的步伐大小互质;
   - 增加散列表的大小，散列表逐渐变满则冲突肯定增加，需要扩容，但要保证是质数大小，同时因为大小变了，散列函数也变了，需要重新计算原来数据的位置，不能简单的复制.
2. 重新构建散列表
   在同一个位置安置多个项，有2种方法:
   - 桶，散列表中的元素是一个桶，也就是数组，可以存多个;
   - 分离链，散列表是一个链表数组，
#### 散列效率
#### 如何确立散列函数
- 散列函数的计算要简单快捷，
- 散列函数应将数据均匀的分布在整个散列表上;
- 散列函数分布随机数据的性能如何，只有数据实现标准的随机分布，那么均匀才有可能；
- 散列函数分布非随机数据的性能如何。
定义散列函数有2个基本的原则:
- 散列函数的计算要包含完整的查找关键字;
- 若散列函数使用模运算，则底数一定是质数;
### 表遍历：散列的低效操作
散列表对有序遍历的操作效率很低，只要涉及到比较或者顺序类的操作，散列的实现方案都是效率比较低的。
### JCF的HashTable与TreeMap
1. HashTable
   使用散列实现的表。
2. TreeMap
   红黑树实现的表，TreeMap可以返回子树，这种操作为什么我没用到过。
## 按多种形式组织数据

# 第14章 图
## 术语
图提供了演示数据的方式，还表示数据项之间的关系，图由顶点与边构成， 子图由图的顶点子集与边的子集构成，顶点之间有边就称为相邻(adjancent)，若图中的每对顶点之间都有路径则称为连通的，若每对顶点之间都有边，则是完全图，也叫做强连通图，一般图的边集是不能存在重复边的，存在重复边的图叫做多重图。边可以叫标记，可以表示权重，这样的图叫做加权图，边可以有方向，这样的图叫做有向图。
## 将图作为ADT
图可以看做抽象数据类型，基本操作：
- 构建一个空图;
- 确定图是否为空;
- 确定图中顶点的数目;
- 确定图中边的数目;
- 确定2个给定的顶点之间是否存在边，对于加权图返回权值;
- 插入顶点;
- 插入边;
- 从图中删除一个顶点以及该顶点与其他顶点之间的边;
- 删除边;
- 检索顶点。

### 实现图
图的2种最常用的实现方式邻接矩阵与邻接表。
- 邻接矩阵是一个n*n的数组，无向图的邻接矩阵是对称的，加权图可以表示权重;
- 邻接表，由n个链表构成，可以直接存储节点值语权重;
根据图的使用方式不同，可以选择不同的实现。2种图中最常见的操作:
- 确定顶点$i$到顶点$j$是否存在边（这种方式适合使用邻接矩阵，因为可以直接定位，不需要查找链表）
- 查找给定顶点$i$的所有邻接顶点(这种方式适合邻接表，因为不需要遍历行，直接取出邻接表的链表即可)
邻接矩阵的空间总是比邻接表要更多的。JCF中没有包含ADT图，可以有不同的实现。
```java
package com.zyx.java.adt.chapter14;

import java.util.Map;
import java.util.TreeMap;
import java.util.Vector;
import java.util.stream.IntStream;

/**
 * Created by zhangyongxiang on 2022/11/29 1:39 AM
 **/
public class Graph {
    /**
     * num of vertices in the graph
     */
    private int numVertices;
    
    /**
     * num of edges in the graph
     */
    private int numEdges;
    
    /**
     * for each vertex, we need to keep track of the edges,
     */
    private Vector<TreeMap<Integer, Integer>> adjList;
    
    public Graph(final int n) {
        this.numVertices = n;
        this.numEdges = 0;
        this.adjList = new Vector<>();
        IntStream.range(0, n).forEach(i -> this.adjList.add(new TreeMap<>()));
    }
    
    public int getNumVertices() {
        return this.numVertices;
    }
    
    public int getNumEdges() {
        return this.numEdges;
    }
    
    public int getEdgeWeight(final Integer source, final Integer target) {
        return this.adjList.get(source).get(target);
    }
    
    public void addEdge(final Integer source, final Integer target,
            final int weight) {
        this.adjList.get(source).put(target, weight);
        this.numEdges++;
    }
    
    public void removeEdge(final Integer source, final Integer target) {
        this.adjList.get(source).remove(target);
        this.numEdges--;
    }
    
    public Edge findEdge(final Integer source, final Integer target) {
        return new Edge(source, target, this.adjList.get(source).get(target));
    }
    
    public Map<Integer, Integer> getAdjacent(final Integer source) {
        return this.adjList.get(source);
    }
}
```
## 图的遍历
图遍历操作可以确定图是否是连通的，遍历图不一定能访问到图的所有节点，2种图的遍历算法:
- 深度优先查找，DFS，deep-frist search，一种回溯的思路；简单的递归形式如下:
  ```java
  +dfs(in v:Vertex)
  // traverse a graph begingin at Vertex v by using a dfs: recursive version
  Mark v as visited
  for(each unvisited vertex u adjacent to v)
     dfs(u)
  ```
  使用栈的版本如下:
  ```java
  dfs(in v: Vertex)
  // traverse a graph beginning at vertex v by using dfs: iteration version
  s.createStack()
  // push v onto the stack and mark it
  s.push(v)
  Mark v as visited
  // loop invariant: there is a path from vertex v at the botom of the stack to the vertex at the top of s
  while(!s.isEmpty()){
    if(no unvisited vertices are adjacent to the vertex on the top of the stack){
        s.pop()
    }else{
        select an unvisited vertex u adjacent to the vertex on the top of s
        s.push(u)
        mark u as vivited
    }
  }
  ```
- 广度优先查找，BFS，breadth-first search，先访问所有的邻接节点，再访问其他节点。要使用队列，迭代版本如下:
  ```java
  +bfs(in v: Vertex)
  // traverse a graph beginning at Vertex v by using a breadth-first search: Iterative version
  q.createQueue()
  // add v to queue and mark it
  q.enqueue(v)
  Mark v as visited
  while(!q.isEmpty()){
    w=q.dequeue()
    // loop invariant: there is a path from vertex w to every vertex in the queue q
    for(each unvisited vertex u adjacent to w){
        Mark u as visited
        q.enqueue(u)
    }
  }
  ```
JCF实现的BFS代码:
```java
public class BFSIterator implements Iterator<Integer> {
    private Graph g;
    private int numVertices;
    private int count;
    private int[] mark;
    private int iter;
    public BFSIterator(final Graph g) {
        this.g = g;
        this.numVertices = g.getNumVertices();
        this.mark = new int[this.numVertices];
        Arrays.fill(this.mark, 0, this.numVertices, -1);
        this.count = 0;
        this.iter = -1;
        startSearch();
    }
    @Override
    public boolean hasNext() {
        return this.iter >= 0 && this.iter < this.numVertices;
    }
    @Override
    public Integer next() {
        if (hasNext()) {
            return this.mark[this.iter++];
        } else {
            throw new NoSuchElementException();
        }
    }
    protected void startSearch() {
        for (int v = 0; v < this.numVertices; v++) {
            if (this.mark[v] == -1) {
                search(v);
            }
        }
    }
    protected void search(final Integer vertex) {
        final LinkedList<Integer> q = new LinkedList<>();
        Map<Integer, Integer> m;
        Set<Integer> connectedVertices;
        Integer v;
        q.add(vertex);
        while (!q.isEmpty()) {
            v = q.remove();
            if (this.mark[v] == -1) {
                this.mark[v] = this.count++;
                m = this.g.getAdjacent(v);
                connectedVertices = m.keySet();
                for (final Integer w : connectedVertices) {
                    if (this.mark[w] == -1) {
                        q.add(w);
                    }
                }
                
            }
        }
    }
}
```
## 图的应用
### 拓扑排序
拓扑排序就是自然顺序，拓扑排序中么，若x有到y的边，则x在y之前。有可能有多种拓扑排序。确定拓扑排序的算法可以是一种递归算法:
- 查找任意一个无后继的顶点，取出放到顶点列表头，删除所有相关的边；
- 重复执行上面的过程
最终得到的顶点列表就是拓扑排序节点.
```java
+topSort(in theGraph:Graph)
// arranges the vertices in graph theGraph into a topological order and places them in list aList return aList
n = number of vertices in theGraph
for(step=1 through n){
    select a vertex v that has no successors
    aList.add(0,v);
    delete from theGraph vertex v and its edges
}
return aList;
```
还有一种使用前驱节点的算法实现拓扑排序，思路如下:
```java
+topSort(in theGraph: Graph): List
//arranges the vertices in graph theGraph into a topological order and
//  places them in list aList return aList
s.createStack()
for(all vertices v in the graph theGraph){
    if(v has no predecessors){
        s.push(v)
        mark v as visited
    }
}
while(!s.isEmpty()){
    if(all vertices adjacent to the vertex on the top of the stack have been visited){
        v=s.pop()
        aList.add(0,v)
    }else{
        select an unvisited vertex u adjacent to the vertex on the top of the stack
        s.push(u)
        Mark u as visited
    }
}
```
### 生成树
树是特殊的无向图，联通无环，无向联通图G的生成树(spanning tree)是G的一个子图，包含G的所有的节点以及形成树的足够的边。有环的无向联通图，删除边直至无环，则得到图的生成树，有3个事实:
- $n$个顶点的无向联通图至少有$n-1$条边;
- 有$n$个顶点和$n-1$条边的无向联通图不包含环;
- 有$n$个顶点，边数大于$n-1$的无向联通图至少包含一个环;
通过顶点数与边数可以确定联通图是否包含环，图的生成树有2种算法都是基于遍历的.
- DFS生成树，深度遍历图时，经过的边就是生成树的边，没有遍历到的边删掉，就得到生成树（边数最少的联通图），简单的过程如下:
  ```java
  +dfsTree(in v: Vertex)
  // forms a spanning tree for a connected undirected graph, beginning at vertex v by using dfs: Recursive version
  Mark v as visited
  for(each unvisited vertex u adjacent to v){
    Mark the edge from u to v
    dfsTree(u)
  }
  ```
- BFS生成树，思路与DFS是一致的。
### 最小生成树
最小生成树，就是边的权值最小的生成树，只有在边具有权重的情况下才有效，一个算法就是Prim算法。算法的思想是开始时算法只包含起始顶点，在各个阶段，算法选择一条成本最低的边，边从树中的一个顶点开始，在一个未在树中的顶点结束，将该边与它的结束节点添加到树中。伪代码如下:
```java
+PrimsAlgorithm(in v:Vertex)
// Determine a minimum spanning tree for a weightted connected undirected graph whose weights are nonnegative
// beginning with any vertex v
Mark vertex v as visited and include it in the minimum spanning tree
while(there are unvisited vertices){
    Find the least-cost edge(v, u) from a visited vertex v to some unvisited vertex u
    Mark u as visited
    add the vertex u and the edge(v, u) to the minimum spanning tree
}
```
### 最短路径
加权有向图的常见操作是得到2点见的最短路径，这里的最短路径是指的权值之和最小。Dijkstra提出了一个算法可以确定给定原始点到其他顶点的最短路径，该算法使用选取的顶点集合$vertexSet$以及一个数组$weight$，其中$weight[v]$是从顶点0到$v$，通过$vertextSet$中顶点的最短路径的权值.
- 开始时，$vertexSet$只包含顶点0，而$weight$含从顶点0到所有其他顶点的单边路径的权值，也就是$weight[v]=matrix[0][v]$
- 查找一个不在$vertexSet$,且使$weight[v]$最小的顶点$v$，将$v$添加到$vertexSet$，对所有不在$vertexSet$的$u$，检查$weight[v]$的值，确保最小的，$weight[u]= min(wight[u], weight[v]+matrix[v][u])$，持续不断的迭代，直到所有的节点都在$vertexSet$中。
伪代码如下:
```java
+shortestPath(in theGraph: Graph, in weight:WeightArray)
// finds the minimum-cost paths between an origin vertex
// (vertex 0) and all other vertices in a weighted directed graph theGraph.
// the array weight contains theGraph's weights which are nonnegative
//  Step 1: initialization
Create a set vertexSet that contains only vertex 0
n = number of vertices in theGraph
for(v=0 through n-1){
    weight[v]=matrix[0][v]
}
// Step 2: through n
// invariant: For v not in vertexSet， weight[v] is the smallest weight of all paths from 0 to v that pass
// through only vertices in vertexSet before reaching v.
// For v in vertexSet, weight[v] is the smallest weight of all paths from 0 to v(including paths outside vertexSet), and the shortest path from 0 to v lies entirely in vertexSet.
for(step=2 through n){
    Find the smallest weight[v] such that v is not in vertexSet
    Add v to vertexSet
    for(all vertices u not in vertexSet){
        if(weight[u]>weight[v]+matrix[v][u]){
            weight[u]=weight[v]+matrix[v][u]
        }
    }
}
```
### 回路
循环的别名，无向图中的路径从$v$开始，正好通过图的各边一次，并在$v$终止，则称为Euler回路，当且仅当通过每个顶点的边数为偶数时，才存在Euler回路.
### 一些复杂问题
- 流动推销员问题;
- 三用品问题;
- 四颜色问题.
## 小结
- 图的2种最常见的实现方式是邻接矩阵与邻接表，2种实现方式各有优缺点，应根据应用程序的实际需要来选择;
- 图的查找是栈/队列的重要应用，DFS是一种图遍历算法，使用栈跟踪一系列未访问的顶点，算法到达图的最深处，然后折回，BFS算法使用队列跟踪一系列未访问的顶点，在访问所有邻接顶点后，才进一步遍历图;
- 拓扑排序生成无环有向图的顶点的线性顺序，若图中有从顶点$x$到顶点$y$的有向边，则$x$在$y$之前;
- 树是无环的有向连通图，无向连通图的生成树是一个子图，包含图的所有顶点以及构成树的足够边，DFS/BFS遍历算法可以生成DFS/BFS生成树;
- 加权无向图的最小生成树是边值和最小的生成树，一个图可以包含若干颗最小生成树，但边值和相同;
- 在加权有向图中，2个顶点之间的最短路径是边权值和最小的路径;
- 无向图的Euler回路是一个环，它从顶点$v$开始，恰好通过图中的每条边一次，在$v$终止;
- 无向图的Hamilton回路是一个环，它从顶点$v$开始，正好通过图中的每个顶点一次，在$v$终止.

# 第15章 外部方法
## 了解外部存储
文件可以用于存储大量的数据，且可以是永久的。因为数据量大，不能直接通过内存处理全部数据，必须修改操作数据的方式，文件访问分2种:
- 顺序访问文件(sequential access file)，类似链表，必须顺序移动到指定位置来访问;
- 随机访问文件(random access file)，类似数组，允许直接访问给定位置的数据.
文件由数据记录组成，数据记录可能是整数或者记录，将文件中的记录组织为块，每个块的大小固定，可以按照线性顺序为文件的块编号，随机访问时可以指定块号，随机访问文件类似于数组的数组，所有的输入输出都是在块级别，这称为块访问(block access)，读写块的命令:
>buf.readBlock(dataFile, i)

读区文件dataFile的第i块访问buf中，buf称为缓冲区，当数据从一个进程或者位置移到另一个进程或者位置时，缓冲区用于临时存储数据。
>buf.writeBlock(dataFile, i)

buf写会dataFile文件的第i块
>buf.writeBlock(dataFile, n+1)

追加块的内容，IO块的时间比内存处理块的时间更多，所以访问记录时要减少块访问的次数。要减少块访问的次数，需要对数据排序或者具备一定的查找功能。
## 排序外部文件的数据
排序存储在外部文件中的数据，外部文件包含1600雇员记录，按照社会保险号排序这些记录，每个块包含100条记录，文件包含16个块，设程序每次访问的内存只能操作300条记录，即3个块。归并排序可以处理这种不能一次在内存中加载所有数据的排序，归并算法的基本原理是，将2个有序的部分合并为一个有序的部分。归并排序排序外部文件的2个阶段:
- 排序各个记录块;
- 执行一系列归并;
1. 排序各个记录块
   从$F$中读区一个块，使用内部排序算法排序后，写入到文件$F_1$中，全部处理完后，$F_1$包含所有的有序块。
2. 归并有序块
   $F_1$归并到$F_2$再从$F_2$归并到$F_1$，基本就是这个过程，因为内存能处理300个记录，分为in1、in2与out3个大小一样的内存区，out用于保存in1与in2归并的结果，满时写入到文件中，in1或者in2空时从文件块中加载记录。
将$F_1$中任意大小的有序段$R_i$与$R_j$归并到$F_2$的高级算法如下:
```java
Read the first block of Ri into in1
Read the first block of Rj into in2
while(either in1 or in2 is not exhausted){
    select the smallest leading record of in1 and in2 and place it into the next position of out(
        if one of the buffers is exhausted, select the leading record from the other
    )
    if(out is full{
        Write its contents to the next block of F2
    }
    if(in1 is exhausted and blocks remain in Ri){
        Read the next block into in1
    }
    if(in2 is exhausted and blocks remain in Rj){
        Read the next block into in2
    }
}
```
## 外部表
在外部存储文件中组织记录的技术，支持高效的执行检索、插入、删除和遍历等ADT表操作。假设随机文件中的记录是有序的（使用前面的算法排序），且作为外部表的表项，则遍历的算法如下:
```java
+traverseTable(in dataFile: File, in numberOfBlocks:integer, in recordsPerBlock:integer)
// traverses the sorted file dataFile in sorted order. visiting each node
// read each block of file dataFile into an internal buffer buf
for(blockNumber = 1 through numberOfBlocks){
    buf.readBlock(dataFile, blockNumber)
    // visit each record in the block
    for(recordNumber = i through recordsPerBlock){
        visit record buf.getRecord(recordNumber-1)
    }
}
```
在有序文件上执行tableRetrieve操作，使用二叉查找算法就可以
```java
+tableRetrieve(in dataFile: File, in recordsPerBlock:integer, in first:integer, in last:integer, in searchKey:KeyType)
// searches blocks first through last of file dataFile and returns the record whose search key equals // //searchKey, the operation fails and returns null if no such items exists
if(first>last or nothing is left to read from dataFile){
    return null
}
else{
    // read middle block of file dataFile into buffer buf
    mid=(first+last)/2
    buf.readBlock(dataFile, mid)
    if(searchKey>=buf.getRecord(0).getKey()&&searchKey<=buf.getRecord(recordsPerBlock-1).getKey()){
        // desired block is found
        Search buffer buf for record buf.getRecord(j) whose search key equals searchKey
        if(record is found){
            tableItem=buf.getRecord(j)
            return tableItem
        }else{
            return null
        }
    }else if(searchKey<buf.getRecord(0).getKey()){
        return tableRetrieve(dataFile, recordsPerBlock, first, mid-1, searchKey)
    }else{
        return tableRetrieve(dataFile, recordsPerBlock, mid+1, last, searchKey)
    }
}
```
- 优点: 数据有序，可以使用二叉查找;
- 缺点: 数据插入或者删除，需要移动元素到后续所有的块.
适合变更不多的外部表实现方案。
### 确定外部文件的索引
2种最佳的外部表实现方案是内部散列/查找树方案的变体。主要的思想就是建立数据文件的索引，类似图书馆编目一样。数据文件的索引只是一个文件，称为索引文件，索引文件包含数据文件中各个记录的索引记录，包含2个部分: 关键字与指针。维护索引文件的好处:
- 索引记录比数据记录小的多;
- 不需要按照特定的顺序维护数据文件;
- 可以同时维护若干个索引

索引文件先考虑简单的方式，也就是按照关键字有序排列，所以可以使用二分查找:
```java
tableRetrieve(in tIndex:File, in tData:File, in searchKey:KeyItemType):TableItemType
// returns the record whose search key equals searchKey，where tIndex is the index file 
// and tData is the data file. the operation fails and returns null if no such record exists.
if(no blocks are left in tIndex to read){
    return null
}else{
    // read the middle block of index
    mid=number of middle block of index file tIndex
    buf.readBlock(tIndex,mid)
    num=indexRecordsPerBlock
    if(searchKey>=buf.getRecord(0).getKey()&&searchKey<=buf.getRecord(num-1).getKey()){
        //desired block of index file found
        Search buf for index file record buf.getRecord(j) whose key value equals searchKey
        if(index record buf.getRecord(j) is found){

        }
    }
    ....// 后续这里看书吧，不写了
}
```
### 外部散列
外部散列方案中，table的每一项包含一个块指针，指向列表开头，列表由索引记录的块组成。散列的是索引文件而不是数据文件，检索的源代码可以看书。
### B树
索引文件组织为外部查找树。前面的方案是组织成外部散列。使用块编号可以将外部文件的块组织成树结构。
## 小结