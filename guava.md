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

