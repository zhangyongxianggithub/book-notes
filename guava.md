[TOC]
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
  - 笨拙且冗长: 在你想制作防御性副本的任何地方使用都不方便;
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

## New Collection Types
Guava引进了大量的新的集合类型，这些集合类型不在JDK中，但是也是广泛使用的，这些新的集合类型被设计为完美的兼容JDK结合类型。作为一个普遍存在的规则，Guava集合实现遵守JDK接口规范。
### Multiset
传统的Java书写方式以计算文档中一个单词的出现次数为例，如下:
```java
Map<String, Integer> counts = new HashMap<String, Integer>();
for (String word : words) {
  Integer count = counts.get(word);
  if (count == null) {
    counts.put(word, 1);
  } else {
    counts.put(word, count + 1);
  }
}
```
这很尴尬，容易出错，并且不支持收集各种有用的统计数据，比如总单词数。我们可以做得更好。Guava提供了一个新的集合类型Multiset，支持添加多个元素。维基百科定义的multiset，在数学上，multiset是集合的概括，其中集合中的元素可以多次出现，相比于元组，元素的顺序是无关的，multiset {a,a,b}与{a,b,a}是相等的。可以以2种方式来看待multiset:
- 类似于ArrayList<E>，但是没有顺序相关性，因为顺序不重要;
- 类似于Map<E,Integer>，带有元素与元素的数量;
Guava的Multiset API组合了2种看待multiset的操作API，如下:
- 当作为一个普通的Collection看待时，Multiset表现的更像一个无序的ArrayList，调用add(E)就是添加了一个给定的元素，iterator()方法迭代每个出现的元素，size()方法是所有元素的数量;
- 额外的查询操作与性能特点更像一个Map<E,Integer>，count(Object)返回元素个数，对于HashMultiset来说，count的时间复杂度是O(1)，对于TreeMultiset，count的时间复杂度是O(logn)等，entrySet()返回一个Set<Multiset.Entry<E>>类似于Map的entrySet，elementSet()返回multiset的所有去重的元素的Set，就像Map的keySet()一样，Multiset的内存消耗与元素数成正比。
明显的是，Multiset完全符合Collection接口的规范，除了极少数的情况下，比如TreeMultiset与TreeSet使用comparison来表示相等而不是Object.equals，特别是，Multiset.addAll(Collection) 为 Collection 中的每个元素每次出现添加一次，这比上面 Map 方法所需的 for 循环方便得多。请注意，Multiset<E>不是一个Map\<E, Integer>，虽然它可能是Mutliset实现的一部分，Mutliset是一个真正的Collection类型，满足所有的规范约束，其他明显的不同有:
- Multiset\<E>元素的个数必须是正的，不能有负值，0表示元素不在set中，所以不会在elementSet()与entrySet()中;
- multiset.size()返回集合的大小，等于所有元素个数的总和，对于去重元素数使用elementSet().size();
- multiset.iterator()迭代每个元素，所以迭代的长度=multiset.size();
- Multiset<E>支持添加元素、移除元素、直接设置元素的数量;
- setCount(elem,0)等价于把所有的elem移除;
- multiset.count(elem)对于不在集合中的elem返回0;

multiset的实现粗略的等价于JDK的map实现

|Map|Corresponding Multiset|是否支持null|
|:---|:---|:---|
|HashMap|HashMultiset|Yes|
|TreeMap|TreeMultiset|Yes|
|LinkedHashMap|LinkedHashMultiset|Yes|
|ConcurrentHashMap|ConcurrentHashMultiset|No|
|ImmutableMap|ImmutableMultiset|No|

`SortedMultiset`是`Multiset`接口的变体，它支持在指定范围内有效地获取子多集。 例如，您可以使用 latencies.subMultiset(0, BoundType.CLOSED, 100, BoundType.OPEN).size() 来确定在 100 毫秒延迟时间内对您的站点进行的点击次数，然后将其与 latencies.size() 进行比较 确定总体比例。TreeMultiset 实现了 SortedMultiset 接口。 在撰写本文时，ImmutableSortedMultiset 仍在测试 GWT 兼容性。
### Multimap
每个有经验的Java程序员都曾在某一时刻实现过Map<K,List<V>>或者Map<K,Set<V>>这样的结构，并处理了该结构的笨拙的问题。例如，Map<K, Set<V>> 是表示无标签有向图的典型方式。 Guava 的 Multimap 框架可以轻松处理从键到多个值的映射。 Multimap 是将键与任意多个值相关联的通用方法。有两种方法可以从概念上考虑 Multimap：作为从单个键到单个值的映射的集合或者作为从唯一键到值集合的映射。一般来说，Multimap 接口是第一选择，但允许您使用 asMap() 视图的方式查看它，该视图返回 Map<K, Collection<V>>接口，最重要的是，key不能映射到空集合，键要么映射到至少一个值，要么根本不存在于 Multimap 中。但是，也很少直接使用 Multimap接口； 更多时候你会使用 ListMultimap 或 SetMultimap，它们分别将键映射到 List 或 Set。
1. Construction
创建一个Multimap的最直接的方式是使用MultimapBuilder，可以配置key与value的表现，比如
```java
// creates a ListMultimap with tree keys and array list values
ListMultimap<String, Integer> treeListMultimap =
    MultimapBuilder.treeKeys().arrayListValues().build();

// creates a SetMultimap with hash keys and enum set values
SetMultimap<Integer, MyEnum> hashEnumMultimap =
    MultimapBuilder.hashKeys().enumSetValues(MyEnum.class).build();

```
您也可以选择直接在实现类上使用 create() 方法，但不建议使用最好使用MultimapBuilder。
2. Modifying
Multimap.get(key) 返回与指定键关联的值的视图集合，即使当前没有。 对于 ListMultimap，它返回一个 List，对于 SetMultimap，它返回一个 Set。修改写入底层 Multimap。 例如:
```java
Set<Person> aliceChildren = childrenMultimap.get(alice);
aliceChildren.clear();
aliceChildren.add(bob);
aliceChildren.add(carol);
```
修改multimap的其他方式包括.
3. Views
Multimap也支持返回其他功能强大的接口:
- asMap返回Map<K, Collection<V>>；
- entries;
- keySet();
- keys;
- values();
4. Multimap is not a Map
一个Multimap<K,V>并不是Map<K,Colections<V>>，尽管这样的map可能在Multimap的实现者中使用，比较明显的差异有:
- Multimap.get(key)总是返回一个非null的可能是空的集合。这并不意味着Multimap会为key额外分配内存，而是返回的集合是一个视图，允许您根据需要添加与键的关联;
- 如果您更喜欢类似Map的行为，比如为Multimap中不存在的key返回null，请使用asMap()视图获取Map<K, Collection<V>>。（或者，要从 ListMultimap中获取 Map<K,List<V>>，请使用静态 Multimaps.asMap()方法。SetMultimap和SortedSetMultimap存在类似的方法。）
- Multimap.containsKey(key) 当且仅当存在与指定键关联的任何元素时才为真。 特别是，如果一个键 k 先前与一个或多个值相关联，而这些值已经从 multimap 中删除，则 Multimap.containsKey(k) 将返回 false;
- Multimap.entries() 返回 Multimap 中所有键的所有条目。 如果您想要所有密钥集合条目，请使用 asMap().entrySet();
- Multimap.size() 返回整个多图中的条目数，而不是不同键的数量。 改为使用 Multimap.keySet().size() 来获取不同键的数量。

5. 实现
Multimap有多个实现，最好使用MultimapBuilder创建Multimap实例

|Implementation|Keys behave like|Values behave like|
|:---|:---|:---|
|ArrayListMultimap|HashMap|ArrayList|
|HashMultimap|HashMap|HashSet|
|LInkedListMultimap|LinkedHashMap|LinkedList|
|LinkedHashMultimap|LinkedHashMap|LinkedHashSet|
|TreeMultimap|TreeMap|TreeSet|
|ImmutableLIstMultimap|ImmutableMap|ImmutableList|
|ImmutableSetMultimap|ImmutableMap|ImmutableSet|
这些实现中的每一个，除了不可变的，都支持空键和值。请注意，并非所有实现实际上都作为 Map<K, Collection<V>> 与列出的实现一起实现！ （特别是，一些 Multimap 实现使用自定义哈希表来最小化开销。）如果您需要更多自定义，请使用 Multimaps.newMultimap(Map, Supplier<Collection>) 或列表和集合版本以使用自定义集合、列表或集合实现来支持您的多图。

### BiMap
将值映射回键的传统方法是维护两个单独的映射并使它们保持同步，但这很容易出错并且当映射中已经存在值时会变得非常混乱。 例如:
```java
Map<String, Integer> nameToId = Maps.newHashMap();
Map<Integer, String> idToName = Maps.newHashMap();

nameToId.put("Bob", 42);
idToName.put(42, "Bob");
// what happens if "Bob" or 42 are already present?
// weird bugs can arise if we forget to keep these in sync...
```
一个BiMap<K,V>就是一个Map<K,V>:
- 允许你通过`inverse()`方法获得BiMap的相反的映射;
- 保证值是唯一的，`values()`返回值是一个Set.
如果调用biMap.put(key,value)时，value已存在，那么调用抛出IllegalArgumentException，如果你想要删除一个key，那么调用
`BiMap.forcePut(key,value)`:
```java
BiMap<String, Integer> userId = HashBiMap.create();
String userForId = userId.inverse().get(id);
```

|Key-Value Map Impl|Value-Key Map Impl|Corresponding BiMap|
|:---|:---|:---|
|HashMap|HashMap|HashBiMap|
|ImmutableMap|ImmutableMap|ImmutableBiMap|
|EnumMap|EnumMap|EnumBiMap|
|EnumMap|HashMap|EnumHashBiMap|
### Table
```java
Table<Vertex, Vertex, Double> weightedGraph = HashBasedTable.create();
weightedGraph.put(v1, v2, 4);
weightedGraph.put(v1, v3, 20);
weightedGraph.put(v2, v3, 5);

weightedGraph.row(v1); // returns a Map mapping v2 to 4, v3 to 20
weightedGraph.column(v3); // returns a Map mapping v1 to 20, v2 to 5
```
通常，当您尝试对多个键进行索引时，您最终会得到类似Map<FirstName, Map<LastName, Person>>的东西，这很丑陋且难以使用。 
Guava提供了一种新的集合类型Table，它支持任何"行"类型和"列"类型的这种用例。表格支持多种视图，让您可以从任何角度使用数据，包括:
- rowMap()将会把Table<R,C,V>视为一个Map<R,Map<C,V>>，简单的，rowKeySet()会返回一个Set<R>
- row(r)将会返回一个非null的Map<C,V>，对返回的map做变更也会修改底层的Table;
- 也提供了列相关的类似的方法: columnMap(),columnKeySet(),column(c)，基于列的访问在效率上比基于行的访问的效率低;
- cellSet()会返回Table的Set<Table.Cell<R,C,V>>，Cell类似于Map.Entry，只是key是以行/列的组合值的方式区分的.

Table的几个简单的实现如下:
- HashBasedTable, 底层是通过HashMap<R,HashMap<C,V>>实现的;
- TreeBasedTable, 底层是通过TreeMap<R,TreeMap<C,V>>实现的;
- ImmutableTable;
- ArrayTable, 需要在创建时指定完整的行列，底层实现是一个二维数组，当不是稀疏表的时候，可以提高速度与减少内存占用;
### ClassToInstanceMap
Map的key是类型也就是class，值是该class的对象，可以用ClassToInstanceMap来实现;除了继承的Map接口的操作意外，还支持`T getInstance(Class<T>)`与`T putInstance(Class<T>, T)`操作，避免类型转换保证了类型安全。ClassToInstanceMap 有一个类型参数，通常命名为 B，表示映射管理的类型的上限。 例如：
```java
ClassToInstanceMap<Number> numberDefaults = MutableClassToInstanceMap.create();
numberDefaults.putInstance(Integer.class, Integer.valueOf(0));
```
从技术上来讲，ClassToInstanceMap<B>实现了Map<Class<? extends B>, B>，或者换句话说，一个从B的子类到B的实例的映射。这会使ClassToInstanceMap中涉及的泛型类型有点混乱，但请记住B始终是Map中类型key的上限，通常，B只是一个Object。Guava提供了名为 MutableClassToInstanceMap 和 ImmutableClassToInstanceMap 的2个实现，重要提示：与任何其他 Map<Class, Object> 一样，ClassToInstanceMap 可能包含原始类型的条目，并且原始类型及其对应的包装器类型可能映射到不同的值。
### RangeSet
RangeSet是一个不连接的非空的range集合，当添加一个range到RangeSet时，任何连接的range都会被合并，空的range会被忽略，如下:
```java
   RangeSet<Integer> rangeSet = TreeRangeSet.create();
   rangeSet.add(Range.closed(1, 10)); // {[1, 10]}
   rangeSet.add(Range.closedOpen(11, 15)); // disconnected range: {[1, 10], [11, 15)}
   rangeSet.add(Range.closedOpen(15, 20)); // connected range; {[1, 10], [11, 20)}
   rangeSet.add(Range.openClosed(0, 0)); // empty range; {[1, 10], [11, 20)}
   rangeSet.remove(Range.open(5, 10)); // splits [1, 10]; {[1, 5], [10, 10], [11, 20)}
```
假如你想merge `Range.closed(1, 10)`与`Range.closedOpen(11, 15)`，你必须首先对Range做预处理`Range.canonical(DiscreteDomain)`，比如设置`DiscreteDomain.integers()`。RangeSet在JDK1.6之后才支持。RangeSet的实现也支持很多其他接口的返回，比如:
- complement(): 一个RangeSet的补集，也是一个RangeSet;
- subRangeSet(Range<C>): 返回RangeSet与range的交集;
- asRanges(): 返回Range的set形式;
- asSet(DiscreteDomain<C>): 将RangeSet<C>作为ImmutableSortedSet<C>返回;
除了返回视图接口的操作，也支持查询操作，如下:
- contains(C): 最基础的操作，返回C是否在RangeSet中;
- rangeContaining(C): 返回包含C的range,没找到返回null;
- enclose(Range(C)): 测试Range是否包含在RangeSet中;
- span(): 返回包含RangeSet中每个Range的最小的Range;
### RangeMap
RangeMap是一个集合类型，这个集合类型把Range映射为一个值，与RangeSet不同，RangeMap
```java
RangeMap<Integer, String> rangeMap = TreeRangeMap.create();
rangeMap.put(Range.closed(1, 10), "foo"); // {[1, 10] => "foo"}
rangeMap.put(Range.open(3, 6), "bar"); // {[1, 3] => "foo", (3, 6) => "bar", [6, 10] => "foo"}
rangeMap.put(Range.open(10, 20), "foo"); // {[1, 3] => "foo", (3, 6) => "bar", [6, 10] => "foo", (10, 20) => "foo"}
rangeMap.remove(Range.closed(5, 11)); // {[1, 3] => "foo", (3, 5) => "bar", (11, 20) => "foo"}
```
RangeMap提供了2个视图接口:
- asMapOfRanges(): 将RangeMap视为Map<Range<K>,V>;
- subRangeMap(Ranges(K)>)；

## 工具类
任何具有JDK Collections Framework经验的程序员都知道并喜欢java.util.Collections包下提供的实用程序。 Guava在这些方面提供了更多实用程序：适用于所有集合的静态方法。 这些是Guava中最受欢迎和最成熟的部分。与特定接口对应的方法以相对直观的方式进行分组:
|Interface|JDK or Guava|Corresponding Guava utility class|
|:---|:---|:---|
|Collection|JDK|Collection2|
|List|JDK|Lists|
|Set|JDK|Sets|
|SortedSet|JDK|Sets|
|Map|JDK|Maps|
|SortedMap|JDK|Maps|
|Queue|JDK|Queues|
|Multiset|Guava|Multisets|
|Multimap|Guava|Multimaps|
|BiMap|Guava|Maps|
|Table|Guava|Tables|
寻找变换、过滤器等？ 这些东西在我们的函数式编程文章中，在函数式术语下。
### 静态构造函数
在JDK 7之前，构建新的泛型集合需要令人不快的代码重复，我想我们都同意这是不愉快的。 Guava提供了使用泛型推断右侧类型的静态方法: 
```java
List<TypeThatsTooLongForItsOwnGood> list = Lists.newArrayList();
Map<KeyType, LongishValueType> map = Maps.newLinkedHashMap();
```
可以肯定的是，JDK 7 中的菱形运算符减少了这方面的麻烦:
```java
List<TypeThatsTooLongForItsOwnGood> list = new ArrayList<>();
```
但Guava比这更进一步。使用工厂方法模式，我们可以非常方便地使用它们的起始元素来初始化集合。
```java
Set<Type> copySet = Sets.newHashSet(elements);
List<String> theseElements = Lists.newArrayList("alpha", "beta", "gamma");
```
此外，通过命名的工厂方法的能力（effective Java条目1），我们可以提高初始化结合的可读性:
```java
List<Type> exactly100 = Lists.newArrayListWithCapacity(100);
List<Type> approx100 = Lists.newArrayListWithExpectedSize(100);
Set<Type> approx100Set = Sets.newHashSetWithExpectedSize(100);
```
下面列出了提供的精确静态工厂方法及其相应的实用程序类。
注意：Guava 引入的新集合类型不公开原始构造函数，或者在实用程序类中具有初始化程序。 相反，它们直接公开静态工厂方法，例如：
```java
Multiset<String> multiset = HashMultiset.create();
```
### Ierrables
只要有可能，Guava更喜欢提供接受Iterable而不是Collection的实用程序，在Google，经常遇到的情况是，collection不止存储在内存中，还可能在一个数据库中或者来自其他的数据中心，因为无法一次性获取所有的元素，而不支持类似于size()的操作。因此，你希望的所有的collection相关的操作基本都可以在Iterables中找到，此外，大部分的Iterables方法在Iterators中也有对应的版本。Iterables中的绝大部分操作都是惰性的，它们仅在绝对必要时执行内部迭代，本身返回Iterables的方法返回延迟计算的视图，而不是显式地在内存中构造一个集合。从Guava 12开始，从 Guava 12 开始，Iterables 得到了 FluentIterable 类的补充，该类包装了一个 Iterable 并为其中许多操作提供了流式的语法。以下是最常用的实用程序的选择，尽管Iterables中的许多更函数式的方法在Guava的函数式术语中进行了讨论。

|Method|Description|See Also|
|:---|:---|:---|
|concat(Iterable<Iterable>)|返回拼接迭代后的惰性视图|concat(Iterable...)|
|frequency(Iterable, Object)|返回对象的出现次数|类似与Collections.frequency(Collection,Object),可以看Multiset|
|partition(Oterable,int)|返回划分为指定大小块的可迭代的不可修改视图|Lists.partition(List, int), paddedPartition(Iterable, int)||||getFirst(Iterable, T default)|返回迭代的第一个元素如果是空就返回默认值|Iterable.iterator().next(), FluentIterable.first()|
|getLast(Iterable)|返回迭代的最后一个元素，如果没有就抛出NoSuchElementException异常|getLast(Iterable, T default), FluentIterable.last()|
|elementsEqual(Iterable, Iterable)|迭代的元素值与顺序相同，判断|Compare List.equals(Object)|
|unmodifiableIterable(Iterable)|返回不可变更视图|Collections.unmodifiableCollection(Collection)|
|limit(Iterable, int)|返回迭代中前n个元素|FluentIterable.limit(int)|
|getOnlyElement(Iterable)|返回Iterable中的唯一元素，如果空或者迭代有多个元素则失败|getOnlyElement(Iterable, T default)|

```java
Iterable<Integer> concatenated = Iterables.concat(
  Ints.asList(1, 2, 3),
  Ints.asList(4, 5, 6));
// concatenated has elements 1, 2, 3, 4, 5, 6

String lastAdded = Iterables.getLast(myLinkedHashSet);

String theElement = Iterables.getOnlyElement(thisSetIsDefinitelyASingleton);
  // if this set isn't a singleton, something is wrong!
```
一般来说，集合通常都支持相同的自然的操作，但是可迭代对象可以不支持一些操作。当输入实际上是一个 Collection 时，这些操作中的每一个都委托给相应的 Collection 接口方法。 例如，如果向 Iterables.size 传递一个 Collection，它将调用 Collection.size 方法，而不是遍历迭代器。

|Method|Analogous Collection method|FluentIterable equivalent|
|:---|:---|:---|
|addAll(Collection addTo, Iterable toAdd)|Collection.addAll(Collection)	||
|contains(Iterable, Object)|Collection.contains(Object)|FluentIterable.contains(Object)|
|removeAll(Iterable removeFrom, Collection toRemove)|	Collection.removeAll(Collection)||	
|retainAll(Iterable removeFrom, Collection toRetain)|Collection.retainAll(Collection)	||
|size(Iterable)|Collection.size()|FluentIterable.size()
|toArray(Iterable, Class)|	Collection.toArray(T[])	|FluentIterable.toArray(Class)|
|isEmpty(Iterable)|Collection.isEmpty()|FluentIterable.isEmpty()|
|get(Iterable, int)|List.get(int)|FluentIterable.get(int)|
|toString(Iterable)|Collection.toString()|FluentIterable.toString()|

除了上面介绍的方法和函数式术语中介绍的方法外，FluentIterable还有一些方便的方法用于复制到不可变集合中:

|Result Type|Method|
|:---|:---|
|ImmutableList|toImmutableList()|
|ImmutableSet|toimmutableSet()|
|ImmutableSortedSet|toImmutableSortedSet(Comparator)|

### Lists
除了静态构造方法和函数式编程方法之外，Lists 还为 List 对象提供了许多有价值的实用方法。
- partition(List, int)返回分片后的数组;
- reverse(List) 返回数组的相反顺序的数组，如果数组是Immutable的，考虑使用ImmutableList.reverse()方法
```java
List<Integer> countUp = Ints.asList(1, 2, 3, 4, 5);
List<Integer> countDown = Lists.reverse(theList); // {5, 4, 3, 2, 1}
List<List<Integer>> parts = Lists.partition(countUp, 2); // {{1, 2}, {3, 4}, {5}}
```
一个看似简单的任务（找到某些元素的最小值或最大值）由于希望最小化位于不同位置的分配、装箱和 API 而变得复杂。下表总结了此任务的最佳实践。
下表仅显示了 max() 解决方案，但同样的建议也适用于查找 min()。
|What you're comparing|Exactly 2 instances|More than 2 instances|
|:---|:---|:---|
|unboxed numeric primitives(e.g., long, int, double, or float)|Math.max(a, b)|Longs.max(a, b, c),Ints.max(a, b, c),etc.|
|Comparable instances(e.g., Duration, String, Long, etc.)|	Comparators.max(a, b)|Collections.max(asList(a, b, c))
|using a custom Comparator(e.g., MyType with myComparator)|Comparators.max(a, b, cmp)|Collections.max(asList(a,b,c),cmp)|

### Sets
Sets包含了很多非常好的方法。集合理论相关的操作。这些方法都返回一个SetView，可以用于:
- 作为一个set，因为它实现了Set接口;
- 通过copyInto(Set)拷贝到别的集合中;
- 生成不可变更集合(immutableCopy)；
主要的方法有：union(Set,Set)，intersection(Set, Set)，difference(Set,Set)，symmetricDifference(Set,Set)；比如:
```java
Set<String> wordsWithPrimeLength = ImmutableSet.of("one", "two", "three", "six", "seven", "eight");
Set<String> primes = ImmutableSet.of("two", "three", "five", "seven");

SetView<String> intersection = Sets.intersection(primes, wordsWithPrimeLength); // contains "two", "three", "seven"
// I can use intersection as a Set directly, but copying it can be more efficient if I use it a lot.
return intersection.immutableCopy();
```
其他比较有用的工具方法如下:
- cartesianProduct(List<Set>), Set中的每个元素都2*2配对都生成一个list，来返回就是生成笛卡尔积;
- powerSet(Set)，返回指定集合的所有子集的集合.

```java
Set<String> animals = ImmutableSet.of("gerbil", "hamster");
Set<String> fruits = ImmutableSet.of("apple", "orange", "banana");

Set<List<String>> product = Sets.cartesianProduct(animals, fruits);
// {{"gerbil", "apple"}, {"gerbil", "orange"}, {"gerbil", "banana"},
//  {"hamster", "apple"}, {"hamster", "orange"}, {"hamster", "banana"}}

Set<Set<String>> animalSets = Sets.powerSet(animals);
// {{}, {"gerbil"}, {"hamster"}, {"gerbil", "hamster"}}
```
### Maps
Maps有很多有价值的方法
1. uniqueIndex
Maps.uniqueIndex(Iterable, Function) 解决了一堆对象转化为Map常见情况，其中每个对象都有一些唯一的主键属性，并且希望能够根据该属性查找这些对象。假设我们有一堆我们知道具有唯一长度的字符串，并且我们希望能够查找具有特定长度的字符串。
```java
ImmutableMap<Integer, String> stringsByIndex = Maps.uniqueIndex(strings, new Function<String, Integer> () {
    public Integer apply(String string) {
      return string.length();
    }
  });
```
如果索引不是唯一的，那么可以使用Multimaps.index。
2. difference
`Maps.difference(Map,Map)`允许你比较2个map的不同，它会返回一个MapDifference对象，会生成维恩图的一些方法如下:
|Method|Description|
|:---|:---|
|`entriesInCommon()`|返回2个map中相同的entry，key与value都相同|
|`entriesDiffering()`|返回2个map中相同key，不同value的entry，不同的value以`MapDifference.ValueDifference`的形式表示，可以看到2个不一样的值|
|`entriesOnlyOnLeft()`|返回key出现在左面，没有在右面的entry|
|`entriesOnlyOnRight()`|返回key出现在右面没有出现在左面的entry|

```java
Map<String, Integer> left = ImmutableMap.of("a", 1, "b", 2, "c", 3);
Map<String, Integer> right = ImmutableMap.of("b", 2, "c", 4, "d", 5);
MapDifference<String, Integer> diff = Maps.difference(left, right);

diff.entriesInCommon(); // {"b" => 2}
diff.entriesDiffering(); // {"c" => (3, 4)}
diff.entriesOnlyOnLeft(); // {"a" => 1}
diff.entriesOnlyOnRight(); // {"d" => 5}
```
BiMap的工具方法也在Maps类中，因为BiMap也是一个Map

|BiMap工具方法|对应的Map工具方法|
|:---|:---|
|`synchronizedBiMap(BiMap)`|`Collections.synchronizedMap(Map)`|
|`unmodifiableBiMap(BiMap)`|`Collections.unmodifiableMap(Map)`|

Maps提供了很多的静态工厂方法
### Multisets
标准的`Collection`操作，比如`containAll``，会忽略multiset中的元素数量，只关注元素是否出现在multiset中，Multisets提供了很多的工具函数，这些工具函数都可以处理Multiset中的多值情况。

|Method|Explanation|Difference from Collection method|
|:---:|:---:|:---:|
|`containsOccurrences(Multiset sup, Multiset sub)`|如果对于所有的o，sub.count(o)<=supper.count(o) 则返回true|`Collection.containsAll`会忽略元素数量，只检测元素是否在集合中|
|`removeOccurrences(Multiset removeFrom, Multiset toRemove)`|Removes one occurrence in removeFrom for each occurrence of an element in toRemove.|Collection.removeAll removes all occurrences of any element that occurs even once in toRemove|
|retainOccurrences(Multiset removeFrom, Multiset toRetain)|Guarantees that removeFrom.count(o) <= toRetain.count(o) for all o.|Collection.retainAll keeps all occurrences of elements that occur even once in toRetain.|
|intersection(Multiset, Multiset)|Returns a view of the intersection of two multisets; a nondestructive alternative to retainOccurrences||

```java
Multiset<String> multiset1 = HashMultiset.create();
multiset1.add("a", 2);

Multiset<String> multiset2 = HashMultiset.create();
multiset2.add("a", 5);

multiset1.containsAll(multiset2); // returns true: all unique elements are contained,
  // even though multiset1.count("a") == 2 < multiset2.count("a") == 5
Multisets.containsOccurrences(multiset1, multiset2); // returns false

Multisets.removeOccurrences(multiset2, multiset1); // multiset2 now contains 3 occurrences of "a"

multiset2.removeAll(multiset1); // removes all occurrences of "a" from multiset2, even though multiset1.count("a") == 2
multiset2.isEmpty(); // returns true
```
Multisets中包含的其他的工具函数有:
- copyHighestCountFirst(Multiset), 返回multiset的不可变更拷贝，这个拷贝中的元素是按照出现的频率降序排列的;
- unmodifiableMultiset(Multiset), 返回multiset的不可变更的视图;
- unmodifiableSortedMultiset(SortedMultiset), 返回排序的multiset的不可变更的视图;

```java
Multiset<String> multiset = HashMultiset.create();
multiset.add("a", 3);
multiset.add("b", 5);
multiset.add("c", 1);

ImmutableMultiset<String> highestCountFirst = Multisets.copyHighestCountFirst(multiset);

// highestCountFirst, like its entrySet and elementSet, iterates over the elements in order {"b", "a", "c"}
```
### Multimaps
1. index
Maps.uniqueIndex的兄弟方法，`Multimaps.index(Iterable, Function)`解决了，通过某些属性寻找对象的问题，找到的对象不唯一。也就是对对象分组或者分类的问题。
```java
ImmutableSet<String> digits = ImmutableSet.of(
    "zero", "one", "two", "three", "four",
    "five", "six", "seven", "eight", "nine");
Function<String, Integer> lengthFunction = new Function<String, Integer>() {
  public Integer apply(String string) {
    return string.length();
  }
};
ImmutableListMultimap<Integer, String> digitsByLength = Multimaps.index(digits, lengthFunction);
/*
 * digitsByLength maps:
 *  3 => {"one", "two", "six"}
 *  4 => {"zero", "four", "five", "nine"}
 *  5 => {"three", "seven", "eight"}
 */
```
2. invertFrom
因为Multimap允许多个key指向一个value，或者一个key指向多个value，所以可以倒置，倒置也是很有用的还是multimap，`invertFrom(Multimap toInvert, Multimap dest)`就是干这个用的，如果你在使用`ImmutableMultimap`，那么可以直接使用`ImmutableMultimap.inverse()`倒置。
```java
ArrayListMultimap<String, Integer> multimap = ArrayListMultimap.create();
multimap.putAll("b", Ints.asList(2, 4, 6));
multimap.putAll("a", Ints.asList(4, 2, 1));
multimap.putAll("c", Ints.asList(2, 5, 3));

TreeMultimap<Integer, String> inverse = Multimaps.invertFrom(multimap, TreeMultimap.<Integer, String>create());
// note that we choose the implementation, so if we use a TreeMultimap, we get results in order
/*
 * inverse maps:
 *  1 => {"a"}
 *  2 => {"a", "b", "c"}
 *  3 => {"c"}
 *  4 => {"a", "b"}
 *  5 => {"c"}
 *  6 => {"b"}
 */
```
3. forMap
在一个Map对象上使用Multimap的方法，forMap(Map)将Map视为一个SetMultimap，这非常有用，比如，与Multimaps.invertFrom联合使用
```java
Map<String, Integer> map = ImmutableMap.of("a", 1, "b", 1, "c", 2);
SetMultimap<String, Integer> multimap = Multimaps.forMap(map);
// multimap maps ["a" => {1}, "b" => {1}, "c" => {2}]
Multimap<Integer, String> inverse = Multimaps.invertFrom(multimap, HashMultimap.<Integer, String> create());
// inverse maps [1 => {"a", "b"}, 2 => {"c"}]
```
4. Wrappers
Multimaps 提供了传统的包装方法，以及基于您选择的 Map 和 Collection 实现来获取自定义 Multimap 实现的工具。
|Multimap type|Unmodifiable|Synchronized|Custom|
|:---|:---|:---|:---|
|Multimap|unmodifiableMultimap|synchronizedMultimap|newMultimap|
|ListMultimap|unmodifiableListMultimap|synchronizedListMultimap|newListMultimap|
|SetMultimap|unmodifiableSetMultimap|synchronizedSetMultimap|newSetMultimap|
|SortedSetMultimap|unmodifiableSortedSetMultimap|synchronizedSortedSetMultimap|newSortedSetMultimap|

自定义 Multimap 实现允许您指定应在返回的 Multimap 中使用的特定实现。警告包括：
- multimap 假定完全拥有 map 和 factory 返回的列表。这些对象不应手动更新，提供时应为空，并且不应使用软引用、弱引用或幻像引用;
- 不保证修改 Multimap 后 Map 的内容会是什么样子;
- 当任何并发操作更新 multimap 时，multimap 不是线程安全的，即使 map 和工厂生成的实例是。不过，并发读取操作将正常工作。如有必要，请使用同步包装器解决此问题;
- 如果 map、factory、factory 生成的列表和 multimap 的内容都是可序列化的，则 multimap 是可序列化的；
- Multimap.get(key) 返回的集合与您的供应商返回的集合的类型不同，但如果您的供应商返回 RandomAccess 列表，则 Multimap.get(key) 返回的列表也将是随机访问;

请注意，自定义 Multimap 方法需要一个 Supplier 参数来生成新的集合。这是一个编写由 TreeMap 映射到 LinkedList 支持的 ListMultimap 的示例。
```java
ListMultimap<String, Integer> myMultimap = Multimaps.newListMultimap(
  Maps.<String, Collection<Integer>>newTreeMap(),
  new Supplier<LinkedList<Integer>>() {
    public LinkedList<Integer> get() {
      return Lists.newLinkedList();
    }
  });
```
### Tables
Tables提供了几个有用的工具。
1. customTable
` Tables.newCustomTable(Map, Supplier<Map>)`允许你指定Table的底层实现，
```java
// use LinkedHashMaps instead of HashMaps
Table<String, Character, Integer> table = Tables.newCustomTable(
  Maps.<String, Map<Character, Integer>>newLinkedHashMap(),
  new Supplier<Map<Character, Integer>> () {
    public Map<Character, Integer> get() {
      return Maps.newLinkedHashMap();
    }
  });
```
2. transpose
`transpose(Table<R, C, V>)`方法可以让你将`Table<R,C,V>`视为`Table<C,R,V>`
3. wrappers
# Service
Guava的Service接口表示一个带有可操作状态与启动/停止方法的对象，比如: web服务器，RPC服务器，Timer等，像这样需要适当的启动和关闭管理的服务，状态管理是非常重要的，尤其是在涉及多个线程或调度的情况下。Guava提供了一些框架来为您管理状态逻辑和线程同步的细节。
## Using a Service
一个`Service`的正常的生命周期顺序是:
- Service.State.NEW;
- Service.State.STARTING;
- Service.State.RUNNING;
- Service.State.STOPPING;
- Service.State.TERMINATING;
一个停止的`Service`不能被重启，如果`Service`在启动、运行或者停止中失败，将会进入到`Service.State.FAILED`状态，如果服务是NEW，则可以使用`startAsync()`异步启动服务。因此，您应该构建您的应用程序，使其具有启动每个服务的唯一位置。停止`Service`的操作也是类似的，使用异步的`stopAsync()`方法，但是与`startAsync()`不同，多次调用停止方法是可以的。这是为了能够处理关闭服务时可能发生的竞争。`Service`还提供了几种方法来等待服务转换完成。
- 使用`addListener()`的异步的方式，addListener()允许您添加将在`Service`的每个状态转换时调用的`Service.Listener`，注意: 如果在添加`Listener`时服务不是NEW，则任何已经发生的状态转换都不会在`Listener`上重播。
- 使用`awaitRunning()`的同步的方式，这是不可中断的，不会引发检查异常，并在`Service`完成启动后返回，如果服务启动失败，则抛出`IllegalStateException`异常，同样的，`awaitTerminated()`等待服务达到终止状态（TERMINATED 或 FAILED）。这两种方法还具有允许指定超时的重载版本。
服务接口微妙而复杂。我们不建议直接实施它。相反，请使用guava中的抽象基类之一作为实现的基础。每个基类都支持特定的线程模型。
## 接口实现
1. AbstractIdleService
AbstractIdleService框架实现`Service`接口，它在RUNNING状态下不执行任何操作——因此在运行时不需要CPU资源；但是有启动和关闭操作要执行。实现这样的`Service`就只需要简单的扩展`AbstractIdleService`并实现`startUp()`和 `shutDown()`方法.
```java
protected void startUp() {
  servlets.add(new GcStatsServlet());
}
protected void shutDown() {}
```
2. AbstractExecutionThreadService
一个`AbstractExecutionThreadService`在一个线程中执行`startup`、`running`、`shutdown`操作，你必须覆盖`run()`方法，它必须对停止请求进行响应，比如，你可能在一个循环中执行操作:
```java
public void run() {
  while (isRunning()) {
    // perform a unit of work
  }
}
```
或者，您可以以任何方式覆盖导致`run()`返回。覆盖`startUp()`和`shutDown()`是可选的，但将为您管理服务状态。
```java
protected void startUp() {
  dispatcher.listenForConnections(port, queue);
}
protected void run() {
  Connection connection;
  while ((connection = queue.take() != POISON)) {
    process(connection);
  }
}
protected void triggerShutdown() {
  dispatcher.stopListeningForConnections(queue);
  queue.put(POISON);
}
```
请注意，`start()`调用您的`startUp()`方法，为您创建一个线程，并在该线程中调用`run()`。`stop()`调用 `triggerShutdown()`并等待线程终止。
3. AbstractScheduledService
`AbstractScheduledService`在运行时执行一些周期性任务。子类实现`runOneIteration()`以指定任务的一次迭代，以及熟悉的`startUp()`和`shutDown()`方法。要描述执行计划，您必须实现`scheduler()`方法。通常，您将使用 `AbstractScheduledService.Scheduler`提供的调度之一，或者`newFixedRateSchedule(initialDelay, delay, TimeUnit)`或`newFixedDelaySchedule(initialDelay, delay, TimeUnit)`，对应于 `ScheduledExecutorService`中熟悉的方法。自定义调度可以使用`CustomScheduler`来实现；有关详细信息，请参阅 Javadoc。
4. AbstractService
当需要自己手动管理线程时，直接集成`AbstractService`即可。通常，前面的实现可以为您提供更良好的服务，但在某些情况下建议您实现`AbstractService`，比如，当您将提供自己的线程语义的内容建模为`Service`时，您有自己的特定线程要求。继承`AbstractService`要实现2个方法:
- `doStart()`: 第一次调用`startAsync()`会调用`doStart()`，你的`doStart()`方法应该执行所有初始化，然后如果启动成功，则最终调用 notifyStarted()，如果启动失败，则最终调用 notifyFailed()；
- `doStop()`: `doStop()`在第一次调用`stopAsync()`时调用，你的`doStop()`方法应该关闭您的服务，然后如果关闭成功则最终调用`notifyStopped()`或如果关闭失败则调用`notifyFailed()`。
## Using ServiceManager
除了Service框架实现之外，Guava还提供了一个`ServiceManager`类，它使涉及多个`Service`实现的某些操作更容易。使用一组`Service`创建一个新的 `ServiceManager`。然后你可以管理它们:
- `startAsync()`启动所有管理的`Service`;
- `stopAsync()`停止所有管理的`Service`;
- `addListener()`添加`ServiceManager.Listener`;
- `awaitHealthy()`等待所有的`Service`到达RUNNING状态;
- `awaitStopped()`等待所有的`Service`到达终止状态;
- `isHealthy()`如果所有的`Service`的状态都是RUNNING，则返回true;
- `servicesByState()`返回所有服务的状态;
- `startupTimes()`返回所有服务的启动时间;
虽然建议通过`ServiceManager`管理`Service`生命周期，但通过其他机制启动的状态转换不会影响其方法的正确性。例如，如果`Service`是通过`startAsync()`之外的某种机制启动的，则listeners将在适当的时候被调用，并且`awaitHealthy()`仍将按预期工作。 `ServiceManager`的唯一要求是在构造`ServiceManager`时所有服务必须是 NEW。


