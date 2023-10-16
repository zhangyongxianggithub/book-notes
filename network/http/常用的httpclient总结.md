[TOC]

常用的httpclient有以下几种：
- Okhttp；
- httpurlconnection；
- ApacheHttpClient;
- Retrofit;
- Spring RestTemplate；
- Spring WebClient
- Feign
- Spring Cloud Open Feign
- google-http-java-client
- async-http-client
- Unirest

下面着重理解他们的使用方法与各自的特点与优缺点
# Retrofit
一个类型安全的HTTPClient，用java语言编写。
## Introduction
Retrofit将HTTP API映射为Java接口。
```java
public interface GitHubService {
  @GET("users/{user}/repos")
  Call<List<Repo>> listRepos(@Path("user") String user);
}
```
Retrofit会生成`GitHubService`接口的一个代理实现
```java
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl("https://api.github.com/")
    .build();
GitHubService service = retrofit.create(GitHubService.class);
```
对方法的每次调用可以发起一个同步或者异步的HTTP请求
```java
Call<List<Repo>> repos = service.listRepos("octocat");
```
使用注解来描述HTTP请求
- URL路径参数与查询参数
- 对象与请求体的转换
- mulitpart请求与文件上传

## API Declaration
接口方法上的注解与参数的注解表明请求的处理方式。
### REQUEST METHOD
每个方法都必须有一个HTTP注解，提供请求方法和相对URL。有八个内置注解：HTTP、GET、POST、PUT、PATCH、DELETE、OPTIONS和HEAD。资源的相对URL在注解中指定。
```java
@GET("users/list")
@GET("users/list?sort=desc")
```
### URL MANIPULATION
URL参数的形式:
```java
@GET("group/{id}/users")
Call<List<User>> groupList(@Path("id") int groupId);
```
也可以添加查询参数
```java
@GET("group/{id}/users")
Call<List<User>> groupList(@Path("id") int groupId, @Query("sort") String sort);
```
对于多个查询参数，可以组合成map
```java
@GET("group/{id}/users")
Call<List<User>> groupList(@Path("id") int groupId, @QueryMap Map<String, String> options);
```
### REQUEST BODY
形式如下:
```java
@POST("users/new")
Call<User> createUser(@Body User user);
```
对象将会通过Retrofit对象设置的转换器来完成与请求体的转换。如果咩有指定转换器，使用`RequestBody`
### FORM ENCODED AND MULTIPART
支持提交form-encoded and multipart请求。当方法上存在`@FormUrlEncoded`时，将发送表单编码数据。每个键值对都用包含名称和提供值的对象的`@Field`进行注释。
```java
@FormUrlEncoded
@POST("user/edit")
Call<User> updateUser(@Field("first_name") String first, @Field("last_name") String last);
```
当方法上存在`@Multipart`时，将使用multipart请求。 部件使用`@Part`注释来声明。
```java
@Multipart
@PUT("user/photo")
Call<User> updateUser(@Part("photo") RequestBody photo, @Part("description") RequestBody description);
```
multipart使用Retrofit的转换器之一，或者它们可以实现`RequestBody`接口来处理它们自己的序列化。
### HEADER MANIPULATION
```java
@Headers({
    "Accept: application/vnd.github.v3.full+json",
    "User-Agent: Retrofit-Sample-App"
})
@GET("users/{username}")
Call<User> getUser(@Path("username") String username);
```
请注意，header不会相互覆盖。所有具有相同名称的header都将包含在请求中。可以使用`@Header`注释动态更新请求header。必须向`@Header`提供相应的参数。如果值为null，则将省略header。否则，将对该值调用`toString`并使用结果。
```java
@GET("user")
Call<User> getUser(@Header("Authorization") String authorization)
```
与查询参数类似，对于复杂的hdeader组合，可以使用Map。
```java
@GET("user")
Call<User> getUser(@HeaderMap Map<String, String> headers)
```
可以使用[OkHttp拦截器](https://github.com/square/okhttp/wiki/Interceptors)指定需要添加到每个请求的header。
### SYNCHRONOUS VS. ASYNCHRONOUS
`Call`实例可以同步或异步执行。每个实例只能使用一次，但是调用`clone()`将创建一个可以使用的新实例。在Android上，回调将在主线程上执行。 在JVM上，回调将在执行HTTP请求的同一线程上发生。
## Retrofit Configuration
Retrofit是一个类，通过它你的API接口可以变成可调用的对象。默认情况下，Retrofit将为您的平台提供合理的默认设置，但它允许自定义。
### CONVERTERS
默认情况下，Retrofit只能将HTTP body反序列化为OkHttp的`ResponseBody`类型，并且只能接受`@Body`注解的对象为`RequestBody`类型。可以添加转换器以支持其他类型。六个同级模块采用流行的序列化库，以方便您使用。
- Gson: com.squareup.retrofit2:converter-gson
- Jackson: com.squareup.retrofit2:converter-jackson
- Moshi: com.squareup.retrofit2:converter-moshi
- Protobuf: com.squareup.retrofit2:converter-protobuf
- Wire: com.squareup.retrofit2:converter-wire
- Simple XML: com.squareup.retrofit2:converter-simplexml
- JAXB: com.squareup.retrofit2:converter-jaxb
- Scalars (primitives, boxed, and String): com.squareup.retrofit2:converter-scalars

以下是使用`GsonConverterFactory`类生成`GitHubService`接口的实现的示例，该接口使用Gson进行反序列化。
```java
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl("https://api.github.com/")
    .addConverterFactory(GsonConverterFactory.create())
    .build();
GitHubService service = retrofit.create(GitHubService.class);
```
### CUSTOM CONVERTERS
如果您需要与使用Retrofit不支持开箱即用的内容格式（例如 YAML、txt、自定义格式）的API进行通信，或者您希望使用不同的库来实现现有格式，您可以轻松创建您自己的转换器。创建一个扩展`Converter.Factory`类的类，并在构建适配器时传入一个实例。
# Feign
Feign是一个HTTP客户端库，参考了Retrofit、JAXRS-2.0、WebSocket等内容，Feign的首要目标是降低HTTP开发的复杂性。
## Why Feign and not X?
Feign使用Jersey或者CXF等工具来写Java的HTTP客户端。更多的，Feign也可以基于http lib比如Apache HC等的客户端。Feign客户端可以以最小的消耗自定义的编解码器以及错误处理器等连接到HTTP API。
## How does Feign work
Feign的工作原理是将注解处理为模板化请求。在输出之前，参数会以简单的方式应用于这些模板。尽管Feign仅限于支持基于文本的API，但它极大地简化了系统方面，例如重放请求。此外，知道这一点后，Feign可以轻松地对您的转换进行单元测试。
## Java Version Compatibility
Feign 10.X与以上的版本基于Java 8，Feign 9.x可以工作于JDK 6版本以上。
## Feature overview
下面的图是feign提供的关键特性
![Feign提供的关键特性](feign-feature.png)
## Roadmap
## Usage
```xml
<dependency>
    <groupId>io.github.openfeign</groupId>
    <artifactId>feign-core</artifactId>
    <version>??feign.version??</version>
</dependency>
```
### Basics
使用方法类似:
```java
interface GitHub {
  @RequestLine("GET /repos/{owner}/{repo}/contributors")
  List<Contributor> contributors(@Param("owner") String owner, @Param("repo") String repo);

  @RequestLine("POST /repos/{owner}/{repo}/issues")
  void createIssue(Issue issue, @Param("owner") String owner, @Param("repo") String repo);

}

public static class Contributor {
  String login;
  int contributions;
}

public static class Issue {
  String title;
  String body;
  List<String> assignees;
  int milestone;
  List<String> labels;
}

public class MyApp {
  public static void main(String... args) {
    GitHub github = Feign.builder()
                         .decoder(new GsonDecoder())
                         .target(GitHub.class, "https://api.github.com");

    // Fetch and print a list of the contributors to this library.
    List<Contributor> contributors = github.contributors("OpenFeign", "feign");
    for (Contributor contributor : contributors) {
      System.out.println(contributor.login + " (" + contributor.contributions + ")");
    }
  }
}
```
### 接口注解
Feign定义了一个Contract对象，用于定义接口与底层的客户端如何交互工作。Feign的默认的contract定义了下面的注解:
|**注解**|**接口目标**|**使用方法**|
|:---|:---|:---|
|@RequestLine|Method|定义HttpMethod/UriTemplate，路径中表达式包含在{}中，其中表达式使用方法参数中的@Param定义|
|@Param|Parameter|定义一个模板变量，其值将用于解析相应的模板表达式，如果值丢失，它将尝试从字节码方法参数名称中获取名称（如果代码是使用-parameters标志编译的）|
|@Headers|Method,Type|定义一个`HeaderTemplate`；UriTemplate的变体。使用@Param注释值来解析相应的表达式。当用于类型时，模板将应用于每个请求。当用于方法时，模板将仅应用于带注释的方法。|
|@QueryMap|Parameter|定义一个map，pojo，最终转化为多个query string|
|@HeaderMap|Parameter|定义一个map，转换为Http Headers|
|@Body|Method|定义一个模板，类似于`UriTemplate`和`HeaderTemplate`，它使用 @Param注解的值来解析相应的表达式。|

如果请求需要提交到一个不同的host，需要在创建Feign客户端时提供或者对没个方法提供一个URI参数作为目标Host，
```java
@RequestLine("POST /repos/{owner}/{repo}/issues")
void createIssue(URI host, Issue issue, @Param("owner") String owner, @Param("repo") String repo);
```
### Templates and Expressions
Feign表达式表示Simple String Expressions (Level 1)，这是[RFC 6570 URI Template](https://tools.ietf.org/html/rfc6570)定义的。
```java
public interface GitHub {

  @RequestLine("GET /repos/{owner}/{repo}/contributors")
  List<Contributor> contributors(@Param("owner") String owner, @Param("repo") String repository);

  class Contributor {
    String login;
    int contributions;
  }
}

public class MyApp {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
                         .decoder(new GsonDecoder())
                         .target(GitHub.class, "https://api.github.com");

    /* The owner and repository parameters will be used to expand the owner and repo expressions
     * defined in the RequestLine.
     *
     * the resulting uri will be https://api.github.com/repos/OpenFeign/feign/contributors
     */
    github.contributors("OpenFeign", "feign");
  }
}
```
表达式在一对中括号中，可以包含正则表达式，在:后指出来限定值的匹配。比如上面的例子owner必须是字母`{owner:[a-zA-Z]*}`。请求参数可以使用扩展的方式.
#### Request Parameter Expansion
`RequestLine`与`QueryMap`模板遵循[URI Template - RFC6570](https://tools.ietf.org/html/rfc6570)规范。Level 1规范的内容如下:
- 不能解析的表达式会被忽略
- 所有文本或者变量值都会执行编码

Level 3的内容如下:
- Maps/Lists以默认的方式展开
- 只支持单个变量模板

```
{;who}             ;who=fred
{;half}            ;half=50%25
{;empty}           ;empty
{;list}            ;list=red;list=green;list=blue
{;map}             ;semi=%3B;dot=.;comma=%2C
```

```java
public interface MatrixService {

  @RequestLine("GET /repos{;owners}")
  List<Contributor> contributors(@Param("owners") List<String> owners);

  class Contributor {
    String login;
    int contributions;
  }
}
```
如果上面例子中的owners的值为Matt、Jeff、Susan。uri会被扩展成`/repos;owners=Matt;owners=Jeff;owners=Susan`。
#### Undefined vs Empty Values
未定义的表达式的意思就是表达式的值是null或者没有提供表达式的值。根据RFC6570规范，可以为表达式提供空值，当Feign解析表达式时，它首先检测值是否被定义，如果存在，正常执行，如果未定义，则查询参数被移除，下面的例子:
```java
public void test() {
   Map<String, Object> parameters = new LinkedHashMap<>();
   parameters.put("param", "");
   this.demoClient.test(parameters);
}
```
产生的请求: `http://localhost:8080/test?param=`.
对下面的例子:
```java
public void test() {
   Map<String, Object> parameters = new LinkedHashMap<>();
   this.demoClient.test(parameters);
}
```
产生的结果: `http://localhost:8080/test`。
未定义:
```java
public void test() {
   Map<String, Object> parameters = new LinkedHashMap<>();
   parameters.put("param", null);
   this.demoClient.test(parameters);
}
```
产生的结果: `http://localhost:8080/test`
可以参考[这里例子](https://github.com/OpenFeign/feign#advanced-usage)展示了高级的用法。
>@RequestLine uri模板默认不会对slash编码，为了改变这个行为，设置`@RequestLine`的`decodeSlash=false`。
>根据URI模板规范，+符号允许出现在URI的路径或者参数segments中，但是如何处理这个符号是不一致的。在老系统中，+符号等于空格。对于现代系统来说，+符号不代表空格，会被强制编码为%2B。如果你想要+符号代表空格，可以直接使用空格的直接文本形式或者使用%20

#### Custom Expansion
`@Param`注解有一个可选项expander，允许控制单个参数的expansion。expander属性必须是一个实现了`Expander`接口的类:
```java
public interface Expander {
    String expand(Object value);
}
```
该方法的结果遵循上述相同的规则。 如果结果为 null或空字符串，则省略该值。 如果该值不是 pct 编码的，则它将是。 有关更多示例，请参阅自定义 @Param 扩展。
#### Request Headers Expansion
#### Request Body Expansion
### Customization
Feign可以定制，对于简单的场景，使用`Feign.builder()`来使用自定义组件来构建API接口。对于request设置，你可以使用`options(Request.Options options)`来设置connetTimeout、connectTimeoutUnit、readTimeout、readTimeoutUnit等，比如下面的例子:
```java
interface Bank {
  @RequestLine("POST /account/{id}")
  Account getAccountInfo(@Param("id") String id);
}

public class BankService {
  public static void main(String[] args) {
    Bank bank = Feign.builder()
        .decoder(new AccountDecoder())
        .options(new Request.Options(10, TimeUnit.SECONDS, 60, TimeUnit.SECONDS, true))
        .target(Bank.class, "https://api.examplebank.com");
  }
}
```
### Multiple Interface
Feign可以生成多个API接口。它们被定义为`Target<T>`(默认为HardCodedTarget<T>)，这样允许动态发现或者允许在实际执行请求前装饰请求。比如，下面的模式会使用当前URL与auth token来装饰每个发出的请求:
```java
public class CloudService {
  public static void main(String[] args) {
    CloudDNS cloudDNS = Feign.builder()
      .target(new CloudIdentityTarget<CloudDNS>(user, apiKey));
  }
  class CloudIdentityTarget extends Target<CloudDNS> {
    /* implementation of a Target */
  }
}
```
### 例子
Feign包含了Github/Wikipedia客户端的例子。
### Integrations
Feign设计为可以与其他开源工具很好地配合。可以为Feign开发模块来集成你喜欢项目。
### Encoder/Decoder
#### Gson
Gson包含JSON的编解码器。添加`GsonEncoder`与`GsonDecoder`到你的`Feign.Builder`，比如:
```java
public class Example {
  public static void main(String[] args) {
    GsonCodec codec = new GsonCodec();
    GitHub github = Feign.builder()
                         .encoder(new GsonEncoder())
                         .decoder(new GsonDecoder())
                         .target(GitHub.class, "https://api.github.com");
  }
}
```
#### Jackson
```java
public class Example {
  public static void main(String[] args) {
      GitHub github = Feign.builder()
                     .encoder(new JacksonEncoder())
                     .decoder(new JacksonDecoder())
                     .target(GitHub.class, "https://api.github.com");
  }
}
```
For the lighter weight Jackson Jr, use JacksonJrEncoder and JacksonJrDecoder from the Jackson Jr Module.
#### Moshi
也是用来处理JSON的
```java
GitHub github = Feign.builder()
                     .encoder(new MoshiEncoder())
                     .decoder(new MoshiDecoder())
                     .target(GitHub.class, "https://api.github.com");
```
#### Sax
解码XML，兼容JVM/android
```java
public class Example {
  public static void main(String[] args) {
      Api api = Feign.builder()
         .decoder(SAXDecoder.builder()
                            .registerContentHandler(UserIdHandler.class)
                            .build())
         .target(Api.class, "https://apihost");
    }
}
```
#### JAXB
xml
```java
public class Example {
  public static void main(String[] args) {
    Api api = Feign.builder()
             .encoder(new JAXBEncoder())
             .decoder(new JAXBDecoder())
             .target(Api.class, "https://apihost");
  }
}
```
#### SOAP
用于处理XML，该模块添加了通过JAXB和SOAPMessage编码和解码SOAP Body对象的支持。它还通过将SOAPFault包装到原始 javax.xml.ws.soap.SOAPFaultException 中来提供 SOAPFault 解码功能，这样您只需捕获 SOAPFaultException 即可处理 SOAPFault。
```java
public class Example {
  public static void main(String[] args) {
    Api api = Feign.builder()
	     .encoder(new SOAPEncoder(jaxbFactory))
	     .decoder(new SOAPDecoder(jaxbFactory))
	     .errorDecoder(new SOAPErrorDecoder())
	     .target(MyApi.class, "http://api");
  }
}
```
### Contract
#### JAX-RS
JAXRSContract配置会替换默认的注解处理机制，使用标准的JAX-RS规范机制来生成HTTP客户端。目前支持1.1规范。下面是使用JAX-RS改写的例子。
```java
interface GitHub {
  @GET @Path("/repos/{owner}/{repo}/contributors")
  List<Contributor> contributors(@PathParam("owner") String owner, @PathParam("repo") String repo);
}

public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
                       .contract(new JAXRSContract())
                       .target(GitHub.class, "https://api.github.com");
  }
}
```
### Client
#### OkHttp
[OkHttpClient](https://github.com/OpenFeign/feign/blob/master/ribbon)将Feign的HTTP请求发到OkHttp。OkHttp开启了SPDY，并且具有更好的网络控制。为了让Feign使用OkHttp底层客户端。你需要将OkHttp模块添加到你的类路径中。然后配置Feign使用OkHttpClient:
```java
public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
                     .client(new OkHttpClient())
                     .target(GitHub.class, "https://api.github.com");
  }
}
```
#### Ribbon
[RibbonClient](https://github.com/OpenFeign/feign/blob/master/ribbon)会覆盖Feign客户端的URL解析机制。添加Ribbon提供的动态路由与弹性机制。使用Ribbon客户端，需要你把ribbon客户端名字替换url中的host部分，比如下面的例子:
```java
public class Example {
  public static void main(String[] args) {
    MyService api = Feign.builder()
          .client(RibbonClient.create())
          .target(MyService.class, "https://myAppProd");
  }
}
```
#### Java 11 Http2
[Http2Client](https://github.com/OpenFeign/feign/blob/master/java11)将Feign的HTTP请求导向Java11中实现了HTTP/2协议的新的HTTP/2客户端。为了让Feign客户端使用HTTP/2客户端，你需要使用SDK11，下面的例子:
```java
GitHub github = Feign.builder()
                     .client(new Http2Client())
                     .target(GitHub.class, "https://api.github.com");
```
### Breaker
#### Hystrix
[HystrixFeign](https://github.com/OpenFeign/feign/blob/master/hystrix)提供了Hystrix支持的circuit breaker机制。需要classpath下面有Hystrix模块
```java
public class Example {
  public static void main(String[] args) {
    MyService api = HystrixFeign.builder().target(MyService.class, "https://myAppProd");
  }
}
```
### Logger
#### slf4j
[SLF4JModule](https://github.com/OpenFeign/feign/blob/master/slf4j)将Feign的日志指向SLF4J。允许你简单的使用你自己选择的logging组件(Logback、Log4J等)。为了让Feign使用SLF4J，需要添加SLF4J与SLF4J的绑定模块到classpath，然后配置Feign使用Slf4jLogger:
```java
public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
                     .logger(new Slf4jLogger())
                     .logLevel(Level.FULL)
                     .target(GitHub.class, "https://api.github.com");
  }
}
```
### Decoders
`Feign.buidler()`允许你指定额外的配置，比如如何解码响应体。如果接口中的请求映射方法返回的类型不是`Response`、`String`、`byte[]`、`void`，你都需要配置一个`Decoder`。下面是使用JSON解码的例子:
```java
public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
                     .decoder(new GsonDecoder())
                     .target(GitHub.class, "https://api.github.com");
  }
}
```
如果你要在解码响应体之前做一些预处理操作，你可以使用builder的`mapAndDecode`方法，下面是一个JSONP的例子:
```java
public class Example {
  public static void main(String[] args) {
    JsonpApi jsonpApi = Feign.builder()
                         .mapAndDecode((response, type) -> jsopUnwrap(response, type), new GsonDecoder())
                         .target(JsonpApi.class, "https://some-jsonp-api.com");
  }
}
```
如果方法返回的类型是`Stream`，需要配置一个`StreamDecoder`，下面是例子:
```java
public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
            .decoder(StreamDecoder.create((r, t) -> {
              BufferedReader bufferedReader = new BufferedReader(r.body().asReader(UTF_8));
              return bufferedReader.lines().iterator();
            }))
            .target(GitHub.class, "https://api.github.com");
  }
}

public class Example {
  public static void main(String[] args) {
    GitHub github = Feign.builder()
            .decoder(StreamDecoder.create((r, t) -> {
              BufferedReader bufferedReader = new BufferedReader(r.body().asReader(UTF_8));
              return bufferedReader.lines().iterator();
            }, (r, t) -> "this is delegate decoder"))
            .target(GitHub.class, "https://api.github.com");
  }
}
```
### Encoders
发送请求体到服务器的最简单的方式是顶一个POST方法且方法的参数为一个`String`或者`byte[]`，你需要添加一个Content-Type头
```java
interface LoginClient {
  @RequestLine("POST /")
  @Headers("Content-Type: application/json")
  void login(String content);
}

public class Example {
  public static void main(String[] args) {
    client.login("{\"user_name\": \"denominator\", \"password\": \"secret\"}");
  }
}
```
配置Encoder，你可以发送类型安全的请求体，下面是一个例子:
```java
static class Credentials {
  final String user_name;
  final String password;

  Credentials(String user_name, String password) {
    this.user_name = user_name;
    this.password = password;
  }
}

interface LoginClient {
  @RequestLine("POST /")
  void login(Credentials creds);
}

public class Example {
  public static void main(String[] args) {
    LoginClient client = Feign.builder()
                              .encoder(new GsonEncoder())
                              .target(LoginClient.class, "https://foo.com");

    client.login(new Credentials("denominator", "secret"));
  }
}
```
### @Body templates
`@Body`注解指定了一个模板，模板使用`@Param`注解的参数构成。你需要配置Content-Type
```java
interface LoginClient {

  @RequestLine("POST /")
  @Headers("Content-Type: application/xml")
  @Body("<login \"user_name\"=\"{user_name}\" \"password\"=\"{password}\"/>")
  void xml(@Param("user_name") String user, @Param("password") String password);

  @RequestLine("POST /")
  @Headers("Content-Type: application/json")
  // json curly braces must be escaped!
  @Body("%7B\"user_name\": \"{user_name}\", \"password\": \"{password}\"%7D")
  void json(@Param("user_name") String user, @Param("password") String password);
}

public class Example {
  public static void main(String[] args) {
    client.xml("denominator", "secret"); // <login "user_name"="denominator" "password"="secret"/>
    client.json("denominator", "secret"); // {"user_name": "denominator", "password": "secret"}
  }
}
```
### Headers
Feign支持设置headers，可以作为API的一部分或者作为client的一部分，可以根据具体的使用场景来设置。
#### Set headers using apis
如果只有特定的接口或者调用有某些固定的header，将header定义为api的一部分是好的，可以使用注解`@Headers`在接口或者方法上定义静态的注解:
```java
@Headers("Accept: application/json")
interface BaseApi<V> {
  @Headers("Content-Type: application/json")
  @RequestLine("PUT /api/{key}")
  void put(@Param("key") String key, V value);
}
```
当放在方法上时，可以为header指定动态的内容，通过参数模板:
```java
public interface Api {
   @RequestLine("POST /")
   @Headers("X-Ping: {token}")
   void post(@Param("token") String token);
}
```
headers可以做成全动态的，比如:
```java
public interface Api {
   @RequestLine("POST /")
   void post(@HeaderMap Map<String, Object> headerMap);
}
```
#### Setting headers per target



