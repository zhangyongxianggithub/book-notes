[TOC]
# 第一章 引论
## 本书讨论的内容
一组$N$个数确定其中的第$k$个最大者，称为**选择问题**常见的解决方案
- 冒泡排序
- 使用$k$个元素的数组，遍历丢弃或者放入
- 前面2个在大元素的情况不能在合理的时间内返回，后面章节的算法可以

## 数学知识复习
1. 指数
   $$x^{a}x^{b}  = x^{a+b} $$
   $$\frac{x^{a}}{x^{b}}   = x^{a-b}  $$
   $$ (x^{a})^{b} = x^{ab}$$
   $$x^{N}+x^{N} =2x^{N}$$
   $$2^{N}+2^{N} =2^{N+1}$$
2. 对数
   $X^{A} = B$当且仅当$\log_{X}{B} =A$
   $$\log_{A}{B} = \frac{\log_{C}{B} }{\log_{C}{A} } , A,B,C> 0, A\ne 1$$
   **证明**: 令$X=\log_{C}{B},Y=\log_{C}{A},Z=\log_{A}{B}$.由对数的定义$C^{X} = B,C^{Y}=A,A^{Z}=B$联合这3个等式得$(C^{Y})^{Z}=C^{X}=B$，因此$X=YZ\to Z-X/Y$
   $$\log_{2}{AB}=\log_{2}{A}+\log_{2}{B}$$
   **证明**: 令$X=\log_{2}{B},Y=\log_{2}{A},Z=\log_{2}{AB}$.由对数的定义$2^{X} = A,2^{Y}=B,2^{Z}=AB$联合这3个等式得$2^{X}2^{Y}=2^{Z}=AB$，因此$X+Y=Z$
   其他有用的公示:
   $$\log_{2}{A/B}=\log_{2}{A}-\log_{2}{B}$$
   $$\log_{2}{A^B}=B\log_{2}{A}$$
   $$\log_{2}{X}< X对所有的X> 0 成立$$
   $$\log_{2}{1}=0,\log_{2}{2}=1,\log_{2}{1024}=10,\log_{2}{1048576}=20$$
3. 级数
   $$\sum_{i=0}^{N} 2^i=2^{N+1}-1$$
   $$\sum_{i=0}^{N} A^i=\frac{A^{N+1}-1}{A-1} $$
   若$0<A<1$，则
   $$\sum_{i=0}^{N} A^i\le \frac{1}{A-1} $$
4. 模运算
5. 证明的方法
   - 归纳法，有2个标准的部分
     - 证明基准情形(base case)，就是证明定理对于某个小的值的正确性
     - 归纳假设(inductive hypothesis)，一般来说，它指的是假设定理对直到某个有限数$k$的所有情况都是成立的。然后使用这个假设证明定理对下一个值$k+1$也是成立的，定理得证。
     一个公式
     $$如果N\ge 1,则\sum_{i=1}^{N} i^2=\frac{N(N+1)(2N+1)}{6} $$
   - 反证法，反证法证明是通过假设定理不成立，然后证明该假设导致某个已知的性质不成立，从而原假设是错误的。
## 递归简论
当一个函数用它自己来定义时就称为递归(recursive)的，比如$f(0)=0且f(x)=2f(x-1)+x^{2}$.Java允许函数是递归的。递归不是循环推理(circular logic)。虽然我们定义一个方法用的是这个方法本身。但是并没有用方法本身定义该方法的一个特定的实例。例子就是通过使用$f(5)$来得到$f(5)$的值才是循环的。通过$f(4)$得到$f(5)$的值不是循环的，除非$f(4)$的求值又要用到对$f(5)$的计算。递归的2个基本法则:
- 基准情形(base case): 必须重要有某些基准的情形，它们不用递归就你能求解
- 不断推进(making progress): 对于那些要递归求解的情形，递归调用必须总能够朝着一个基准情形推进

递归的4条基本法则
- 基准情形(base case): 必须重要有某些基准的情形，它们不用递归就你能求解
- 不断推进(making progress): 对于那些要递归求解的情形，递归调用必须总能够朝着一个基准情形推进
- 设计法则，假设所有的递归调用都能运行，就是没必要追踪递归调用的每一个递归过程，因为有很多
- 合成效益法则，不要做重复性的工作

## 实现泛型构件pre-Java 5
泛型就是为了代码重用。不同类型的实现方法相同就可以用泛型机制。
- 使用Object表示泛型，一个问题是使用时需要强制转化为特定的类型，否则无法使用，还有一个就是无法表示基本类型
- 使用接口类型表示泛型
## 利用Java5泛型特性实现泛型构件
- 简单的泛型类与接口，只需要在菱形内声明类型参数，类型参数可以用于类内的域、方法的参数与返回值类型。使用泛型使以前只有在运行时才能报告的错误变成了编译时的错误
- 自动装箱，编译器将通过Integer构造函数构造出Integer对象，自动拆箱，直接调用Integer的`intValue()`方法来得到int值
- 菱形运算符
- 泛型数组是协变的，也就是Square IS-A Shape，Square[] IS-A Shape[]，但是Collection\<Square> IS-NOT-A Collection\<Shape>，传递参数的时候会产生编译错误，Java使用通配符来解决这个问题。通配符来表示参数类型的子类或者超类，? extends Type，单独使用时表示 extends Object
- 泛型static方法需要在返回值前声明类型参数
- 类型限界` public static <AnyType> AnyType findMax(AnyType[] arr)`，类型限界可以在编译期就可以调用`compareTo()`方法而不用等到运行期再去判断，`public static <AnyType extends Comparable<AnyType>> AnyType findMax(nyType[] arr)`，`public static <AnyType extends Comparable<? super AnyType>> AnyType findMax(AnyType[] arr)`，假设Shape实现Comparable<Shape>，Square继承Shape，此时Square实现了Comparable<Shape>但是没实现Comparable<Square>，于是Shape IS-A Comparable<Shape>但是它 IS-NOT-A Comparable<Square>，所以应该声明AnyType IS-A Comparable<T>，T是AnyType的父类。
- 类型擦除到类型限界，成为原始类，这是编译期干的
- static域不能使用泛型因为类型擦除后，类型参数不存在，instanceof只针对原始类型进行，不能通过`new T()`的方式构造泛型对象，因为擦除后可能是一个接口；泛型数组也不能创建；

## 函数对象
没有数据只有一个方法的类的对象
## 小结
算法在大量输入情况下花费的时间是重要的评价标准。
## 练习
1. 
# 第二章 算法分析
算法是求解一个问题的指令集合。
## 数学基础
4个定义:
>如果存在正常数$c$与$n_{0}$，使得当$N \ge n_{0}$时，$T(N) \le cf(N)$，则记为$T(N)=O(f(N))$,意思就是$T(N)$的增长率小于等于$f(N)$的增长率

>如果存在正常数$c$与$n_{0}$，使得当$N \ge n_{0}$时，$T(N) \ge cg(N)$，则记为$T(N)= \Omega (g(N))$，意思就是$T(N)$的增长率大于等于$g(N)$的增长率

>$T(N)= \Theta  (h(N))$当且仅当$T(N)=O(h(N))$以及$T(N)= \Omega (h(N))$，意思就是$T(N)$的增长率等于$h(N)$的增长率

>如果对每一正常数$c$都存在常数$n_{0}$使得当$N >n_{0}$时$T(N)<cp(N)$，则$T(N)=o(p(N))$，也可以说$T(N)=O(p(N))$且$T(N) \ne \Theta (p(N))$,则$T(N)=o(p(N))$，意思就是$T(N)$的增长率小于$p(N)$的增长率

重要的结论
>**法则1**: 如果$T_{1}(N)=O(f(N))$且$T_{2}(N)=O(g(N))$，那么$T_{1}(N)+T_{2}(N)=O(f(N)+g(N))$且$T_{1}(N)\times T_{2}(N)=O(f(N)\times g(N))$

>**法则2**: 如果$T(N)$是一个$k$次多项式，则$T(N)=\theta(N^k)$

>**法则3**: 对任意常数$k$，$\log_{k}{N} =O(N)$，对数增长的很慢

## 模型
## 要分析的问题
要分析的最重要的资源就是运行时间，收到算法本身与输入规模的影响
## 运行时间计算
计算任何事情不要超过一次。
最大子序列和问题的求解
最开始的算法，穷举的区间算法，每次都是一个区间来计算。算法的时间复杂度是$O(N^{3})$
```java
    public static int maxSubSum1(final int[] a) {
        int maxSum = 0;
        for (int i = 0; i < a.length; i++) {
            for (int j = i; j < a.length; j++) {
                int thisSum = 0;
                for (int k = i; k <= j; k++) {
                    thisSum += a[k];
                }
                if (thisSum > maxSum) {
                    maxSum = thisSum;
                }
            }
        }
        return maxSum;
    }
```
一种改进的算法，通过使用历史结果方式降低了复杂度，$O(N^2)$
```java
    public static int maxSubSum2(final int[] a) {
        int maxSum = 0;
        for (int i = 0; i < a.length; i++) {
            int thisSum = 0;
            for (int j = i; j < a.length; j++) {
                thisSum += a[j];
                if (thisSum > maxSum) {
                    maxSum = thisSum;
                }
            }
        }
        return maxSum;
    }
```
一种$O(log_{2}{N}\times N)$复杂度的算法如下，使用了二叉树或者说折半算法的思想，分解问题，也可以说是分治法的思想:
```java
    public static int maxSubSum3(final int[] a) {
        return maxSubSum3Rec(a, 0, a.length - 1);
    }
    
    public static int maxSubSum3Rec(final int[] a, final int left,
            final int right) {
        if (left == right) {
            if (a[left] > 0) {
                return a[left];
            }
            return 0;
        }
        final int center = (left + right) / 2;
        final int maxLeftSum = maxSubSum3Rec(a, left, center);
        final int maxRightSum = maxSubSum3Rec(a, center + 1, right);
        int maxLeftBorderSum = 0, leftBorderSum = 0;
        for (int i = center; i >= left; i--) {
            leftBorderSum += a[i];
            if (leftBorderSum > maxLeftBorderSum) {
                maxLeftBorderSum = leftBorderSum;
            }
        }
        int maxRightBorderSum = 0, rightBorderSum = 0;
        for (int i = center + 1; i <= right; i++) {
            rightBorderSum += a[i];
            if (rightBorderSum > maxRightBorderSum) {
                maxRightBorderSum = rightBorderSum;
            }
        }
        return Math.max(Math.max(maxLeftSum, maxRightSum),
                maxLeftBorderSum + maxRightBorderSum);
    }
```
更好的算法$O(N)$，只扫描一次数据，不需要记以前的数据，在任意时刻，算法都能对已经读入的数据给出子序列问题的正确答案，具有这种特性的算法叫做联机算法:
```java
    public static int maxSubSum4(final int[] a) {
        int maxSum = 0, thisSum = 0;
        for (int i : a) {
            thisSum += i;
            if (thisSum > maxSum) {
                maxSum = thisSum;
            } else if (thisSum < 0) {
                thisSum = 0;
            }
        }
        return maxSum;
    }
```
具有对数特点的3个例子
- 折半查找
- 欧几里得算法
- 幂运算
# 第三章 表、栈与队列
## 抽象数据类型
abstract data type(ADT)是带有一组操作的一些对象的集合。抽象是数学上的抽象。
## 表ADT
表就是一序列位置有序的元素。可以有增删改查的操作。有2种实现方案
- 数组实现，方便查询不方便插入删除等操作
- 链表实现，双向链表，方便插入删除不方便查询

## Java Collections API中的表
`java.util.Collection`接口是表的概念。实现`Iterable`的所有类支持增强的for循环。实现`Iterable`的所有类都会实现一个`iterator()`返回一个实现了`Iterator`接口的对象，可以迭代处理集合中的元素或者移除元素。对迭代器做结构上的改变不要使用迭代器。
List接口实现了表，继承了`Coolection`接口并添加了一些额外的基于位置的操作方法，分为2种实现:
- ArrayList: 可增长数组的实现方式
- LinkedList: 双链表实现方式

## ArrayList类的实现
```java
public class MyArrayList<AnyType> implements List<AnyType> {
    
    private static final int DEFAULT_CAPACITY = 10;
    
    private int theSize;
    
    private AnyType[] theItems;
    
    public MyArrayList() {
        doClear();
    }
    
    private void doClear() {
        theSize = 0;
        ensureCapacity(DEFAULT_CAPACITY);
    }
    
    private void ensureCapacity(final int newCapacity) {
        if (newCapacity < theSize) {
            return;
        }
        final AnyType[] old = theItems;
        theItems = (AnyType[]) new Object[newCapacity];
        for (int i = 0; i < size(); i++) {
            theItems[i] = old[i];
        }
    }
    
    @Override
    public int size() {
        return theSize;
    }
    
    @Override
    public boolean isEmpty() {
        return size() == 0;
    }
    
    @Override
    public boolean contains(final Object o) {
        return false;
    }
    
    @Override
    public Iterator<AnyType> iterator() {
        return new ArrayListIterator();
    }
    
    private class ArrayListIterator implements Iterator<AnyType> {
        
        private int current = 0;
        
        @Override
        public boolean hasNext() {
            return current < size();
        }
        
        @Override
        public AnyType next() {
            return theItems[current++];
        }
        
        @Override
        public void remove() {
            MyArrayList.this.remove(--current);
        }
    }
    
    @Override
    public Object[] toArray() {
        return new Object[0];
    }
    
    @Override
    public <T> T[] toArray(final T[] a) {
        return null;
    }
    
    @Override
    public boolean add(final AnyType anyType) {
        add(size(), anyType);
        return true;
    }
    
    @Override
    public boolean remove(final Object o) {
        return false;
    }
    
    @Override
    public boolean containsAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public boolean addAll(final Collection<? extends AnyType> c) {
        return false;
    }
    
    @Override
    public boolean addAll(final int index,
            final Collection<? extends AnyType> c) {
        return false;
    }
    
    @Override
    public boolean removeAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public boolean retainAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public void clear() {
        doClear();
    }
    
    @Override
    public AnyType get(final int index) {
        if (index < 0 || index >= size()) {
            throw new ArrayIndexOutOfBoundsException();
        }
        return theItems[index];
    }
    
    @Override
    public AnyType set(final int index, final AnyType element) {
        if (index < 0 || index >= size()) {
            throw new ArrayIndexOutOfBoundsException();
        }
        final AnyType old = theItems[index];
        theItems[index] = element;
        return old;
    }
    
    @Override
    public void add(final int index, final AnyType element) {
        if (theItems.length == size()) {
            ensureCapacity(size() * 2 + 1);
        }
        for (int i = theSize; i > index; i--) {
            theItems[i] = theItems[i - 1];
        }
        theItems[index] = element;
        theSize++;
    }
    
    @Override
    public AnyType remove(final int index) {
        final AnyType removedItem = theItems[index];
        for (int i = index; i < size() - 1; i++) {
            theItems[index] = theItems[i + 1];
        }
        theSize--;
        return removedItem;
    }
    
    @Override
    public int indexOf(final Object o) {
        return 0;
    }
    @Override
    public int lastIndexOf(final Object o) {
        return 0;
    }
    @Override
    public ListIterator<AnyType> listIterator() {
        return null;
    }
    @Override
    public ListIterator<AnyType> listIterator(final int index) {
        return null;
    }

    @Override
    public List<AnyType> subList(final int fromIndex, final int toIndex) {
        return null;
    }
}
```
## LinkedList类的实现
`LinkedList`作为双链表来实现。
```java
public class MyLinkedList<AnyType> implements List<AnyType> {
    private static class Node<AnyType> {
        
        public AnyType data;
        public Node<AnyType> prev;
        public Node<AnyType> next;
        
        public Node(final AnyType data, final Node<AnyType> prev,
                final Node<AnyType> next) {
            this.data = data;
            this.prev = prev;
            this.next = next;
        }
    }
    
    private int theSize;
    private int modCount;
    private Node<AnyType> beginMarker;
    private Node<AnyType> endMarker;
    
    @Override
    public int size() {
        return theSize;
    }
    
    @Override
    public boolean isEmpty() {
        return size() == 0;
    }
    
    @Override
    public boolean contains(final Object o) {
        return false;
    }
    
    @Override
    public Iterator<AnyType> iterator() {
        return null;
    }
    
    @Override
    public Object[] toArray() {
        return new Object[0];
    }
    
    @Override
    public <T> T[] toArray(final T[] a) {
        return null;
    }
    
    @Override
    public boolean add(final AnyType anyType) {
        add(size(), anyType);
        return true;
    }
    
    @Override
    public boolean remove(final Object o) {
        return false;
    }
    
    @Override
    public boolean containsAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public boolean addAll(final Collection<? extends AnyType> c) {
        return false;
    }
    
    @Override
    public boolean addAll(final int index,
            final Collection<? extends AnyType> c) {
        return false;
    }
    
    @Override
    public boolean removeAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public boolean retainAll(final Collection<?> c) {
        return false;
    }
    
    @Override
    public void clear() {
        doClear();
    }
    
    @Override
    public AnyType get(final int index) {
        return getNode(index).data;
    }
    
    @Override
    public AnyType set(final int index, final AnyType element) {
        final Node<AnyType> node = getNode(index, 0, size());
        final AnyType oldValue = node.data;
        node.data = element;
        return oldValue;
    }
    
    @Override
    public void add(final int index, final AnyType element) {
        addBefore(getNode(index, 0, size()), element);
    }
    
    @Override
    public AnyType remove(final int index) {
        return remove(getNode(index));
    }
    
    @Override
    public int indexOf(final Object o) {
        return 0;
    }
    
    @Override
    public int lastIndexOf(final Object o) {
        return 0;
    }
    
    @Override
    public ListIterator<AnyType> listIterator() {
        return null;
    }
    
    @Override
    public ListIterator<AnyType> listIterator(final int index) {
        return null;
    }
    
    @Override
    public List<AnyType> subList(final int fromIndex, final int toIndex) {
        return null;
    }
    
    private void doClear() {
        beginMarker = new Node<>(null, null, null);
        endMarker = new Node<>(null, beginMarker, null);
        beginMarker.next = endMarker;
        theSize = 0;
        modCount++;
    }
    
    private void addBefore(final Node<AnyType> p, final AnyType x) {
        final Node<AnyType> newNode = new Node<>(x, p.prev, p);
        newNode.prev.next = newNode;
        p.prev = newNode;
        theSize++;
        modCount++;
    }
    
    private Node<AnyType> getNode(final int idx) {
        return getNode(idx, 0, size() - 1);
    }
    
    private Node<AnyType> getNode(final int idx, final int lower,
            final int upper) {
        Node<AnyType> p;
        if (idx < size() / 2) {
            p = beginMarker;
            for (int i = 0; i <= idx; i++) {
                p = p.next;
            }
        } else {
            p = endMarker;
            for (int i = size(); i > idx; i--) {
                p = p.prev;
            }
        }
        return p;
    }
    
    private AnyType remove(final Node<AnyType> p) {
        p.prev.next = p.next;
        p.next.prev = p.prev;
        return p.data;
    }
}
```
## 栈ADT
栈模型: 限制插入与删除只能在一个位置上进行的表，这个位置叫做栈的top。基本操作有入栈与出栈。也叫做LIFO表，只有栈顶是可以访问的。任何实现表的方法都能是实现栈，所以有2种实现方式:
- 栈的链表实现，操作都在头节点
- 栈的数组实现，增加一个移动的位置标记

栈是在计算机科学中在数组之后的最基本的数据结构因为在现代计算机中，栈操作已经成为了指令集。栈的3种应用
- 平衡符号，就是判断文本的括号是否成对的程序。算法的基本思路是: 做一个空栈，读入字符直到文件结尾。如果字符是一个开放符号，则将其推入栈中，如果字符是一个封闭符号，则当栈空时报错否则将栈元素弹出判断是不是封闭符号对应的开放字符，如果不是报错。读完所有字符后，栈非空报错。
- 后缀表达式，四则元素的后缀表示法就是运算符后置，带有运算的优先级信息。也叫做逆波兰式。使用栈的来计算就是遇到数入栈，遇到符号弹出2个数计算结果后入栈，最后栈中的元素就是表达式的结果。
- 中缀到后缀的转换，具体的计算法则是: 做一个空栈，遇到操作数输出，遇到运算符与左括号放入栈中，遇到右括号，将栈元素弹出到输出，直到遇到左括号，左括号不输出。接下来如果见到任何其他的操作符比如(,+,*。从栈中弹出元素，直到遇到优先级更低的操作符。左括号只能在遇到右括号的时候弹出。最后欧弹出所有的栈元素。其实就是一个计算右表达式的过程。左括号在输入时是最高优先级的操作符，在栈中时是最低优先级的操作符。
- 方法调用，方法调用时，主调方法的寄存器与返回地址等上下文信息存在一个栈中，控制转移到被调方法。执行完从栈顶复原。所存储的信息叫做活动记录(activation record)或者叫做栈帧(stack frame)。通常，栈顶就是当前运行的方法。栈空间有大小限制。尾递归就是最后一行的递归调用。尾递归可以被转换为迭代。递归总是可以被去除，编译期也会这么优化。
## 队列ADT
队列也是表，队列在一端插入在一端删除。队列的基本操作时入队与出队。队列是可以使用表实现的，链表或者数组实现都可以，都是$O(1)$的运行时间。数组的实现要使用循环数组。
# 第四章 树
二叉查找树(bianry search tree)，是`TreeSet`与`TreeMap`的实现基础。树在计算机科学中是非常有用的抽象概念。
## 预备知识
树的递归定义方式，一棵树是一些节点的集合，这个集合可以是空集，若不是空集，则树由称作根(root)的节点`r`以及0个或者多个非空的子树$T_{1},T_{2}, \dots ,T_{k}$组成，子树的的根都被来自$r$的有向边连结。树由$N$个节点与$N-1$条边构成。从节点$n_1$到$n_k$的路径定义为节点$n_1,n_2,\dots ,n_k$的一个序列，使得对于$1\le i\le k$，节点$n_i$是节点$n_{i+1}$的父亲，路径的长是路径的边数。一颗树丛根节点到每个节点恰好存在一条路径。$n_i$的深度为从根到$n_i$的路径的长，$n_i$的高度为$n_i$到一片树叶的最长路径的长。树的深度=树的高度。实现树的数据结构，通常是在节点内维持指向子节点的链，但是子节点数量是变化的，不好维护，解决的方法是将所有的兄弟节点放到一个链表中，父节点只需维护到第一个子节点的链就可以了，结构如下:
```java
public class TreeNode<T> {
    private T element; 
    private TreeNode<T> firstChild;
    private TreeNode<T> nextSibling;
    public TreeNode(final T element, final TreeNode<T> firstChild,
            final TreeNode<T> nextSibling) {
        this.element = element;
        this.firstChild = firstChild;
        this.nextSibling = nextSibling;
    }
    public void setElement(final T element) {
        this.element = element;
    }
    public void setFirstChild(final TreeNode<T> firstChild) {
        this.firstChild = firstChild;
    }
    public void setNextSibling(final TreeNode<T> nextSibling) {
        this.nextSibling = nextSibling;
    }
    public T getElement() {
        return element;
    }
    public TreeNode<T> getFirstChild() {
        return firstChild;
    }
    public TreeNode<T> getNextSibling() {
        return nextSibling;
    }
}
```
树的应用-文件系统的目录，树由前中后3种遍历方法
- 前序preorder，对节点的处理工作在所有儿子节点处理之前完成，层次感比较好，节点的计算与子节点无关时用前序。
- 中序，左子树处理完处理处理节点，然后右子树
- 后序postorder，对节点的处理工作在所有儿子节点处理之后完成，需要所有子节点的数据的时候，用后序
## 二叉树
二叉树是一棵树，每个节点不能多于2个儿子。二叉树的节点类实现
```java
public class BinaryNode<T> {
    private T element;
    
    private BinaryNode<T> left;
    
    private BinaryNode<T> right;
    
    public BinaryNode(final T element, final BinaryNode<T> left,
            final BinaryNode<T> right) {
        this.element = element;
        this.left = left;
        this.right = right;
    }
    
    public T getElement() {
        return element;
    }
    
    public void setElement(final T element) {
        this.element = element;
    }
    
    public BinaryNode<T> getLeft() {
        return left;
    }
    
    public void setLeft(final BinaryNode<T> left) {
        this.left = left;
    }
    
    public BinaryNode<T> getRight() {
        return right;
    }
    
    public void setRight(final BinaryNode<T> right) {
        this.right = right;
    }
}
```
二叉树的主要用在编译器的设计领域。
- 表达式树: 树叶是操作数，其他节点是操作符。
## 查找树ADT: 二叉查找树
二叉查找树的特点: 对于任意的节点$X$，它的左子树都小于$X$，右子树中的节点都大于$X$。如果输入预先排好序的数据，二叉查找树变成了有序链表，一个解决办法就是做树的平衡操作。AVL树就是一种平衡查找树。
# 第10章 算法设计技巧
本章讨论用于求解问题的5种通常类型的算法，对于很对问题，这些方法中至少有一种是可以解决问题的。
## 贪婪算法
greedy algorithm，Dijkstra算法、Prim算法、Kruskal算法都是贪婪算法，贪婪算法分阶段的工作，每一个阶段都做最好的决定而不考虑整体，局部最优=全局最优，那么算法就是正确的，否则算法会得到一个次最优解，如果不要求绝对最佳答案，那么贪婪算法需要的计算可能比计算准确答案要简单很多。贪婪算法的例子比如钱币找零问题。
1. 一个简单的调度问题
有作业$j_1,j_2,...,j_N$，已知对应的运行时间分别是$t_1,t_2,...,t_N$，处理器只有一个，求作业平均完成时间的最小化，事实证明作业是按照最短作业最先进行，平均时间最小，证明如下,第一个作业以$t_1$时间完成，第二个作业以$t_1+t_2$时间完成，第三个作业以$t_1+t_2+t_3$时间完成，得到总的时间$C$如下:
$$ C=\sum ^{N}_{k=1} \left ( {N-k+1} \right ){t}_{k} $$
拆分公式得到
$$ C=\left ( {N+1} \right )\sum ^{N}_{k=1} {{t}_{k}}-\sum ^{N}_{k=1} {k}\cdot {t}_{k} $$
第一个和与作业的排序无关，只有第二个影响到总开销，第二个越大，则总开销越小，假如存在$x>y$使得$t_x<t_y$，
经过计算此时交换$t_x$与$t_y$第二个和增加，从而降低总开销，因此，所用时间不是单调非减的任何的作业调度都是次最优的，这个结果指出操作系统调度程序一般把优先权赋予那些更短作业的原因。
1. 哈夫曼编码
贪婪算法的第二个应用文件压缩，ASCII字符集包含100个左右的字符，所以需要至少需要$⌈log 100⌉=7$个bit，第8个bit作为奇偶校验位，如果字符集的大小是$C$那么标准的编码中就需要$⌈log C⌉$个bit，假设一个文件的字符信息如下:

|字符|编码|频率|bit数|
|:---|:---|:---|:---|
|a|000|10|30|
|e|001|15|45|
|i|010|12|36|
|s|011|3|9|
|t|100|4|12|
|空格|101|13|39|
|newline|110|1|3|

这个文件需要174个bit来表示，网络传输与磁盘存储需要更少的bit数，而不同的字符的出现频率是不同的，根绝这个特点，只要保证常出现的字符的bit短就能有效的减少总的传输量，
字符的二进制代码可以用二叉树表示0表示左分支，1表示右分支，如下图所示
![字符二叉树](adtjava/trie-%E7%AC%AC%201%20%E9%A1%B5.drawio.png)
现在就是要减少到每个叶节点的路径长度，比如nl字符它是仅有的儿子，可以放到上一层，减少一层
![字符二叉树](adtjava/trie-%E7%AC%AC%202%20%E9%A1%B5.drawio.png)
这是一颗满树，最优的编码总是满树，要不是叶节点，要不具有2个儿子，具有一个儿子的可以向上移动一层。
只要字符都在叶节点上，那么就可以正常的译码，如果放在非叶节点上，那么字符的前缀可能会是别的字符，存在二义性，只要字符代码不是别的字符代码的前缀，那么字符编码的长度无关紧要，这样的编码就做前缀码。构造前缀码的一个算法就是哈夫曼编码，算法的过程如下:
设字符的个数位$C$，算法的数据是由多个树组成的森林，初始为$C$颗单节点树，每个字符一颗，初始的树的权就是字符频率，任意选取最小权的2颗树，$T_1$与$T_2$组成新的树，新的树的权等于2个子树的权的和，重复步骤$C-1$次，算法结束时得到一颗树，这棵树就是最优哈夫曼编码树。
在压缩文件的开头要传送编码信息，否则不可能译码。
2. 近似装箱问题
装箱问题可以产生距离最优解不远的解。设有$N$个箱子，大小分别为$s_1,s_2,...,s_N$，每个都满足$0<s_i<1$，把他们装到容量为1大箱子中去，求一种使用箱子最少的办法。有2种版本的装箱问题。

- 联机装箱问题，on-line bin packing problem，每一个物品必须放入一个箱子后才能处理下一个物品;
- 脱机装箱问题，off-line bin packing problem, 做任何事都需要把所有的输入数据全部读取完后才进行;
1. 联机算法
联机算法并不能总给出最优解，考虑权为$ \frac {1} {2}-\varepsilon$的$M$个小项与权为$ \frac {1} {2}+\varepsilon$的$M$个大项构成的序列$I_1$，其中$0<\varepsilon<1$，如果每个箱子中放一个小项与一个大项，那么可以放入到$M$个箱子中去，假设存在一个最优的联机装箱算法$A$，考虑对序列$I_2$操作，该序列只有$ \frac {1} {2}-\varepsilon$的$M$个小项组成，$I_2$是可以装入到$ \lceil M/2\rceil  $个箱子中去，不知道这个在讲什么？fuck。
> 定理10.1: 存在使得任意联机装箱算法至少使用$ \frac {4} {3}$最优箱子数的输入

- 下项适合算法（next fit），当处理任何一件物品时，检查它是否还能装进刚刚装进物品的同一个箱子中去，如果可以就放进去，不行就开辟新的箱子
> 定理10.2: 令$M$是将一列物品$I$装箱所需的最优装箱数，则下项适合算法所有箱子数绝不超过$2M$个箱子，存在一些顺序使得下项适合算法用箱子数达到$2M-2$个

- 首次适合算法(first fit)，依次扫描箱子，并把新的物品放入碰到的第一个能够放入它的箱子，如果没有则开辟新的箱子
> 定理10.3: 令$M$是将一列物品$I$装箱所需的最优装箱数，则首次适合算法所有箱子数绝不超过$\lceil \frac {17} {10}M \rceil$个箱子，存在一些顺序使得首次适合算法用箱子数达到$\lceil \frac {17} {10}(M-1) \rceil$个

- 最佳适合算法(best fit)，一个新的物品找到能放入它的最满的箱子中去，也就是剩余空间最小的那个箱子中去，
2. 脱机算法
首次适合非增算法，前提是物品按照权重已经排序。

## 分治算法
分治算法由2部分组成
- 分(divide): 递归解决较小的问题
- 治(conquer): 从子问题的解构建原问题的解.
至少含有2个递归调用的例程叫做分治算法，只含有一个的不是分治算法(也就是子问题只有一种的不算是分治法)只是简单的递归调用，子问题不相交。
1. 分支算法的运行时间
分支算法将问题分解为一些子问题，每个子问题都是原问题的一部分，然后进行某些附加的工作算出最后的答案。最经典的例子就是归并排序，每个子问题都是原问题大小的一半，然后执行$O(N)$的附加工作。归并排序的运行时间$$T(N)=2T(N/2)+O(N)$$该方程的解为$O(N logN)$.


