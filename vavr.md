Vavr前身叫做javaslang，是一个java8+的函数库，provides persistent data types and functional control structures.
[TOC]
# introduction
## Functional Data Structures in java8 with Vavr
Java8的lambda表达式让我们可以创建完美的API，它们增强的java的表达式功能，Vavr通过lambda创建了很多机遇函数式编程的新特性，其中一个就是函数式的集合库，是替代java标准集合库的完美替代者。
## 函数式编程
在开始讲述一些最基本的数据结构前，这一节会帮助你了解下，创建Vavr与Java集合库的一些背景。
### 副作用
Java 应用程序通常有很多副作用。 它们使某种状态发生变异，也许是外部世界。 常见的副作用是更改对象或变量、打印到控制台、写入日志文件或数据库。 如果副作用以不受欢迎的方式影响我们程序的语义，则它们被认为是有害的。
例如，如果一个函数抛出一个异常并且这个异常被解释，它被认为是影响我们程序的副作用。 此外，异常就像非本地 goto 语句。 它们破坏了正常的控制流。 然而，现实世界的应用程序确实会产生副作用。
```java
int divide(int dividend, int divisor) {
    // throws if divisor is zero
    return dividend / divisor;
}
```
使用函数式的编程场景，我们更倾向把副作用（异常）压缩到一个Try中
```java
Try<Integer> divide(Integer dividend, Integer divisor) {
    return Try.of(() -> dividend / divisor);
}
```
这样，函数不会再抛出异常，我们通过Try让可能发生的失败暴漏出来。
### 引用透明度
对于一个函数，或者更普遍的表达式来说，引用透明指的是一个调用可以在不影响程序行为的情况下被它的值替换，简单来说，给出以下输入，输出是一致的
```java
// not referentially transparent
Math.random();

// referentially transparent
Math.max(1, 2);
```
如果函数中的所有的表达式都是引用透明的，那么这个函数被称为透明函数，由纯函数组成的应用程序虽然很可能在编译后才能工作，但是我们能够对此进行推理。 单元测试很容易编写，调试成为过去的遗物。
### 对值的深入认识
Rich Hickey，Clojure的创建者对值的问题做了非常伟大的讲述，他认为不可以变值是最有趣的；原因如下：
- 不可变值是线程安全的，不需要加锁;
- 是稳定的，因为equals与hashCode行为不变，是可靠的hash结构的key;
- 不需要克隆;
- 在未经检查的转换中能保证类型安全，编写更好java代码的关键就是使用透明函数与不可变值。
Vavr为了实现这些目标，提供了必要的控制与集合。
## 容器数据结构
Vavr的集合库由大量的基于lambda的函数式数据结构组成，与java原生的集合库公用的接口只有Iterable，主要的原因是，java原生集合接口的设值方法不会返回集合中的对象。
### 可变数据结构
java是一个OOP语言，我们把数据的状态封装到对象来实现数据隐藏并提供Getter/Setter方法来控制这些状态，java集合框架就是基于这个观点创建的。
```java
interface Collection<E> {
    // removes all elements from this collection
    void clear();
}
```
今天，我将 void 返回类型理解为一种气味。 这是副作用发生的证据，状态发生了突变。 共享可变状态是一个重要的失败来源，不仅在并发设置中。
### 不可变数据结构
不可变数据结构在创建后就不能变更，在java中，他们通常用于一个一个集合wrapper的角色，如下：
```java
List<String> list = Collections.unmodifiableList(otherList);

// Boom!
list.add("why not?");
```
有很多库都提供了类似这样的包装方法，作用都是返回集合的不可变的视图，传统上，调用变更方法，会抛出运行时异常。
### 一致性数据结构
一致性数据结构会保存数据的以前的版本，因此是变相的可不变，一致性数据结构允许任何版本上的变更与查询。
很多操作的变更范围都不是很大，每次都完全copy数据效率不高，为了节省时间与内存，识别版本之间相似的内容并共享相似的内容是非常重要的。
## 函数式数据结构
也可以叫做透明函数数据结构，它们都是不可变的与一致性的，函数式数据结构的方法都是引用透明的。Vavr开发了大量广泛使用的函数式数据结构，下面的例子将会深入的介绍。
### LinkedList
一个广泛使用的并且也是最简单的函数式数据结构是LinkedList，它是一个有着头节点与尾节点的列表，一个LinkedList的行为更加类似于一个Stack，定义了LIFO的一些方法。
在Vavr中，我们这样来实例化一个List
```java
// = List(1, 2, 3)
List<Integer> list1 = List.of(1, 2, 3);
```
列表中的每个元素都是一个分离的node，最后一个元素的tail是nil。
如下图
![初始化linkedlist](vavr/vavr-linkedlist.png "创建一个list")
下面的操作可以让我们共享List不同版本的元素
```java
// = List(0, 2, 3)
List<Integer> list2 = list1.tail().prepend(0);
```
头节点0被链接到原始链表的头节点的尾链表的前面，原始的链表保持不变。如下图：
![链表的多个版本](vavr/vavr-linkedlist-multiversion.png "链表的多个版本")
这个操作可以在常数的时间内完成，换句话说，这个操作不依赖链表的大小，大多数其他的操作都是线性时间完成的，在Vavr中，使用接口LinearSeq表达线性操作。
如果我们需要一些读区操作在常量时间内完成，可以使用Vavr的Array与Vector，它们都有随机存取的能力。数组类型低层使用的是java原生的数组类型，插入与删除都需要线性的时间，向量表的实现介于数组与线性表之间，它常用在大量随机存取与变更频繁的场景中。
事实上，linked list可以用来实现Queue数据结构。
### Queue
一个高效的函数式Queue可以通过2个linkedlist实现，前面的线性表持用反向入队的元素，后面的linkedlist持用正向入队的元素；2种入队操作都是常量时间的。
```java
Queue<Integer> queue = Queue.of(1, 2, 3)
                            .enqueue(4)
                            .enqueue(5);
```
Queue由3个元素初始化完成，然后2个元素进入rear线性表。
![队列](vavr/queue-two-linkedlist.png)
如果front链表的元素都出队了，rear链表就回反转称为新的front链表。
![rear链表反转](vavr/queue-rear-reversed.png)
当元素出队时，我们得到队头元素与剩余的队列元素队列，剩余元素的队列是一个新的版本的队列，因为队列也是一种函数式数据结构，它必须是不可变的与一致性的，原始的Queue不会受到影响。
```java
Queue<Integer> queue = Queue.of(1, 2, 3);

// = (1, Queue(2, 3))
Tuple2<Integer, Queue<Integer>> dequeued =
        queue.dequeue();
```
当队列是空的，出队操作会发生什么？dequeue()会抛出一个NoSuchElementException的异常，函数式的处理方式是返回一个Optional的结果。
```java
// = Some((1, Queue()))
Queue.of(1).dequeueOption();

// = None
Queue.empty().dequeueOption();
```
optional的结果不论是否是空的都可以进一步的处理
```java
// = Queue(1)
Queue<Integer> queue = Queue.of(1);

// = Some((1, Queue()))
Option<Tuple2<Integer, Queue<Integer>>> dequeued =
        queue.dequeueOption();

// = Some(1)
Option<Integer> element = dequeued.map(Tuple2::_1);

// = Some(Queue())
Option<Queue<Integer>> remaining =
        dequeued.map(Tuple2::_2);
```
### 排序set
是比queue更频繁使用的数据结构，我们用二叉树来模拟set的操作，二叉树是由一些包含值与最多2个孩子的node组成。
我们构建一个二叉搜索树，通过Comparator比较元素的顺序，即左子树的所有的节点值\<当前节点的值，右子树的所有的值大于当前节点的值。
```java
// = TreeSet(1, 2, 3, 4, 6, 7, 8)
SortedSet<Integer> xs = TreeSet.of(6, 1, 3, 2, 4, 7, 8);
```
![](vavr/set-binary-tree.png)
在这样的树上搜索会花费O(logn)的时间复杂度，我们从root开始搜索，判断是否找到了元素，因为我们知道元素的全部顺序，所以我们可以决定去左/右子树继续寻找。
```java
// = TreeSet(1, 2, 3);
SortedSet<Integer> set = TreeSet.of(2, 3, 1, 2);

// = TreeSet(3, 2, 1);
Comparator<Integer> c = (a, b) -> b - a;
SortedSet<Integer> reversed = TreeSet.of(c, 2, 3, 1, 2);
```
大多数的树操作带有固有的递归性，插入操作与搜索操作时类似的，当搜索到达终点时，就回创建一个的节点，整个路径会进行一定的重构达到平衡；
```java
// = TreeSet(1, 2, 3, 4, 5, 6, 7, 8)
SortedSet<Integer> ys = xs.add(5);
```
![](vavr/set-add-element.png)
在vavr中，我们是使用红黑树来实现二叉搜索树的，它使用一种特殊的颜色策略来保证插入与删除后的树的平衡。
## 集合的状态
一般来说，我们观察到编程语言的演变。 好的功能会遗留下来，其他的则会慢慢消失。 但 Java 不同，它必然永远向后兼容。 这是一种力量，但也会减缓演变。
Lambda让java与scala更接近了，虽然它们目前还是有很大的不同；Martin Odersky认为java的Stream是iterator的另一种形式，java8的Stream API提升了集合的操作，Stream做的是定义一个计算单元，把这个单元关联到一个特定的结合上。
```java
// i + 1
i.prepareForAddition()
 .add(1)
 .mapBackToInteger(Mappers.toInteger())
```
这就是Java 8Stream的工作方式，它是java集合上的一个可计算层。
```java
// = ["1", "2", "3"] in Java 8
Arrays.asList(1, 2, 3)
      .stream()
      .map(Object::toString)
      .collect(Collectors.toList())
```
Vavr收到Scala的启发，
```java
// = Stream("1", "2", "3") in Vavr
Stream.of(1, 2, 3).map(Object::toString)
```
### Seq
Seq是一个接口，表示实现的集合类的元素是顺序的，连续的；上面讲的Linked List、Stream、Lazy Linked List都是Seq接口的实现类，它允许我们处理可能是无限长的元素的序列。
![](vavr/seq.png)
所有的集合都是Iterable的实现类，因为可以在的for-循环中使用。
```java
for (String s : List.of("Java", "Advent")) {
    // side effects and mutation
}
```
我们也可以通过内化的池技术与lambda来实现同样的行为
```java
List.of("Java", "Advent").forEach(s -> {
    // side effects and mutation
});
```
不论如何，正如我们前面看到的例子，我们更喜欢表达式返回结果而不是啥都没有，下面看一个简单的例子，
```java
String join(String... words) {
    StringBuilder builder = new StringBuilder();
    for(String s : words) {
        if (builder.length() > 0) {
            builder.append(", ");
        }
        builder.append(s);
    }
    return builder.toString();
}
```
函数式的表达方式是：
```java
String join(String... words) {
    return List.of(words)
               .intersperse(", ")
               .foldLeft(new StringBuilder(), StringBuilder::append)
               .toString();
}
```
使用vavr可以实现非常丰富多彩的操作，这里使用流式函数调用完成功能，还有更简单的写法：
```java
List.of(words).mkString(", ");
```
### Set与Map
序列非常重要，但是还不够完整，因为无法表达Sets与Maps，因为它们不是连续的，是基于树的。
![](vavr/set-map.png)
上面我们描述了如何使用二叉搜索树来模拟Set，一个排序Map相比于排序Set的区别就是是key/value结构的，并且按照key排序。
HashMap是由HAMT实现的，HashSet是基于key-key的HashMap实现的。
我们的Map没有特殊的Entry类型来表达key-value对，我们使用了元组的概念，Tuple2类似于Entry，可以用来表达pair，元组的值是可以枚举的。
```java
// = (1, "A")
Tuple2<Integer, String> entry = Tuple.of(1, "A");

Integer key = entry._1;
String value = entry._2;
```
Vavr中大量使用了Maps与Tuples，多值的函数返回类型使用元组是必然的。
```java
// = HashMap((0, List(2, 4)), (1, List(1, 3)))
List.of(1, 2, 3, 4).groupBy(i -> i % 2);

// = List((a, 0), (b, 1), (c, 2))
List.of('a', 'b', 'c').zipWithIndex();
```
# Getting started
使用maven的方式
# 使用指南
Vavr中包含一些设计良好的基本类型，这些类型基本是java中没有的或者不太完善的，比如Tuple、Value与lambda。
在Vavr中，所有的内容主要由下面的部分组成
![](vavr/vavr-architecture.png)
## 元组
java里面没有元组类型，一个元组包含固定数量的元素，这些元素被当成一个整体看待，与数组或者线性表不同，一个元组可以持有不同类型的元素，但是元组是不可变的，元组类型有Tuple1、Tuple2、Tuple3.。。。，现在最多有8元组。
### 创建元组
```java
// (Java, 8)
Tuple2<String, Integer> java8 = Tuple.of("Java", 8); 

// "Java"
String s = java8._1; 

// 8
Integer i = java8._2; 
```
### 组件映射
使用Function
```java
// (vavr, 1)
Tuple2<String, Integer> that = java8.map(
        s -> s.substring(2) + "vr",
        i -> i / 8
);
```
### 使用mapper映射
```java
// (vavr, 1)
Tuple2<String, Integer> that = java8.map(
        (s, i) -> Tuple.of(s.substring(2) + "vr", i / 8)
);
```
### 转换元组
```java
// "vavr 1"
String that = java8.apply(
        (s, i) -> s.substring(2) + "vr " + i / 8
);
```
## Functions
函数式编程就是值与值的转换，java8提供了Function与BiFunction类型，Vavr提供了0->8个参数的Function类型，名字类似于Function[n]，如果你需要一个Function抛出检查异常，可以是使用CheckedFunction[n]，下面的lambda表达式创建了一个Function，计算2个数的和
```java
// sum.apply(1, 2) = 3
Function2<Integer, Integer, Integer> sum = (a, b) -> a + b;
```
也可以使用静态的工厂方法Function3.of(....)等，从方法引用创建Function。
```java
Function3<String, String, String, String> function3 =
        Function3.of(this::methodWhichAccepts3Parameters);
```
事实上，Vavr函数式接口是java8函数式接口的变体，提供的特性有：
- 组合
- Lifting
- Currying
- Memoization
### Composition
你可以组合函数，从数学的角度来说，函数组合就是一种函数处理另一个函数结果以产生第三个值的用法，比如：函数f，X->Y与函数g: Y->Z,可以组合产生一个新的函数h:g(f(x)),产生了映射X->Z。也可以使用andThen实现函数组合。
```java
Function1<Integer, Integer> plusOne = a -> a + 1;
Function1<Integer, Integer> multiplyByTwo = a -> a * 2;

Function1<Integer, Integer> add1AndMultiplyBy2 = plusOne.andThen(multiplyByTwo);

then(add1AndMultiplyBy2.apply(2)).isEqualTo(6);
```
或者使用compose
```java
Function1<Integer, Integer> add1AndMultiplyBy2 = multiplyByTwo.compose(plusOne);

then(add1AndMultiplyBy2.apply(2)).isEqualTo(6);
```
### Lifting
您可以将偏函数提升为返回 Option 结果的全函数。 术语偏函数来自数学。 从 X 到 Y 的偏函数的定义是，定义函数 f: 对于 X 的某个子集 X′ 存在X′ → Y，这个函数来源于f: X → Y ，但是不要求，每个X
的元素都有对应的Y。这意味着偏函数仅适用于某些输入值。 如果使用不允许的输入值调用该函数，则通常会引发异常。
下面的divide方法就是一个偏函数，只接受非0值。
```java
Function2<Integer, Integer, Integer> divide = (a, b) -> a / b;
```
我们把divide函数提升为对所有值都有效的全函数。
```java
Function2<Integer, Integer, Option<Integer>> safeDivide = Function2.lift(divide);

// = None
Option<Integer> i1 = safeDivide.apply(1, 0); 

// = Some(2)
Option<Integer> i2 = safeDivide.apply(4, 2);
```
下面的函数sum是一个只接受整数的偏函数
```java
int sum(int first, int second) {
    if (first < 0 || second < 0) {
        throw new IllegalArgumentException("Only positive integers are allowed"); 
    }
    return first + second;
}
```
我们可以使用方法引用的方式提升为全函数
```java
Function2<Integer, Integer, Option<Integer>> sum = Function2.lift(this::sum);

// = None
Option<Integer> optionalResult = sum.apply(-1, 2);
```
### Partial application
局部计算可以让你从一个新的Function中派生出新的Function，这个是通过固定参数来实现的，你可以固定一个或者更多的参数，固定参数的数量定义了新函数的元组数，也就是`new arity=(original arity- fixed parameters)；参数的范围是从左向右的。
```java
Function2<Integer, Integer, Integer> sum = (a, b) -> a + b;
Function1<Integer, Integer> add2 = sum.apply(2); 

then(add2.apply(4)).isEqualTo(6);
```
下面的Function5的例子演示的更好一些
```java
Function5<Integer, Integer, Integer, Integer, Integer, Integer> sum = (a, b, c, d, e) -> a + b + c + d + e;
Function2<Integer, Integer, Integer> add6 = sum.apply(2, 3, 1); 

then(add6.apply(4, 3)).isEqualTo(13);
```
局部计算与Currying是不同的。
### 柯里化求值
柯里化求值就是固定一个参数的值来局部应用函数，比如一个Function1的函数柯里化后返回结果也是Function1。
当一个Function2被柯里化后，得到的结果与Function2被局部计算后的结果是一样的。因为得到的都是1-arity 函数。
```java
Function2<Integer, Integer, Integer> sum = (a, b) -> a + b;
Function1<Integer, Integer> add2 = sum.curried().apply(2); 

then(add2.apply(4)).isEqualTo(6);
```
你可能注意到了，除了使用到了.curried（）调用外，其他部分与局部计算是一样的，当函数的元组数大于2时，与局部计算的区别就出来了.
```java
Function3<Integer, Integer, Integer, Integer> sum = (a, b, c) -> a + b + c;
final Function1<Integer, Function1<Integer, Integer>> add2 = sum.curried().apply(2);

then(add2.apply(4).apply(3)).isEqualTo(9);
```
### 记忆表
记忆表可以理解为缓存，一个记忆函数只会执行一次，以后的调用直接返回结果，可以看下面的例子
```java
Function0<Double> hashCache =
        Function0.of(Math::random).memoized();

double randomValue1 = hashCache.apply();
double randomValue2 = hashCache.apply();

then(randomValue1).isEqualTo(randomValue2);
```
## Values
在函数式设置中，我们将值视为一种范式，一种无法进一步求值的表达式。 在 Java 中，我们通过将对象的状态设为 final 并将其称为不可变来表达这一点。
Vavr 的函数值抽象了不可变对象。 通过在实例之间共享不可变内存来添加高效的写入操作。 我们得到的是免费的线程安全！
### Option
是用来表达可选值的一元容器类型，Option的实例要么是Some的实例要么是None的实例。
```java
// optional *value*, no more nulls
Option<T> option = Option.of(...);
```
如果你用过java8的Optional类，它们之间存在一个非常大的不同点，对null值调用.map会返回的一个empty的optional,vavr的Option会返回一个Some(null)的Option实例。
```java
Optional<String> maybeFoo = Optional.of("foo"); 
then(maybeFoo.get()).isEqualTo("foo");
Optional<String> maybeFooBar = maybeFoo.map(s -> (String)null)  
                                       .map(s -> s.toUpperCase() + "bar");
then(maybeFooBar.isPresent()).isFalse();
```
使用Vavr的Option，上面的例子会抛出NullPointerException
```java
Option<String> maybeFoo = Option.of("foo"); 
then(maybeFoo.get()).isEqualTo("foo");
try {
    maybeFoo.map(s -> (String)null) 
            .map(s -> s.toUpperCase() + "bar"); 
    Assert.fail();
} catch (NullPointerException e) {
    // this is clearly not the correct approach
}
```
看起来Vavr的实现不是特别好，但是事实上并不是这样的——相反，它符合一元容器类型在调用 .map 时维护计算上下文的要求。 就选项而言，这意味着在 Some 上调用 .map 将导致 Some，而在 None 上调用 .map 将导致 None 。 在上面的 Java Optional 示例中，上下文从 Some 更改为 None。
看起来Option好像没什么用，但是它强制你关注可能出现的null值并处理它们而不是默默的接受，正确处理null值出现的方式就是使用flatMap。
```java
Option<String> maybeFoo = Option.of("foo"); 
then(maybeFoo.get()).isEqualTo("foo");
Option<String> maybeFooBar = maybeFoo.map(s -> (String)null) 
                                     .flatMap(s -> Option.of(s) 
                                                         .map(t -> t.toUpperCase() + "bar"));
then(maybeFooBar.isEmpty()).isTrue();
```
```java
Option<String> maybeFoo = Option.of("foo"); 
then(maybeFoo.get()).isEqualTo("foo");
Option<String> maybeFooBar = maybeFoo.flatMap(s -> Option.of((String)null)) 
                                     .map(s -> s.toUpperCase() + "bar");
then(maybeFooBar.isEmpty()).isTrue();
```
### Try
Try也是一个一元容器类型，用来表示计算单元可能会抛出异常，也有能返回成功值，有些类似Either，但是语法上是完全不同的，Try的实例要么是Success，要么是Failure。
```java
// no need to handle exceptions
Try.of(() -> bunchOfWork()).getOrElse(other);
```
```java
import static io.vavr.API.*;        // $, Case, Match
import static io.vavr.Predicates.*; // instanceOf

A result = Try.of(this::bunchOfWork)
    .recover(x -> Match(x).of(
        Case($(instanceOf(Exception_1.class)), t -> somethingWithException(t)),
        Case($(instanceOf(Exception_2.class)), t -> somethingWithException(t)),
        Case($(instanceOf(Exception_n.class)), t -> somethingWithException(t))
    ))
    .getOrElse(other);
```
### Lazy
Lazy是一个一元容器类型，表示一个延迟计算值，相比于Supplier，Lazy是记忆化的，只计算一次。
```java
Lazy<Double> lazy = Lazy.of(Math::random);
lazy.isEvaluated(); // = false
lazy.get();         // = 0.123 (random generated)
lazy.isEvaluated(); // = true
lazy.get();         // = 0.123 (memoized)
```
### Either
Either表示2个可能值之中的一个，一个Either要么是左面的值，要么是右面的值，要么表示两种可能类型的值。 一个要么是左要么是右。 如果给定的Either 是Right 并投影到Left，则Left 操作对Right 值没有影响。 如果给定的Either 是Left 并投影到Right，则Right 操作对Left 值没有影响。 如果将左投影到左或将右投影到右，则操作会产生效果。
下面的例子：一个compute()函数，Either要么返回Integer的类型，要么返回错误的message，按照惯例，成功的值是右值，失败的值是左值。
```java
Either<String,Integer> value = compute().right().map(i -> i * 2).toEither();
```
### Future
Future是一个在未来某个点可用的计算计算结果，所有的操作都是非阻塞的，隐含的executorService被用来执行异步的处理器，一个Future有2种状态，待定或者完成。
- 待定：计算在执行，只有待定状态的future可以完成或者取消；
- 完成：计算完成了或者失败了，或者被取消了。
Future上可以注册回调接口，这些回调只要Future完成了就会被调用，注册在已完成的Future上的回调会立即执行，回调可能在另外的线程执行，这取决于潜在的ExecutorService，注册在被取消的Future上的回调回执行错误的回调行为。
```java
// future *value*, result of an async calculation
Future<T> future = Future.of(...);
```
### Validation
Validation 控件是一个应用函子，可以把很多错误累积起来。 当尝试组合一元容器数据时，组合过程将在第一次遇到错误时短路。 但是“验证”将继续处理组合函数，累积所有错误。 这在验证多个字段时特别有用，比如 Web 表单，并且您想知道遇到的所有错误，而不是一次一个。 
下面的例子
```java
PersonValidator personValidator = new PersonValidator();

// Valid(Person(John Doe, 30))
Validation<Seq<String>, Person> valid = personValidator.validatePerson("John Doe", 30);

// Invalid(List(Name contains invalid characters: '!4?', Age must be greater than 0))
Validation<Seq<String>, Person> invalid = personValidator.validatePerson("John? Doe!4", -1);
```
有效的值包含在validation.Valid中，校验的errors包含在Validation.Invalid中，下面的例子是一个把不同的校验结果组合成一个Validation实例的例子
```java
class PersonValidator {

    private static final String VALID_NAME_CHARS = "[a-zA-Z ]";
    private static final int MIN_AGE = 0;

    public Validation<Seq<String>, Person> validatePerson(String name, int age) {
        return Validation.combine(validateName(name), validateAge(age)).ap(Person::new);
    }

    private Validation<String, String> validateName(String name) {
        return CharSeq.of(name).replaceAll(VALID_NAME_CHARS, "").transform(seq -> seq.isEmpty()
                ? Validation.valid(name)
                : Validation.invalid("Name contains invalid characters: '"
                + seq.distinct().sorted() + "'"));
    }

    private Validation<String, Integer> validateAge(int age) {
        return age < MIN_AGE
                ? Validation.invalid("Age must be at least " + MIN_AGE)
                : Validation.valid(age);
    }

}
```
如果验证成功，输入的数据是有效的，那么会创建一个Person的对象
```java
class Person {

    public final String name;
    public final int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public String toString() {
        return "Person(" + name + ", " + age + ")";
    }

}
```
## Collections
我们付出了很大的努力设计java下的符合函数式编程思想的集合库，其中最重要的特点就是不变性。Java的Stream在集合上添加了计算单元，Vavr中不需要这些模板代码。
新集合都实现了Iterable，所以都是可迭代的。
```java
// 1000 random numbers
for (double random : Stream.continually(Math::random).take(1000)) {
    ...
}
```
TraversableOnce接口含有大量的操作函数，它的API类似于java.util.stream.Stream但是更成熟。
### List
Vavr的List是一个LinkedList，所有的变更方法都会创建一个新的实例，大多数的操作都是线性时间的，连续的操作一个接着一个的执行。
```java
Arrays.asList(1, 2, 3).stream().reduce((i, j) -> i + j);
IntStream.of(1, 2, 3).sum();
```
```java
// io.vavr.collection.List
List.of(1, 2, 3).sum();
```
### stream
io.vavr.collection.Stream 是由Lazy Linked List实现的，值只有在需要的时候才计算，因为是懒加载的，大多数的操作都在常量事件内完成。
由于其惰性，大多数操作都是在恒定时间内执行的。 操作通常是中间的，并在单次通过中执行。流的惊人之处在于我们可以使用它们来表示（理论上）无限长的序列。
```java
// 2, 4, 6, ...
Stream.from(1).filter(i -> i % 2 == 0);
```
### 性能
下表是顺序操作的时间复杂度
||head()|tail()|get(int)|update(int,T)|prepend(T)|append(T)|
|:---|:---|:---|:---|:---|:---|:---|
|**Array**|const|linear|const|const|linear|linear|
|**CharSeq**|const|linear|const|linear|linear|linear|
|**Iterator**|const|const|-|-|-|-|
|**List**|const|const|linear|linear|const|linear|
|**Queue**|const|const^a^|linear|linear|const|const|
|**PriorityQueue**|const|const^a^|linear|linear|const|const|
|**Stream**|const|const|linear|linear|const^lazy^|const^lazy^|
|**Vector**|const^eff^|const^eff^|const^eff^|const^eff^|const^eff^|const^eff^|
Map/Set操作的时间复杂度
||contains/Key|add/put|remove|min|
|:---|:---|:---|:---|:---|
|**HashMap**|const^eff^|const^eff^|const^eff^|linear|
|**HashSet**|const^eff^|const^eff^|const^eff^|linear|
|**LinkedHashMap**|const^eff^|linear|linear|linear|
|**LinkedHashMap**|const^eff^|linear|linear|linear|
|**Tree**|log|log|long|log|
|**TreeMap**|log|log|log|log|
|**TreeSet**|log|log|log|log|
- const,代表常量时间
- const^a^,大部分是常量时间，少数的操作会时间比较长;
- const^eff^,平均常量时间，依赖hash key的分布;
- const^lazy^,
## 属性检查
属性检查是一个特别强大的功能，用于测试属性内的具体值，在单元测试中使用，io.vavr:vavr-test模块中包含了属性测试。
```java
Arbitrary<Integer> ints = Arbitrary.integer();

// square(int) >= 0: OK, passed 1000 tests.
Property.def("square(int) >= 0")
        .forAll(ints)
        .suchThat(i -> i * i >= 0)
        .check()
        .assertIsSatisfied();
```
## 模式匹配
Scala内置了模式匹配的功能，这是比java优势的一个地方，基本语法类似于java的switch
```scala
val s = i match {
  case 1 => "one"
  case 2 => "two"
  case _ => "?"
}
```
*match*是一个表达式，它得到一个结果。提供的内容有：
- 命名参数`case i: Int->"Int"+i`;
- 对象解包`case Some(i)->i`;
- 条件判断`case Some(i) if i > 0 -> "Positive"+i`;
- 条件组合`case "-h" | "--help" -> displayHelp`;
- 穷举的编译时间检查。
模式匹配是一个很重要的特性，可以避免写很多的if-then-else分支逻辑。
### Java中的基本的模式匹配
Vavr提供了类似Scala模式匹配的API`import static io.vavr.API.*;`,这个包包含了Match、Case与原子的模式匹配的一些相关的静态方法。
- $() 通配符模式
- $(value) 相等模式
- $(predicate) 条件模式
上面的scala的例子表示为Java的形式：
```java
String s = Match(i).of(
    Case($(1), "one"),
    Case($(2), "two"),
    Case($(), "?")
);
```
我们使用了大写的Case写法，是为了与java的case做区分。因为这个是关键字。
- Exhaustiveness，上面的例子中$()模式就是全部匹配，类似于switch中的default，因为如果没有任何项匹配，程序就会抛出一个MatchError类型的异常，使用$()就不会抛出这个异常了，因为我们不能执行Scala那样的详细的检查，所以我们可以选择返回可选值.
```java
Option<String> s = Match(i).option(
    Case($(0), "zero")
);
```
- 语法糖
就像上面演示的，Case可以匹配模式
```java
Case($(predicate), ...)
```
我们内置了很多的谓词对象可以进行条件判断
```java
import static io.vavr.Predicates.*;
```
上面的例子使用条件表达式的形式可以表示为：
```java
String s = Match(i).of(
    Case($(is(1)), "one"),
    Case($(is(2)), "two"),
    Case($(), "?")
);
```
如果有多个条件，可以表示为一种集合的形式
```java
Case($(isIn("-h", "--help")), ...)
```
- 执行的副作用
匹配的行为就像一个表达式，它产生一个值，为了执行一些额外的操作，我们需要一个返回void的帮助函数run来执行一些其他的处理操作。
```java
Match(arg).of(
    Case($(isIn("-h", "--help")), o -> run(this::displayHelp)),
    Case($(isIn("-v", "--version")), o -> run(this::displayVersion)),
    Case($(), o -> run(() -> {
        throw new IllegalArgumentException(arg);
    }))
);
```
使用了run函数，run必须是lambda的形式运行。run函数如果没有正确的使用，就回容易出错，我们正考虑在未来的版本中遗弃这个功能，并提供一些更好的API。
- 命名参数
Vavr借助lambda可以提供命名参数的功能，如下：
```java
Number plusOne = Match(obj).of(
    Case($(instanceOf(Integer.class)), i -> i + 1),
    Case($(instanceOf(Double.class)), d -> d + 1),
    Case($(), o -> { throw new NumberFormatException(); })
);
```
到目前为止，我们使用原子模式直接匹配值。 如果原子模式匹配，则从模式的上下文中推断出匹配对象的正确类型。下面我们会看下回溯模式的用法，可以执行深度匹配。
- 对象解构
在java中，我们使用构造函数来实例化类，我们认为，对象解构就是把对象分解为多个组合部分的过程。一个构造函数的作用是使用参数返回一个类的实例，一个惜构函数的作用是相反的，接收一个实例对象，返回对象的组成部分，我们说一个对象被unapplied。
对象析构并不一定是一个必须的操作，也可以通过其他的形式得到实例的组成部分。

### 模式
在Vavr中，我们使用模式定义一个特定类型的实例的如何分解，这样的惜构模式可以与Match API配合使用。
- 预定义的模式
很多内置的模式在包`import static io.vavr.Patterns.*;`中，例如，我们可以使用如下的Try的结果匹配
```java
Match(_try).of(
    Case($Success($()), value -> ...),
    Case($Failure($()), x -> ...)
);
```
如果没有适当的编译器支持，这是不切实际的，因为生成的方法的数量呈指数级增长。 当前的 API 做出了妥协，即所有模式都匹配，但只分解了根模式。
```java
Match(_try).of(
    Case($Success(Tuple2($("a"), $())), tuple2 -> ...),
    Case($Failure($(instanceOf(Error.class))), error -> ...)
);
```
这里的根模式就是Success与Failure，它们被析构成Tuple2与Error，拥有正确的范型。

- 用户自定义模式
```java
import io.vavr.match.annotation.*;

@Patterns
class My {

    @Unapply
    static <T> Tuple1<T> Optional(java.util.Optional<T> optional) {
        return Tuple.of(optional.orElse(null));
    }
}
```
