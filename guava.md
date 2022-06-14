# Collections
## Immutable Collections
例子:
```java
public static final ImmutableSet<String> COLOR_NAMES = ImmutableSet.of(
  "red",
  "orange",
  "yellow",
  "green",
  "blue",
  "purple");

class Foo {
  final ImmutableSet<Bar> bars;
  Foo(Set<Bar> bars) {
    this.bars = ImmutableSet.copyOf(bars); // defensive copy!
  }
}
```
### why?
不可变对象有很多优势，包括:
- 可以安全的用于不受信任的库;
- 线程安全: 可以被多线程使用，没有竞态条件;
- 不需要支持变更操作，节省了时间与空间，所有的不可变更的集合实现比可变更的版本的内存效率更高;
- 可以作为一个常量使用，只要是保持不变的变量都可以使用不可变集合.
使用对象的不可变拷贝是一个好的防故障编程技术。Guava为每一个标准的Collection类型都提供了简单的、易于使用的不可变集合版本，包括Guava自己的Collection变体。JDK提供了Collections.unmodifiableXXX方法来返回不可变集合，但是在我们看来，这种实现存在以下的问题:
- 绷着且冗长: 在你想制作防御性副本的任何地方使用都不方便;
- 不安全: 只有在没有人持有对原始集合的引用时，返回的集合才是真正不可变的;
- 低效: 数据结构仍然具有可变集合的所有开销，包括并发修改检查、哈希表中的额外空间等;
当您不希望修改集合或希望集合保持不变时，最好将其防御性地复制到不可变集合中.
重要提示: Guava的所有的不可变集合都不允许null值 我们对 Google 的内部代码库进行了详尽的研究，结果表明集合生命周期中的5%时间中允许空元素，而其他95%的情况都是通过在null上快速失败来解决。如果您需要使用null值，请考虑在允许null的集合使用Collections.unmodifiableXXX得到不可变集合。更详细的建议可以在这里找到。
### How?
一个`ImmutableXXX`集合可以通过下面的几种方式创建:
- 使用copyOf静态方法，比如`ImmutableSet.copyOf(set)`;
- 使用of静态方法，比如`ImmutableSet.of("a", "b", "c")`与`ImmutableMap.of("a", 1, "b", 2)`;
- 使用Builder, 比如:
```java
public static final ImmutableSet<Color> GOOGLE_COLORS =
   ImmutableSet.<Color>builder()
       .addAll(WEBSAFE_COLORS)
       .add(new Color(0, 191, 255))
       .build();
```
除了排序集合，元素迭代的顺序是构建的顺序。copyOf方法比你想的更智能。当不需要拷贝数据的时候，ImmutableXXX.copyOf会尝试不拷贝数据，具体的细节未指定，但是内部实现是很智能的，比如:
```java
ImmutableSet<String> foobar = ImmutableSet.of("foo", "bar", "baz");
thingamajig(foobar);

void thingamajig(Collection<String> collection) {
   ImmutableList<String> defensiveCopy = ImmutableList.copyOf(collection);
   ...
}
```
在这段代码中，ImmutableList.copyOf(foobar)足够智能只返回 foobar.asList()，ImmutableSet返回list视图只需要花费常量时间。作为一般的启发式方法，ImmutableXXX.copyOf(ImmutableCollection)会试图避免线性拷贝，需要的条件是:
- 是否可以直接使用底层数据结构，比如ImmutableSet.copyOf(ImmutableList)就不行，需要经过处理;
- 不会造成内存泄漏，比如，如果你有一个集合`ImmutableList<String> hugeList`，并且做了如下操作`ImmutableList.copyOf(hugeList.subList(0, 10))`，此时会执行显式复制，以避免意外持有不在hugeList中的引用;
- 不会改变语义，因此 ImmutableSet.copyOf(myImmutableSortedSet) 将执行显式复制，因为 ImmutableSet 使用的 hashCode() 和 equals 与 ImmutableSortedSet 基于比较器的行为具有不同的语义。
这些都会帮助提升性能。所有的不可变几何都提供了asList()方法会得到ImmutableList视图，所以，如果你有一个`ImmutableSortedSet`，通过`sortedSet.asList().get(k)`你可以得到第k个最小的元素。返回的 ImmutableList 经常——不总是，但经常——一个常量开销视图，而不是显式副本。 也就是说，它通常比普通的 List 更聪明——例如，它将使用支持集合的有效 contains 方法。集合对应关系.

|interface|jdk or Guava|Immutable Version|
|:---|:---|:---|
|Collection|JDK|ImmutableCollection|
|List|JDK|ImmutableList|
|Set|JDK|ImmutableSet|
|SortedSet/NavigableSet|JDK|ImmutableSortedSet|
|Map|JDK|ImmutableMap|
|SortedMap|JDK|ImmutableSortedMap|
|Multiset|Guava|ImmutableMultiset|
|SortedMultiset|Guava|ImmutableSortedMultiset|
|Multimap|Guava|ImmutableMultimap|
|ListMultimap|Guava|ImmutableListMultimap|
|SetMultimap|Guava|ImmutableSetMultimap|
|BiMap|Guava|ImmutableBiMap|
|ClassToInstanceMap|Guava|ImmutableClassToInstanceMap|
|Table|Guava|ImmutableTable|
