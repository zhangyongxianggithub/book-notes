common.graph 是一个对图形数据结构建模的工具包，也就是对实体与关系进行建模，这种数据的例子包括webpage与超链接、科学家与科学家发表的文章、航班与航班的航线、人与家庭（家庭树）。common.graph的目的就是提供通过通用与可扩展性的语言来处理这样的数据。
## Definitions
graph包含很多node(也叫做vertice)与边（也叫做link或者arc(弧)）。每个边都用来连接节点，边连接的node也叫做边的端点（endpoint）。虽然我们在下面介绍一个称为 Graph 的接口，但我们将使用“graph”（小写“g”）作为指代这种数据结构的通用术语。 当我们想引用这个库中的特定类型时，我们将其大写。
如果一条边具有定义的起点（其源）和终点（其目标，也称为其目的地），则它是有向的。 否则，它是无向的。 有向边适用于建模非对称关系（descended from、links to、authored by），而无向边适用于建模对称关系（coauthored a paper with、distance between、sibling of）。如果图的每条边都是有向的，则图是有向的，如果其每条边都是无向的，则图是无向的。（common.graph不支持同时具有有向和无向边的图）。
给出下面的例子
```java
graph.addEdge(nodeU, nodeV, edgeUV);
```
- nodeU和nodeV相互相邻;
- edgeUV发生在nodeU和nodeV上（反之亦然）;
如果graph是有向的:
- nodeU是nodeV的前驱;
- nodeV是nodeU的后继;
- edgeUV是nodeU的outgoing边;
- edgeUV是nodeV的incoming边;
- nodeU是edgeUV的source;
- nodeV是edgeUV的target;
如果graph是无向的:
- nodeU是nodeV的前驱与后继;
- nodeV是nodeU的前驱与后继;
- edgeUV是nodeU的outgoing与incoming边;
- edgeUV是nodeV的outgoing与incoming边;
所有这些关系都与图有关。self-loop指的是连接自己的边，也就是说，边的2个端点是同一个端点，如果一个self-loop是有向的，它既是节点的outgoing边和incoming边，节点既是self-loop边的源又是目标。如果两条边以相同的顺序（如果有）连接相同的节点，则它们是平行的，如果它们以相反的顺序连接相同的节点，则它们是反平行的。（无向边不能是反平行的）。给出下面的例子:
```java
directedGraph.addEdge(nodeU, nodeV, edgeUV_a);
directedGraph.addEdge(nodeU, nodeV, edgeUV_b);
directedGraph.addEdge(nodeV, nodeU, edgeVU);

undirectedGraph.addEdge(nodeU, nodeV, edgeUV_a);
undirectedGraph.addEdge(nodeU, nodeV, edgeUV_b);
undirectedGraph.addEdge(nodeV, nodeU, edgeVU);
```
在有向图中，edgeUV_a和edgeUV_b相互平行，并且都与edgeVU反平行。在undirectedGraph中，edgeUV_a、edgeUV_b和edgeVU中的每一个都与其他两个相互平行。
## Capabilities
common.graph提供了出路图形的接口与类，但是它不提供IO与视图的功能，只能用在有限的使用场景中。作为一个图形库，支持以下图形的变体:
- 有向图;
- 无向图;
- 加权图;
- 支持平行边;
- 支持边/节点的插入排序、其他排序、或者无序的图形;
common.graph类型支持的图类型描述在Javadoc中，每种图形类型的内置实现所支持的图形类型描述在与实现关联的Builder的Javadoc文档中。本库中类型的具体实现（尤其是第三方实现）不需要支持所有这些变体，当然也可以额外支持其他的变体。
库隐藏了底层数据结构的存储，关系可以存储为矩阵、临接列表或者临接映射等。具体依赖实现者的使用场景。common.graph（此时）不包括对以下图形变体的显式支持，尽管它们可以使用现有类型进行建模：
- trees;
- forests;
- 具有不同类型的node或者不同类型edge的图（二分图/k-分图/多模态图）;
- 超图 hypergraphs
- 同时具有有向边与无向边的图;
Graphs 类提供了一些基本实用程序（例如，复制和比较图形）。
## Graph Types
共有3个顶级图形接口，接口通过边的表示方式的不同区分:
- Graph
- ValueGraph;
- Network;
这3个是兄弟类型，任意一个；类型都不是其他2个类型的子类型。这3个顶级接口都扩展了SuccessorsFunction与PredecessorsFunction接口，这些接口可以作为图形算法的输入参数类型比如深度遍历算法。图形算法大部分只需要具有访问图中节点的前驱与后继节点的方法就可以了。
- Graph: Graph是最简单与最基础的图形类型，它定义了处理node-to-node关系的底层操作，比如successors(node), adjacentNodes(node)与isDegree(node)，它的节点都是唯一对象，你可以认为他们类似于Map的key。边是完全匿名的;
- ValueGraph: ValueGraph有所有Graph中node相关的方法，添加了一些方法处理边的权重值，ValueGraph于Graph之间的关系类似于Map与Set之间的关系，Graph的边都是端点对的set集合，ValueGraph的边是端点对到权重值的Map集合。ValueGraph提供了一个asGraph()方法返回ValueGraph的Graph引用类型，允许操作在Graph实例上的方法也可以应用到ValueGraph实例。
- Network: Network有所有Graph中的node相关的方法，添加了很多边相关的方法还有处理node-to-edge关系的方法，比如outEdges(node)、incidentNodes(edge)、edgesConnecting(nodeU,nodeV)。Network的边是一等的唯一对象，与node节点类似。
3种图形类型的本质区分在于边的表示方式。
Graph的边是节点间的匿名连接，边没有标识或者属性，当2个节点之间最多只有一个边并且边上没有什么关联信息的时候，使用Graph；ValueGraph的边有权重或者标签，当2个节点之间最多只有一个边并且边上存在关联信息的时候使用ValueGraph；Network中edge是作为唯一的一等对象存在的，与node的地位相同，如果边对象是唯一的（并行边）使用netwrok。
## Building graph instances
common.graph中的实现类都不是public的，开发者不需要了解太多的public类，用户不需要考虑那么多就可以得到内置实现提供的各种功能。为了创建一个图接口实现的实例对象，需要使用对应的Builder类，GraphBuilder、ValueGraphBuilder或者NetworkBuilder类，下面的例子:
```java
// Creating mutable graphs
MutableGraph<Integer> graph = GraphBuilder.undirected().build();

MutableValueGraph<City, Distance> roads = ValueGraphBuilder.directed()
    .incidentEdgeOrder(ElementOrder.stable())
    .build();

MutableNetwork<Webpage, Link> webSnapshot = NetworkBuilder.directed()
    .allowsParallelEdges(true)
    .nodeOrder(ElementOrder.natural())
    .expectedNodeCount(100000)
    .expectedEdgeCount(1000000)
    .build();

// Creating an immutable graph
ImmutableGraph<Country> countryAdjacencyGraph =
    GraphBuilder.undirected()
        .<Country>immutable()
        .putEdge(FRANCE, GERMANY)
        .putEdge(FRANCE, BELGIUM)
        .putEdge(GERMANY, BELGIUM)
        .addNode(ICELAND)
        .build();
```
- 2种方式得到Builder对象
* 调用静态方法directed()与undirected();
* 调用静态方法from()基于一个已经存在图形实例来创建Builder;
- 创建Builder对象后，可以指定其他特性与能力;
- 创建可变图
* 调用build()，调用一次就就创建一个图实例;
* build()方法返回图的Mutable子类型;
- 创建不可变图:
* 调用immutable()创建ImmutableGraph.Builder实例;
* 需要在immutable()方法上指定范型类型;
Builder 类型通常提供两种类型的选项：约束和优化提示。约束指定给定 Builder 实例创建的图必须满足的行为和属性，例如：
- 图是否有向
- 此图是否允许自循环
- 此图的边是否已排序
等等。实现类可以选择使用优化提示来提高效率，例如，确定内部数据结构的类型或初始大小。 它们不保证有任何效果。每种图类型都提供与其 Builder 指定的约束对应的访问器，但不提供优化提示的访问器。
## Mutable and Immutable graphs
1. Mutable* types
每种图形类型都有对应的Mutable*子类型:
- MutableGraph;
- MutableValueGraph;
- MutableNetwork;
这些子类型都定义了变更方法:
- 添加或者移除节点的方法addNode, removeNode
- 添加或者移除边的方法:
* MutableGraph: putEdge、removeEdge;
* MutableValueGraph: putsEdgeValue、removeEdge;
* MutableNetwork: addEdge、removeEdge;
这与以前的Java 集合框（以及Guava的新集合类型）不同；Java集合类型中的每一种都包含变更方法的签名，我们选择将变更方法签名放到子类型中，部分原因是为了实现防御性编程，一般来说，如果你的代码只是检查或者遍历图，那么不需要变更的操作，那么你的代码中的图应该是Graph、ValueGraph或者Network而不是他们的子类型，另一方面，如果你的代码需要操作对象，那么你的代码需要使用Mutable类型的数据。
因为Graph是接口，虽然它不包含变更方法，但是也不能保证不会被修改，因为它也可能是Mutable子类型的，如果你想要Graph不可变更，那么Graph的实际实例必须是Immutable的相关实现。
2. Immutable*实现
每个图形类型都有对应的Immutable的实现，这些实现类似于Guava的ImmutableSet、ImmutableList、ImmutableMap等类型，一旦构造后，不能更改，实现类内部使用了高效的Immutable数据结构。与其他的Guava Immmutable类型不同，图形实现没有任何的变更方法的签名，所以它们不会在尝试调用变更方法时抛出UnsupportOperationException。你可以通过2种方式创建ImmutableGraph的实例:
- 使用GraphBuilder
```java
ImmutableGraph<Country> immutableGraph1 =
    GraphBuilder.undirected()
        .<Country>immutable()
        .putEdge(FRANCE, GERMANY)
        .putEdge(FRANCE, BELGIUM)
        .putEdge(GERMANY, BELGIUM)
        .addNode(ICELAND)
        .build();
```
- 使用ImmutableGraph.copyOf()；
```java
ImmutableGraph<Integer> immutableGraph2 = ImmutableGraph.copyOf(otherGraph);
```
不可变图始终保证提供稳定的事件边顺序。 如果使用GraphBuilder填充图形，则事件边顺序将尽可能是插入顺序（有关详细信息，请参阅ElementOrder.stable()）。 当使用copyOf时，事件边的顺序将是它们在复制过程中被访问的顺序。
每个Immutable类型都保证:
- 浅不变: 不能添加、移除、替换元素;
- 确定性迭代: 迭代顺序始终是确定的;
- 线程安全: 并发访问线程时是安全的;
- 透明性: Immutable的实现是隐藏的，而且不可能是Guava外部的实现;
最好把这些类当作借口而不是实现者看待。每一个Immutable类都提供了上述有意义的行为保证而不仅仅是一个特定实现，所以，你需要把他们视为接口。引用Immutable* 实例（如ImmutableGraph）的字段和方法返回值应声明为Immutable*类型，而不是相应的接口类型（如Graph）。这向调用者传达了上面列出的所有语义保证，这几乎总是非常有用的信息。另一方面，ImmutableGraph类型的参数对于调用者来说不是很方便，相反应该声明为Graph类型。
**警告**: 如其他地方所述，修改Graph中的元素的内容是一个坏主意（影响equals），这将导致未定义的行为与错误，最好不要使用可变更的对象作为Immutbable实例中的元素因为用户可能希望ImmutableGraph是深不变的而不是浅不变。
## Graph元素(节点与边)
1. 元素必须可以用作Map的key
开发者提供的图元素应该被认为是插入到Graph实现中维护的内部数据结构的key，因此，元素必须有equals()与hashCode()方法，2个方法必须具有如下的特点
- Uniqueness: 如果A与B满足A.equals(B) == true，2个对象中只有一个会成为图的元素;
- Consistency between hashCode() and equals(): hashCode与equals()的一致性要与Object.hashCode()一样;
- Ordering consistency with equals(): 如果节点是有序的，排序必须与equals一致，定义在Comparator与Comparable中;
- Non-recursiveness: hashCode()和equals()不得递归引用其他元素，如下例所示:
```java
// DON'T use a class like this as a graph element (or Map key/Set element)
public final class Node<T> {
  T value;
  Set<Node<T>> successors;

  public boolean equals(Object o) {
    Node<T> other = (Node<T>) o;
    return Objects.equals(value, other.value)
        && Objects.equals(successors, other.successors);
  }

  public int hashCode() {
    return Objects.hash(value, successors);
  }
}
```
使用这样的类作为common.graph的元素(Graph<Node<T>>)会有以下的问题:
- redundancy(冗余): Graph实现已经存储了元素关系;
- inefficiency(低效): 添加或者访问元素会调用equals或者hashCode方法，方法会消耗O(n)复杂度;
- infeasibility(不可行): 如果在Graph存在还，equals与hashCode的调用将永远不会终止;
相反，应该使用T类型的value本身作为元素类型，建设Tvalue本身是有效的Map key。如果元素状态是可变的:
- 可变状态不能出现在equals()与hashCode()方法中;
- 不要构造多个彼此相等的元素并期望它们可以互换，特别是，当添加这样的元素到graph中时，你只需要创建元素一次，然后存储元素的引用方面后面构造图的关系数据等时使用而不是每次用时都new新的对象。如果你存储每个元素相关的可变的状态，一个办法时使用不可变元素，当时把可变状态存储到其他数据结构中，比如(element-to-state map)。元素不能为null。
## Library constracts and behaviors
这一节common.graph类型内置实现的一些行为.
1. Mutation
你可以添加边，即使边相关的节点之前还没添加到图中，如果node没在图中，此时会被添加到图中；
```java
Graph<Integer> graph = GraphBuilder.directed().build();  // graph is empty
graph.putEdge(1, 2);  // this adds 1 and 2 as nodes of this graph, and puts
                      // an edge between them
if (graph.nodes().contains(1)) {  // evaluates to "true"
  ...
}
```
2. Graph equals() and graph equivalence
从Guava 22开始，common.graph的图类型都定义了有意义的equals方法
- Graph.equals()定义了只有在2个图中的所有的节点与边一样，并且边的端点与边的方向也一样的情况下，2个graph相等;
- ValueGraph.equals()只有在2个图中的所有的节点与边一样，并且边的端点与边的方向与权重也一样的情况下，2个graph相等;
- Network.equals()定义了只有在2个图中的所有的节点与边一样，并且边的端点与边的方向一样的情况下，2个graph相等;
另外，对于每种graph类型，只用变得类型完全相同图才可以判断相等，也就是都是有向图或者都是无向图。如果你只想根据连接性比较2个Network或者2个ValueGraph或者将Netwrok、ValueGraph与Graph比较，你只需要使用ValueGraph与Network提供的asGraph的返回结果用于比较就可以
```java
Graph<Integer> graph1, graph2;
ValueGraph<Integer, Double> valueGraph1, valueGraph2;
Network<Integer, MyEdge> network1, network2;

// compare based on nodes and node relationships only
if (graph1.equals(graph2)) { ... }
if (valueGraph1.asGraph().equals(valueGraph2.asGraph())) { ... }
if (network1.asGraph().equals(graph1.asGraph())) { ... }

// compare based on nodes, node relationships, and edge values
if (valueGraph1.equals(valueGraph2)) { ... }

// compare based on nodes, node relationships, and edge identities
if (network1.equals(network2)) { ... }
```
3. Accessor（读）方法
返回集合的访问器读方法:
- 可能返回Graph的视图形式，此时对Graph的变更会影响到视图的访问(比如在迭代nodes()的过程中调用addNode或者removeNode)，变更是不支持的，可能会造成ConcurrentModificationException.
- 可能返回空的集合（比如adjacentNode(node)当node没有临接节点时可能返回空）
如果传的参数没在Graph中，那么读方法会抛出IllegalArgumentException异常。
4. Sychronization
Graph的实现自己决定自己的并发策略，默认情况下，并发访问/变更同一个图可能造成未定义的行为。通常来说，内置的可变更实现图没有提供线程安全保证，Immutable类型的图天然线程安全.
5. Element objects
node、edge、权重可以是任何类型与图的内部实现没有任何关系，它们只是作为内部数据结构的key，nodes/edges对象可以被多个graph实例使用。默认情况下，node与edge对象是插入排序的，也就是说，当迭代nodes()或者edges()时，是以插入顺序迭代的，就像是LinkedHashSet。
## Notes for implementors
1. 存储模型
common.graph支持多种方式来存储graph的拓扑结构，包括:
- Graph实现类存储了拓扑(通过Map<N,Set<N>存储node与node的临接节点，这意味着nodes只是作为key，多个graph中可使用同一个node);
- node存储拓扑(比如通过一个List<E>的字段存储临接节点)，这意味着节点是特定图相关的;
- 一个额外的数据存储(比如数据库)存储拓扑;
对于支持孤立节点（没有关联边的节点）的 Graph 实现来说，Multimap 的内部数据结构不够充分，因为它们的限制是键要么映射到至少一个值，要么不存在于 Multimap 中。
2. 读操作(Accessor行为)
对于返回集合的accessors:
- 返回的集合是immutable拷贝(比如: ImmutableSet)，尝试修改集合会造成异常，并且对图的修改不会反映在集合中（因为是拷贝）;
- 返回的集合是unmodifiable视图（例如 Collections.unmodifiableSet()），尝试以任何方式修改集合都会抛出异常，并且对图的修改将反映在集合中（因为是视图）;
- 返回mutable拷贝, 它可能会被修改，但对集合的修改不会反映在图表中，反之亦然(因为是拷贝);
- 返回modifiable视图，它可以被修改，对集合的修改会反映在图中，反之亦然;
理论上来说，可以返回一个集合，这个集合可以通过集合变更或者通过Graph变更，但是这可能没什么用.(1),(2)是更建议的方式，对于写入来说，内置实现通常使用(2)。(3)也可以，但是会对用户产生疑惑，因为对集合或者graph的修改没有反映到另一方;(4)是危险的设计，使用时要特别注意，很难保持内部数据结构的一致性。
3. Abstract*类
每个图类型都有对应的Abstract类，比如AbstractGraph，图接口的实现最好尽可能继承合适的抽象类，不要直接实现接口，抽象类里面包含了很多关于key的方法，可以直接使用。
## Code Examples
- node是否在graph中
```java
graph.nodes().contains(node);
```
- 是否存在u到v的边
```java
// This is the preferred syntax since 23.0 for all graph types.
graphs.hasEdgeConnecting(u, v);

// These are equivalent (to each other and to the above expression).
graph.successors(u).contains(v);
graph.predecessors(v).contains(u);

// This is equivalent to the expressions above if the graph is undirected.
graph.adjacentNodes(u).contains(v);

// This works only for Networks.
!network.edgesConnecting(u, v).isEmpty();

// This works only if "network" has at most a single edge connecting u to v.
network.edgeConnecting(u, v).isPresent();  // Java 8 only
network.edgeConnectingOrNull(u, v) != null;

// These work only for ValueGraphs.
valueGraph.edgeValue(u, v).isPresent();  // Java 8 only
valueGraph.edgeValueOrDefault(u, v, null) != null;
```
- Graph
```java
ImmutableGraph<Integer> graph =
    GraphBuilder.directed()
        .<Integer>immutable()
        .addNode(1)
        .putEdge(2, 3) // also adds nodes 2 and 3 if not already present
        .putEdge(2, 3) // no effect; Graph does not support parallel edges
        .build();

Set<Integer> successorsOfTwo = graph.successors(2); // returns {3}
```
- ValueGraph
```java
MutableValueGraph<Integer, Double> weightedGraph = ValueGraphBuilder.directed().build();
weightedGraph.addNode(1);
weightedGraph.putEdgeValue(2, 3, 1.5);  // also adds nodes 2 and 3 if not already present
weightedGraph.putEdgeValue(3, 5, 1.5);  // edge values (like Map values) need not be unique
...
weightedGraph.putEdgeValue(2, 3, 2.0);  // updates the value for (2,3) to 2.0
```
- Network
```java
MutableNetwork<Integer, String> network = NetworkBuilder.directed().build();
network.addNode(1);
network.addEdge("2->3", 2, 3);  // also adds nodes 2 and 3 if not already present

Set<Integer> successorsOfTwo = network.successors(2);  // returns {3}
Set<String> outEdgesOfTwo = network.outEdges(2);   // returns {"2->3"}

network.addEdge("2->3 too", 2, 3);  // throws; Network disallows parallel edges
                                    // by default
network.addEdge("2->3", 2, 3);  // no effect; this edge is already present
                                // and connecting these nodes in this order

Set<String> inEdgesOfFour = network.inEdges(4); // throws; node not in graph
```
- 遍历无向图
```java
// Return all nodes reachable by traversing 2 edges starting from "node"
// (ignoring edge direction and edge weights, if any, and not including "node").
Set<N> getTwoHopNeighbors(Graph<N> graph, N node) {
  Set<N> twoHopNeighbors = new HashSet<>();
  for (N neighbor : graph.adjacentNodes(node)) {
    twoHopNeighbors.addAll(graph.adjacentNodes(neighbor));
  }
  twoHopNeighbors.remove(node);
  return twoHopNeighbors;
}
```
- 遍历有向图
```java
// Update the shortest-path weighted distances of the successors to "node"
// in a directed Network (inner loop of Dijkstra's algorithm)
// given a known distance for {@code node} stored in a {@code Map<N, Double>},
// and a {@code Function<E, Double>} for retrieving a weight for an edge.
void updateDistancesFrom(Network<N, E> network, N node) {
  double nodeDistance = distances.get(node);
  for (E outEdge : network.outEdges(node)) {
    N target = network.target(outEdge);
    double targetDistance = nodeDistance + edgeWeights.apply(outEdge);
    if (targetDistance < distances.getOrDefault(target, Double.MAX_VALUE)) {
      distances.put(target, targetDistance);
    }
  }
}
```
## FAQ
- why did guava introduce common.graph
与 Guava 所做的许多其他事情一样，同样的论点适用于图形:
* 代码重用/互操作性/范式统一：很多事情都与图形处理有关
* 效率：有多少代码使用了低效的图形表示？ 太多的空间（例如矩阵表示）？
* 正确性：有多少代码在做图分析错误？
* 促进使用图形作为 ADT：如果图形很容易，有多少人会使用图形？
* 简单性：如果明确使用该隐喻，处理图形的代码更容易理解。
