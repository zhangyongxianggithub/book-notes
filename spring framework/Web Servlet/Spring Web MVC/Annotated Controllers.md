# 异常处理
`@Controller/@ControllerAdvice`类可以使用`@ExceptionHandler`方法来处理controller方法抛出的异常。正如下面的例子所示:
```java
@Controller
public class SimpleController {
    // ...
    @ExceptionHandler
    public ResponseEntity<String> handle(IOException ex) {
        // ...
    }
}
```
异常可以匹配抛出的异常栈内的所有异常，也就是能匹配上直接异常与内嵌的cause异常。比如IOException异常被包含在IllegalStateException异常内。从5.3版本之后才具有这个特性，之前的版本只会匹配直接异常。为了匹配异常，最好将目标异常类型声明为一个方法参数。如上面的例子所示，当匹配多个异常处理方法时，直接异常匹配比内嵌异常匹配具有更高的优先级。更具体的说，`ExceptionDepthComparator`就是用来对异常排序，这是基于抛出的异常栈来排序。或者，注解可以声明匹配多个异常类型，如下面的例子所示:
```java
@ExceptionHandler({FileSystemException.class, RemoteException.class})
public ResponseEntity<String> handle(IOException ex) {
    // ...
}
```
你还可以使用一个特定的异常类型列表，这些异常具有共同的父类型异常，可以将父类型异常作为参数签名。如下面的例子所示:
```java
@ExceptionHandler({FileSystemException.class, RemoteException.class})
public ResponseEntity<String> handle(Exception ex) {
    // ...
}
```
直接异常匹配和内嵌异常匹配之间的区别可能令人惊讶。在前面显示的`IOException`变体例子中，方法调用时使用的实际参数是`FileSystemException`或`RemoteException`异常实例，因为它们都是从`IOException`继承而来的。但是，如果包含`IOException`异常的包装器异常在执行异常匹配时，传入的异常实例就是包装器异常。`handle(Exception)`变体例子中的行为甚至更简单。这个异常处理总是直接处理包装器异常，在这种情况下可以通过`ex.getCause()`找到实际匹配的异常。只有当`FileSystemException`或`RemoteException`实例作为直接异常抛出时，传入的异常才是实际的`FileSystemException`或`RemoteException`实例。

我们通常建议你在参数签名使用尽可能具体的异常类型。减少直接异常和内嵌异常类型之间不匹配的可能性。考虑将一个多重匹配方法分解为多个单独的`@ExceptionHandler`异常方法，每个异常方法通过其签名匹配一个具体的异常类型。在具有多个`@ControllerAdvice`的应用中，我们建议在具有您想要的顺序优先级的@ControllerAdvice上声明您的主要直接异常方法。在单一的控制器或`@ControllerAdvice`类的范围内，直接异常匹配优先于内嵌异常匹配。 这意味着高优先级`@ControllerAdvice`Bean上的异常匹配优先于低优先级`@ControllerAdvice`Bean上的任何匹配。最后，`@ExceptionHandler`方法实现可以选择直接抛出原始异常。重新抛出的异常通过剩余的解析链传播，就好像给定的`@ExceptionHandler`方法一开始就不会匹配一样。Spring框架使用`HandlerExceptionResolver`机制支持`@ExceptionHandler`。
## 方法参数
@ExceptionHandler方法支持下面的参数
|方法参数|描述|
|:---|:---|
|Exception类型|产生的异常引用|
|HandlerMethod|抛出异常的Controller方法引用|
|WebRequest,NativeWebRequest|用于访问请求参数，请求，session属性|
|ServletRequest,ServletResponse|Request/response类型|
|HttpSession|强制生成一个session，所以这样的参数永远不是null，注意，session不是线程安全的，如果要并发访问，需要设置`RequestMappingHandlerAdapter`的`synchronizeOnSession=true`|
|Principal|当前认证的用户|
|HttpMethod|HTTP method|
|Locale|当前请求产生的区域，由`LocaleResolver`生成|
|TimeZone,ZoneId|时区|	
|OutputStream,Writer|raw response body输出流|	
|Map/Model/ModelMap|一个error response的model|
|RedirectAttributes|指定重定向时要使用的属性|
|@SessionAttribute|访问session属性|
|@RequestAttribute|For access to request attributes. See @RequestAttribute for more details.|
## 返回值
|Return value|描述|
|:---|:---|
|@ResponseBody|返回值通过HttpMessageConverter实例转换后写到response，可以看[@ResponseBody](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responsebody)部分的详细介绍|
|HttpEntity<T>，ResponseEntity<T>|返回的值描述了完整的响应，包含header/body，通过HttpMessageConverter实例转换后写到response，参考[ResponseEntity](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responseentity)获得更详细的信息|
|ErrorResponse|生成RFC7807规定的错误响应，输出到body中[Error Response](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-rest-exceptions)|
|ProblemDetail|生成RFC7807规定的错误响应，输出到body中[Error Response](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-rest-exceptions)|
|String|一个视图名称，ViewResolver会负责解析并与隐式模型一起使用。也可以明确的声明一个Model类型的参数组合使用|
|View|与上面一样，这个是View实例|
|Map/Model|要被渲染到模板的属性|
|@ModelAttribute|要被渲染到模板的属性|
|ModelAndView||
|void|如果具有`void`返回类型（或 null 返回值）的方法还具有`ServletResponse``OutputStream`参数或`@ResponseStatus`注释，则该方法被认为已完全处理响应。如果控制器进行了肯定的`ETag`或`lastModified`时间戳检查，情况也是如此（有关详细信息，请参阅控制器）。如果以上都不是true，void 返回类型也可以指示 REST 控制器的“无响应主体”或 HTML 控制器的默认视图名称选择。|
|Any other return value|如果返回值与上述任何一个都不匹配并且不是简单类型（由 BeanUtils#isSimpleProperty 确定），默认情况下，它将被视为要添加到模型中的模型属性。 如果是简单类型，则仍未解决|

# Controller Advice
`@ExceptionHandler`,`@InitBinder`,`@ModelAttribute`只能定义并应用在`@Controller`类中，或者继承了`@Controller`注解的类。还有一种方案，它们可以定义在一个`@ControllerAdvice`与`@RestControllerAdvice`修饰类中，然后它们可以全局应用到任意的控制器。更多的，从5.3版本开始，`@ControllerAdvice`中`@ExceptionHandler`可以处理任意`@Controller`类抛出的异常。`@ControllerAdvice`是一个带有`@Component`注解的元注解，因此可以注册为一个Spring Bean，`@RestControllerAdvice`是一个带有`@ControllerAdvice`与`@ResponseBody`的元注解。这意味着，`@ExceptionHandler`方法的返回值将会通过response body message转换转化到响应中而不是返回HTML视图。在启动阶段，`RequestMappingHandlerMapping`和`ExceptionHandlerExceptionResolver`会检测controller advice类型的bean并在运行时应用处理器逻辑。来自于`@ControllerAdvice`类的全局`@ExceptionHandler`方法在controller本地定义的异常处理器之后执行，相反的是，全局的`@ModelAttribute`与`@InitBinder`方法在本地定义的组件之前执行。`@ControllerAdvice`注解有很多属性可以设置，可以限定controller的范围，比如:
```java
// Target all Controllers annotated with @RestController
@ControllerAdvice(annotations = RestController.class)
public class ExampleAdvice1 {}

// Target all Controllers within specific packages
@ControllerAdvice("org.example.controllers")
public class ExampleAdvice2 {}

// Target all Controllers assignable to specific classes
@ControllerAdvice(assignableTypes = {ControllerInterface.class, AbstractController.class})
public class ExampleAdvice3 {}
```
前面例子中年的选择器在运行时检测，这会影响性能。可以参考[@ControllerAdvice](https://docs.spring.io/spring-framework/docs/6.0.4/javadoc-api/org/springframework/web/bind/annotation/ControllerAdvice.html)获得更多的细节。