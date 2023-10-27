一个库，实现了脚本特性。JEXL实现了一个基于JSTL EL扩展的EL。支持以shell或者ECMA-Script的方式构造表达式。其目标是暴露可供企业平台的技术人员或顾问使用的脚本接口。在许多案例中，JEXL允许应用程序的最终用户编写自己的脚本或表达式，并确保其在受控约束内执行。库暴露了较少的API。核心特性在3个class内与10个方法中。可以用在不同的环境下:
- 脚本特性:
  - 应用可以让用户定义或者求值简单的表达式
- Module or component configuration:
  - 应用的配置文件，最用有最终用户模块处理，这可能会受益于变量与表达式
  - 方便实现IOC不需要复杂的完整的框架，比如Spring、Guice
- Loose-coupling of interfaces and implementations or duck-typing:
  - 编写了可选类，不一定要编译处理
  - You have to integrate and call "legacy" code or use components that you don't want to strongly depend upon
- 简单的模板能力
  - Your application has basic template requirements and JSPs or Velocity would be overkill or too inconvenient to deploy.

JEXL的名字表示Java EXpression Language。一个简单的EL，收到了Apache Velocity、JSTL 1.1中EL规范、JSP2.0规范的启发。JEXL2.0支持统一EL。语法类似ECMAScript与shell的混合。让他容易编写。API与EL使用了固定的Java命名模式，也就是暴露属性的getter/setter。属性声明为public也会参与计算。允许调用任意的可调用的方法。
# A Detailed Example
为了创建一个表达式或者脚本，需要一个`JexlEngine`。为了实例化一个，需要创建一个`JexlBuilder`，它用来描述`JexlPermissions`与`JexlFeatures`。这会决定表达式可以访问或者调用哪些类或者哪些方法以及表达式可以使用哪些语法元素。不要忽视这个配置。尤其是你的应用的安全权限可能依赖这个。一旦构建，JEXL引擎就会存储、共享与复用这些配置。它是线程安全的，表达式在求值过程中也是线程安全的。当求值时，JEXL将`JexlExpression`或者`JexlScript`与`JexlContext`合并。在最简单的形势下，使用`JexlEngine#createExpression()`创建脚本或者表达式。参数是一个有效的JEXL语法的字符串。最简单的JexlContext可以通过一个MapContext实例化。内部维护了一个map变量。JEXL的目的是与其托管平台紧密集成；脚本语法非常接近JScript，但（可能）利用Java暴露的任何公共类或方法。这种整合的紧密程度和丰富程度取决于您；派生JEXL API 类，最重要的是`JexlPermissions`、`JexlContext`、`JexlArithmetic`是实现这一目标的手段。
```java
/**
 * A test around scripting streams.
 */
public class StreamTest {
    /** Our engine instance. */
    private final JexlEngine jexl;

    public StreamTest() {
        // Restricting features; no loops, no side effects
        JexlFeatures features = new JexlFeatures()
                .loops(false)
                .sideEffectGlobal(false)
                .sideEffect(false);
        // Restricted permissions to a safe set but with URI allowed
        JexlPermissions permissions = new ClassPermissions(java.net.URI.class);
        // Create the engine
        jexl = new JexlBuilder().features(features).permissions(permissions).create();
    }

    /**
     * A MapContext that can operate on streams.
     */
    public static class StreamContext extends MapContext {
        /**
         * This allows using a JEXL lambda as a mapper.
         * @param stream the stream
         * @param mapper the lambda to use as mapper
         * @return the mapped stream
         */
        public Stream<?> map(Stream<?> stream, final JexlScript mapper) {
            return stream.map( x -> mapper.execute(this, x));
        }

        /**
         * This allows using a JEXL lambda as a filter.
         * @param stream the stream
         * @param filter the lambda to use as filter
         * @return the filtered stream
         */
        public Stream<?> filter(Stream<?> stream, final JexlScript filter) {
            return stream.filter(x -> x =! null && TRUE.equals(filter.execute(this, x)));
        }
    }

    @Test
    public void testURIStream() throws Exception {
        // let's assume a collection of uris need to be processed and transformed to be simplified ;
        // we want only http/https ones, only the host part and forcing an https scheme
        List<URI> uris = Arrays.asList(
                URI.create("http://user@www.apache.org:8000?qry=true"),
                URI.create("https://commons.apache.org/releases/prepare.html"),
                URI.create("mailto:henrib@apache.org")
        );
        // Create the test control, the expected result of our script evaluation
        List<?> control =  uris.stream()
                .map(uri -> uri.getScheme().startsWith("http")? "https://" + uri.getHost() : null)
                .filter(x -> x != null)
                .collect(Collectors.toList());
        Assert.assertEquals(2, control.size());

        // Create scripts:
        // uri is the name of the variable used as parameter; the beans are exposed as properties
        // note the starts-with operator =^
        // note that uri is also used in the back-quoted string that performs variable interpolation
        JexlScript mapper = jexl.createScript("uri.scheme =^ 'http'? `https://${uri.host}` : null", "uri");
        // using the bang-bang / !! - JScript like -  is the way to coerce to boolean in the filter
        JexlScript transform = jexl.createScript(
                "list.stream().map(mapper).filter(x -> !!x).collect(Collectors.toList())", "list");

        // Execute scripts:
        JexlContext sctxt = new StreamContext();
        // expose the static methods of Collectors; java.util.* is allowed by permissions
        sctxt.set("Collectors", Collectors.class);
        // expose the mapper script as a global variable in the context
        sctxt.set("mapper", mapper);

        Object transformed = transform.execute(sctxt, uris);
        Assert.assertTrue(transformed instanceof List<?>);
        Assert.assertEquals(control, transformed);
    }
}
```