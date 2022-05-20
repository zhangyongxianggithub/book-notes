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

