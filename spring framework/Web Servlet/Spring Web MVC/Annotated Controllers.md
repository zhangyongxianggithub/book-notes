# 处理器方法
`@RequestMapping`处理器方法的参数非常灵活，支持特别多的参数与返回值。
## 方法参数
下面的表格列出了支持的所有的控制器方法参数，不支持任何响应式类型的参数。JDK8的`Optional`也是支持的，与带有`required`属性的注解（`@RequestParam`，`@RequestHeader`或者其他的注解）一起使用，表示`required=false`。
|Controller method argument|Description|
|`@PathVariable`|访问URI模板变量，可以参考[URI patterns](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-requestmapping.html#mvc-ann-requestmapping-uri-templates)|
|`@RequestParam`|访问Servlet请求参数，包括multipart文件，参数值会被转换为声明的方法参数类型，`@RequestParam`的参数也可以是[Multipart](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/multipart-forms.html)，对于简单的参数值来说，`@RequestParam`是可选的|
|`@RequestHeader`|访问请求头，请求头会被转换为声明的参数类型|
|其他参数|如果是简单类型的参数被认为是`@RequestParam`（由[BeanUtils.isSimpleProperty](https://docs.spring.io/spring-framework/docs/6.1.2/javadoc-api/org/springframework/beans/BeanUtils.html#isSimpleProperty-java.lang.Class-)）,其他情况下默认为`@ModelAttribute`参数|
## @RequestHeader
使用`@RequestHeader`注解绑定请求头到controller中的方法参数上。考虑下面的请求
```http
Host                    localhost:8080
Accept                  text/html,application/xhtml+xml,application/xml;q=0.9
Accept-Language         fr,en-gb;q=0.7,en;q=0.3
Accept-Encoding         gzip,deflate
Accept-Charset          ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive              300
```
下面的例子获取`Accept-Encoding`与`Keep-Alive`请求头的值
```java
@GetMapping("/demo")
public void handle(
		@RequestHeader("Accept-Encoding") String encoding,
		@RequestHeader("Keep-Alive") long keepAlive) {
	//...
}
```
`@RequestHeader`注解的参数不是String类型时，自动执行类型转换。如果是`Map<String, String>`, `MultiValueMap<String, String>`或者`HttpHeaders`类型，则用所有的请求头填充。Spring MVC支持将逗号分隔字符串转换为字符串数组或者Spring支持自动转换的类型的数组。
## Multipart
如果开启了`MultipartResolver`，Content-Type=multipart/form-data的POST请求体的内容将会被解析并且可以使用常规的请求参数的方式访问。下面的例子展示了访问一个普通的表单项与一个上传文件的例子:
```java
@Controller
public class FileUploadController {

	@PostMapping("/form")
	public String handleFormUpload(@RequestParam("name") String name,
			@RequestParam("file") MultipartFile file) {

		if (!file.isEmpty()) {
			byte[] bytes = file.getBytes();
			// store the bytes somewhere
			return "redirect:uploadSuccess";
		}
		return "redirect:uploadFailure";
	}
}
```
可以将参数声明为`List<MultipartFile>`，这样针对一个参数名可以解析多个上传的文件。当`@RequestParam`注解声明为`Map<String,MultipartFile>`或者`MultiValueMap<String,MultipartFile>`时，不需要在注解中指定参数名，文件与参数名会填充到map中。你也可以使用Servlet规范的多媒体参数形式，比如使用`jakarta.servlet.http.Part`参数代替`MultipartFile`，或者作为集合元素的元素类型。您还可以将multipart请求绑定到对象。例如，前面示例中的表单字段和文件可以是表单对象上的字段，如以下示例所示：
```java
class MyForm {

	private String name;

	private MultipartFile file;

	// ...
}

@Controller
public class FileUploadController {

	@PostMapping("/form")
	public String handleFormUpload(MyForm form, BindingResult errors) {
		if (!form.getFile().isEmpty()) {
			byte[] bytes = form.getFile().getBytes();
			// store the bytes somewhere
			return "redirect:uploadSuccess";
		}
		return "redirect:uploadFailure";
	}
}
```
Multipart请求也可能不是浏览器提交的，比如Rest服务。下面的例子是一个例子:
```http
POST /someUrl
Content-Type: multipart/mixed

--edt7Tfrdusa7r3lNQc79vXuhIIMlatb7PQg7Vp
Content-Disposition: form-data; name="meta-data"
Content-Type: application/json; charset=UTF-8
Content-Transfer-Encoding: 8bit

{
	"name": "value"
}
--edt7Tfrdusa7r3lNQc79vXuhIIMlatb7PQg7Vp
Content-Disposition: form-data; name="file-data"; filename="file.properties"
Content-Type: text/xml
Content-Transfer-Encoding: 8bit
... File Data ...
```
您可以通过`@RequestParam`以字符串的形式访问"meta-data"数据part，但您可能更想要将其从JSON反序列化(类似于`@RequestBody`)。在使用HttpMessageConverter转换后，使用`@RequestPart`注解来访问multipart：
```java
@PostMapping("/")
public String handle(@RequestPart("meta-data") MetaData metadata,
		@RequestPart("file-data") MultipartFile file) {
	// ...
}
```
你可以将`@RequestPart`与`jakarta.validation.Valid`配合使用或者使用Spring的`@Validated`注解。这样可以应用Bean校验。默认情况下，校验不通过会产生`MethodArgumentNotValidException`异常，然后Spring会以400返回给客户端。你可以通过在Controller方法中的`Errors`或者`BindingResult`来处理校验错误。
```java
@PostMapping("/")
public String handle(@Valid @RequestPart("meta-data") MetaData metadata,
		BindingResult result) {
	// ...
}
```
## @ResponseBody
`@ResponseBody`注解放到方法上会让返回值通过`HttpMessageConverter`转换为响应体。下面的列表是一个例子
```java
@GetMapping("/accounts/{id}")
@ResponseBody
public Account handle() {
}
```
`@ResponseBody`也可以放到类上，被所有的方法继承。效果等于`@RestController`，它是一个`@Controller`与`@ResponseBody`注解组合在一起的元注解。`@ResponseBody`注解支持响应式类型，可以参考[Asynchronous Requests](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-async.html)与[Reactive Types](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-async.html#mvc-ann-async-reactive-types)。你可以使用[MVC Config](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-config.html)的[Message Converters](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-config/message-converters.html)可选项来自定义类型转换。你还可以配置`@ResponseBody`的JSON序列化器，参考[Jackson JSON](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/jackson.html)获取更多的细节。
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

# Exceptions
`@Controller`与`@ControllerAdvice`注解类内都可以写`@ExceptionHandler`方法来处理controller方法抛出的异常，如下面的例子所示
```java
@Controller
public class SimpleController {
	@ExceptionHandler
	public ResponseEntity<String> handle(IOException ex) {
		// ...
	}
}
```
异常能匹配异常stack中的所有异常，这是从5.3版本开始的，之前的版本只能匹配最外面的异常与它的直接cause。最好声明方法中的异常为目标类型，当有很多异常处理方法都匹配时，需要一个root异常处理来处理根异常。更特殊的，可以用`ExceptionDepthComparator`来对异常stack排序，基于他们的depth。注解声明可以限定匹配的异常，如下面的例子所示:
```java
@ExceptionHandler({FileSystemException.class, RemoteException.class})
public ResponseEntity<String> handle(IOException ex) {
	// ...
}
```
通过注解限定，你可以在方法签名上声明更通用的异常类型参数，如下面的例子所示:
```java
@ExceptionHandler({FileSystemException.class, RemoteException.class})
public ResponseEntity<String> handle(Exception ex) {
	// ...
}
```
root与cause异常匹配是不同的
在前面展示的`IOException`变体中，方法实际调用时，异常参数可能是`FileSystemException`或者`RemoteException`的实例对象，因为他们都扩展自`IOException`，然而，如果异常在传播中被包裹到一个`IOException`实例中，方法传递的异常实例对象是`IOException`本身。这种行为类似`handle(Exception)`变体，在wrapping的场景总是使用最外面的异常实例完成方法调用，通过`ex.getCause()`完成异常匹配。

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
