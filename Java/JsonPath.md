# Getting Started
JsonPath库在Maven中央仓库中，需要提前添加:
```xml
<dependency>
    <groupId>com.jayway.jsonpath</groupId>
    <artifactId>json-path</artifactId>
    <version>2.8.0</version>
</dependency>
```
JsonPath始终表示一个JSON文档中的结构，工作方式类似XPath与XML。JsonPath中的根对象始终用`$`表示，不论对象是对象还是数组。JsonPath表达式使用点号标记`$.store.book[0].title`或者括号标记`$['store']['book'][0]['title']`
# Operators
|Operator|Description|
|:---|:---|
|$|根对象，是所有路径表达式的开始标记|
|@|谓词filter正在处理的当前节点|
|*|通配符，匹配任意的名字或者数组|
|..|深度扫描，表示任意名字|
|`.<name>`|点号标记的子节点|
|`['<name>' (, '<name>')]`|括号标记的子节点|
|`[<number> (, <number>)]`|数组下标|
|`[start:end]`|数组切片|
|`[?(<expression>)]`|filter表达式，表达式的值必须是一个boolean值|
# Functions
函数可以在path的最后调用，函数的输入是path表达式的输出，函数输出是函数本身定义的。
|Function|Description|Output type|
|:---|:---|:---|
|min()|数字数组的最小值|Double|
|max()|数字数组的最大值|Double|
|avg()|数字数组的平均值|Double|
|stddev()|数字数组的标准差|Double|
|length()|数组的长度|Integer|
|sum()|数字数组的总和|Double|
|keys()|属性的key|Set|
|concat(X)|使用X连接输出|类似输入|
|append(X)|添加一个新的元素到输出的数组|input|
|first()|数组的第一个元素||
|last()|数组的最后一个元素||
|index(X)|数组下标X处的元素||

过滤器是逻辑表达式，用来过滤数组元素。典型的过滤器类似`[?(@.age > 18)]`，在这个表达式里面，`@`符号表示当前正被处理的元素，更复杂的过滤器可以通过逻辑运算符`&&`与`||`来组合。纯文本要用单引号或者双引号包起来`[?(@.color == 'blue')]`或者`[?(@.color == "blue")]`。
|Operator|Description|
|:---|:---|
|==|等于|
|!=|不等于|
|<|小于|
|<=|小于等于|
|>|大于|
|>=|大于等于|
|=~|匹配正则表达式|
|in|存在`[?(@.size in ['S', 'M'])]`|
|nin|不存在|
|subsetof|是子集`[?(@.sizes subsetof ['S', 'M', 'L'])]`|
|anyof|交集不为空`[?(@.sizes anyof ['M', 'L'])]`|
|noneof|交集为空` [?(@.sizes noneof ['M', 'L'])]`|
|size|数组或者字符串的长度要匹配|
|empty|数组或者字符串为空|
# Path Examples
```json
{
    "store": {
        "book": [
            {
                "category": "reference",
                "author": "Nigel Rees",
                "title": "Sayings of the Century",
                "price": 8.95
            },
            {
                "category": "fiction",
                "author": "Evelyn Waugh",
                "title": "Sword of Honour",
                "price": 12.99
            },
            {
                "category": "fiction",
                "author": "Herman Melville",
                "title": "Moby Dick",
                "isbn": "0-553-21311-3",
                "price": 8.99
            },
            {
                "category": "fiction",
                "author": "J. R. R. Tolkien",
                "title": "The Lord of the Rings",
                "isbn": "0-395-19395-8",
                "price": 22.99
            }
        ],
        "bicycle": {
            "color": "red",
            "price": 19.95
        }
    },
    "expensive": 10
}
```
|JsonPath|Result|
|:---|:---|
|$.store.book[*].author|所有书的作者|
|$..author|所有的作者|
|$.store.*|All things, both books and bicycles|
|$.store..price|The price of everything|
|$..book[2]|The third book|
|$..book[-2]|The second to last book|
|$..book[0,1]|The first two books|
|$..book[:2]|All books from index 0 (inclusive) until index 2 (exclusive)|
|$..book[1:2]|All books from index 1 (inclusive) until index 2 (exclusive)|
|$..book[-2:]|Last two books|
|$..book[2:]|All books from index 2 (inclusive) to last|
|$..book[?(@.isbn)]|All books with an ISBN number|
|$.store.book[?(@.price < 10)]|All books in store cheaper than 10|
|$..book[?(@.price &lt;= $['expensive'])]|ll books in store that are not "expensive"|
|$..book[?(@.author =~ /.*REES/i)]|All books matching regex (ignore case)|
|$..*|Give me every thing|
|$..book.length()|The number of books|

# Reading a Document
最简单的方式是使用静态read API
```java
String json = "...";
List<String> authors = JsonPath.read(json, "$.store.book[*].author");
```
如果你只需要读一次，那么这种方式是OK的，如果要处理多次，那么每次read都要解析json文档，你可以只解析一次
```java
String json = "...";
Object document = Configuration.defaultConfiguration().jsonProvider().parse(json);
String author0 = JsonPath.read(document, "$.store.book[0].author");
String author1 = JsonPath.read(document, "$.store.book[1].author");
```
JsonPath也提供了流式API
```java
String json = "...";
ReadContext ctx = JsonPath.parse(json);
List<String> authorsOfBooksWithISBN = ctx.read("$.store.book[?(@.isbn)].author");
List<Map<String, Object>> expensiveBooks = JsonPath
                            .using(configuration)
                            .parse(json)
                            .read("$.store.book[?(@.price > 10)]", List.class);
```
# What is Returned When
使用Java时，你想获得预期的数据类型的结果，JsonPath将会自动将结果转型为你预期的类型
```java
//Will throw an java.lang.ClassCastException    
List<String> list = JsonPath.parse(json).read("$.store.book[0].author")

//Works fine
String author = JsonPath.parse(json).read("$.store.book[0].author")
```
当计算路径时，有2个概念要清楚
- 明确的路径
- 不明确的路径
  - .. 深度扫描
  - ?(expression)逻辑表达式
  - [number,number,number]多个数组索引

不明确的路径始终返回list。这是由当前的JsonProvider提供的。默认的情况下，MappingProvider SPI提供了一个简单的对象mapper。你可以指定你想要的返回类型，MappingProvider江湖i执行这个映射，下面的例子展示了如何再Long与Date类型之间做映射
```java
String json = "{\"date_as_long\" : 1411455611975}";

Date date = JsonPath.parse(json).read("$['date_as_long']", Date.class);
```
如果你配置JsonPath使用`JacksonMappingProvider`，`GsonMappingProvider`，`JakartaJsonProvider`，你可以在json结果与普通的POJO之间做映射，如下:
```java
Book book = JsonPath.parse(json).read("$.store.book[0]", Book.class);
```
为了得到全部的泛型信息:
```java
TypeRef<List<String>> typeRef = new TypeRef<List<String>>() {};

List<String> titles = JsonPath.parse(JSON_DOCUMENT).read("$.store.book[*].title", typeRef);
```
# Predicates
有3种创建filter谓词的方式
- Inline Predicates，在path中定义的
  ```java
  List<Map<String, Object>> books =  JsonPath.parse(json)
                                     .read("$.store.book[?(@.price < 10)]");
  ```
  你可以使用`&&`与`||`来组合多个谓词，`[?(@.price < 10 && @.category == 'fiction')] , [?(@.category == 'reference' || @.price > 10)]`，你可以使用`!`来否定谓词`[?(!(@.price < 10 && @.category == 'fiction'))]`
- Filter predicates，使用Filter API来构建
  ```java
  import static com.jayway.jsonpath.JsonPath.parse;
    import static com.jayway.jsonpath.Criteria.where;
    import static com.jayway.jsonpath.Filter.filter;
    ...
    ...
    Filter cheapFictionFilter = filter(
   where("category").is("fiction").and("price").lte(10D)
    );
    List<Map<String, Object>> books =  
   parse(json).read("$.store.book[?]", cheapFictionFilter);
  ```
  注意占位符`?`表示filter应该在的位置，当存在多个filter谓词时，他们按照占位符出现的顺序填充。占位符与filter谓词的数量要匹配。也可也在一个filter操作中指定多个谓词，他们是AND的关系`[?,?]`
  ```java
  Filter fooOrBar = filter(
   where("foo").exists(true)).or(where("bar").exists(true)
    );
   
    Filter fooAndBar = filter(
    where("foo").exists(true)).and(where("bar").exists(true)
    );
  ```
- Roll Your Own，第三个方式是自定义谓词
  ```java
  Predicate booksWithISBN = new Predicate() {
    @Override
    public boolean apply(PredicateContext ctx) {
        return ctx.item(Map.class).containsKey("isbn");
    }
    };

    List<Map<String, Object>> books = 
   reader.read("$.store.book[?].isbn", List.class, booksWithISBN);
  ```
# Path vs Value
在Goessner的实现中，JsonPath也可以返回Path或者Value，默认返回Value，上面所有的例子都是返回Value，如果要返回path可以这么做:
```java
Configuration conf = Configuration.builder()
   .options(Option.AS_PATH_LIST).build();

List<String> pathList = using(conf).parse(json).read("$..author");

assertThat(pathList).containsExactly(
    "$['store']['book'][0]['author']",
    "$['store']['book'][1]['author']",
    "$['store']['book'][2]['author']",
    "$['store']['book'][3]['author']");
```
# Set a Value
也可以设置json元素的值
```java
String newJson = JsonPath.parse(json).set("$['store']['book'][0]['author']", "Paul").jsonString();
```
# Tweaking Configuration
## Options
有一个配置选项可以改变默认的行为
- DEFAULT_PATH_LEAF_TO_NULL，JsonPath对不存在的path返回null,考虑下面的json
  ```json
  [
   {
      "name" : "john",
      "gender" : "male"
   },
   {
      "name" : "ben"
   }
  ]
  ```
  ```java
  Configuration conf = Configuration.defaultConfiguration();

  //Works fine
  String gender0 = JsonPath.using(conf).parse(json).read("$[0]['gender']");
  //PathNotFoundException thrown
  String gender1 = JsonPath.using(conf).parse(json).read("$[1]['gender']");

  Configuration conf2 = conf.addOptions(Option.DEFAULT_PATH_LEAF_TO_NULL);

  //Works fine
  String gender0 = JsonPath.using(conf2).parse(json).read("$[0]['gender']");
  //Works fine (null is returned)
  String gender1 = JsonPath.using(conf2).parse(json).read("$[1]['gender']");
  ```
- ALWAYS_RETURN_LIST，始终返回list
  ```java
  Configuration conf = Configuration.defaultConfiguration();

  //ClassCastException thrown
  List<String> genders0 = JsonPath.using(conf).parse(json).read("$[0]['gender']");
  Configuration conf2 = conf.addOptions(Option.ALWAYS_RETURN_LIST);
  //Works fine
  List<String> genders0 = JsonPath.using(conf2).parse(json).read("$[0]['gender']");
  ```
- SUPPRESS_EXCEPTIONS，异常会被被传递，如果设置了ALWAYS_RETURN_LIST，返回空list，如果没有返回null
- REQUIRE_PROPERTIES，当计算indefinite路径时，路径上需要属性名
  ```java
  Configuration conf = Configuration.defaultConfiguration();
  //Works fine
  List<String> genders = JsonPath.using(conf).parse(json).read("$[*]['gender']");
  Configuration conf2 = conf.addOptions(Option.REQUIRE_PROPERTIES);
  //PathNotFoundException thrown
  List<String> genders = JsonPath.using(conf2).parse(json).read("$[*]['gender']");
  ```
# JsonProvider SPI
JsonPath打包了5个不同的JsonProviders:
- [JsonSmartJsonProvider](https://github.com/netplex/json-smart-v2)(default)
- [JacksonJsonProvider](https://github.com/FasterXML/jackson)
- [JacksonJsonNodeJsonProvider](https://github.com/FasterXML/jackson)
- [GsonJsonProvider](https://code.google.com/p/google-gson/)
- [JsonOrgjsonProvider](https://github.com/stleary/JSON-java)
- [JakataJsonProvider](https://javaee.github.io/jsonp/)

改变默认的配置应该在应用程序初始化时完成，不建议在运行时修改。
```java
Configuration.setDefaults(new Configuration.Defaults() {

    private final JsonProvider jsonProvider = new JacksonJsonProvider();
    private final MappingProvider mappingProvider = new JacksonMappingProvider();
      
    @Override
    public JsonProvider jsonProvider() {
        return jsonProvider;
    }

    @Override
    public MappingProvider mappingProvider() {
        return mappingProvider;
    }
    
    @Override
    public Set<Option> options() {
        return EnumSet.noneOf(Option.class);
    }
});
```
# Cache SPI
JsonPath 2.1.0引入了一个新的Cache SPI机制。这允许使用者自定义配置路径缓存。Cache必须在JsonPath第一次访问前配置，JsonPath打包了2个Cache实现
- com.jayway.jsonpath.spi.cache.LRUCache，默认的，线程安全的
- com.jayway.jsonpath.spi.cache.NOOPCache，mo cache
自己实现
```java
CacheProvider.setCache(new Cache() {
    //Not thread safe simple cache
    private Map<String, JsonPath> map = new HashMap<String, JsonPath>();

    @Override
    public JsonPath get(String key) {
        return map.get(key);
    }

    @Override
    public void put(String key, JsonPath jsonPath) {
        map.put(key, jsonPath);
    }
});
```