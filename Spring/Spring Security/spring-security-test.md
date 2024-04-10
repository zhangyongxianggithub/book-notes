这一节主要描述Spring Security提供得1测试支持
# 测试安全性方法
这一节主要展示如何使用相关的支持类来测试安全性方法，我们首先写一个service的类，这个类的方法访问需要用户认证
```java
public class HelloMessageService implements MessageService {

    @PreAuthorize("authenticated")
    public String getMessage() {
        Authentication authentication = SecurityContextHolder.getContext()
            .getAuthentication();
        return "Hello " + authentication;
    }
}
```
方法只是简单的返回Hello+Authentication
## 测试初始化
在我们使用相关的测试支持类前，我们必须执行一些初始化的工作，比如下面这样的配置
```java
@RunWith(SpringJUnit4ClassRunner.class) 
@ContextConfiguration 
public class WithMockUserTests {
```
@RunWith声明了Spring-test模块需要创建一个ApplicationContext，与普通的Spring测试是一样的，更多的信息可以看Spring参考文档，@ContextConfiguration注解声明Spring- test、模块创建ApplicationContext用到的配置，因为没有指定配置，会在默认的地址尝试加载配置信息，与普通的Spring测试是一样的，更多的信息可以看Spring参考文档。
Spring Security使用钩子技术嵌入到Spring Test的执行，钩子类是WithSecurityContextTestExecutionListener，将会确保测试方法执行时带有当前的用户，这是通过在运行test前向SecurityContextHolder的上下文中写入当前用户完成的，如果你使用的是响应式程序，你需要使用ReactorContextTestExecutionListener填充ReactiveSecurityContextHolder的上下文，test执行完后，钩子会自动把上下文清空。记得我们在HelloMessageService的方法上加了@PreAuthorize注解，所以方法的访问需要登录的用户才可以，如果我们运行这个方法会抛出指定的异常
```java
@Test(expected = AuthenticationCredentialsNotFoundException.class)
public void getMessageUnauthenticated() {
    messageService.getMessage();
}
```
## @WithMockUser
指定运行test的用户最容易的方法是什么？答案就是@WithMockUser，下面的用户将会以一个username=user的用户的身份执行，密码是password，roles=ROLE_USER
```java
@Test
@WithMockUser
public void getMessageWithMockUser() {
String message = messageService.getMessage();
...
}
```
上面的例子指定了下面几项：
- username=user的用户必须要是真实存在的，因为是模拟的；
- SecurityContext上下文中的Authentication的类型是UsernamePasswordAuthenticationToken
- Authentication内的principal是User类型的对象；
- User对象的username=user，密码是password，有一个GrantedAuthority=ROLE_USER的权限。
我们的例子是很简短的，因为我们使用了很多缺省的配置，假如向换个username的用户运行怎么办呢？下面的例子将会以username=customUser的用户运行
```java
@Test
@WithMockUser("customUsername")
public void getMessageWithMockUserCustomUsername() {
    String message = messageService.getMessage();
...
}

```
也可以定制角色
```java
@Test
@WithMockUser(username="admin",roles={"USER","ADMIN"})
public void getMessageWithMockUserCustomUser() {
    String message = messageService.getMessage();
    ...
}


```
也可以不使用带ROLE_前缀的角色，直接使用权限。
```java
@Test
@WithMockUser(username = "admin", authorities = { "ADMIN", "USER" })
public void getMessageWithMockUserCustomAuthorities() {
    String message = messageService.getMessage();
    ...
}
```
每个测试方法上都放这个比较单调乏味，可以放到类上，那么每个类中方法都会从类继承
```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration
@WithMockUser(username="admin",roles={"USER","ADMIN"})
public class WithMockUserTests {
```
或者你用到了JUnit5的嵌套机制，那么可以在外层的类上指定，嵌套的类也会继承
```java
@ExtendWith(SpringExtension.class)
@ContextConfiguration
@WithMockUser(username="admin",roles={"USER","ADMIN"})
public class WithMockUserTests {

    @Nested
    public class TestSuite1 {
        // ... all test methods use admin user
    }

    @Nested
    public class TestSuite2 {
        // ... all test methods use admin user
    }
}
```
缺省情况下，钩子在遇到TestExecutionListener.beforeTestMethod事件时执行，这个事件在执行Junit的@Before方法前发出，可以执行在发出TestExecutionListener.beforeTestExecution事件时执行，那么会在@Before方法后，测试方法执行前执行。
```java
@WithMockUser(setupBefore = TestExecutionEvent.TEST_EXECUTION)
```
## @WithAnonymousUser
使用@WithAnonymousUser指定以匿名用户得方式执行，使用的场景时，当大多数测试以某个用户运行时，某几个不需要用户信息，这时可以指定@WithAnonymousUser以匿名用户的方式执行，如下面的例子
```java
@RunWith(SpringJUnit4ClassRunner.class)
@WithMockUser
public class WithUserClassLevelAuthenticationTests {

    @Test
    public void withMockUser1() {
    }

    @Test
    public void withMockUser2() {
    }

    @Test
    @WithAnonymousUser
    public void anonymous() throws Exception {
        // override default to run as anonymous user
    }
}
```
## @WithUserDetails
@WithMockUser已经很好用了，但是也不是所有的场合都可以应付，比如，对与一些应用来说，Authen提cation的principal通常是某种特定的类型，而不是User对象，这样减少对Spring Security的耦合。自定义的principal常常是自定义的UserDetailsService的返回结果，这个结果是一个UserDetails的实现类，这样的场景，需要调用UserDetailsService来创建测试用户，这些工作 @WithUserDetails都做了，假设我们有个类型是UserDetailsService的bean，下面的测试方法的上下文是是一个类型是UsernamePasswordAuthenticationToken的authenrication，一个从UserDetailsService返回的username=user的principal。
```java
@Test
@WithUserDetails
public void getMessageWithUserDetails() {
    String message = messageService.getMessage();
    ...
}
```
我们也可以指定一个username，如下：
```java
@Test
@WithUserDetails("customUsername")
public void getMessageWithUserDetailsCustomUsername() {
    String message = messageService.getMessage();
    ...
}

```
可以指定使用哪个UserDetailsService来加载principal，如下：
```java
@Test
@WithUserDetails(value="customUsername", userDetailsServiceBeanName="myUserDetailsService")
public void getMessageWithUserDetailsServiceBeanName() {
    String message = messageService.getMessage();
    ...
}
```
@WithUserDetails需要用户存在，以便service加载。
## @WithSecurityContext
这个是更灵活的方式，使用@WithSecurityContext定义自己的注解，可以自己决定创建SecurityContext上下文的内容，如下：
```java
@Retention(RetentionPolicy.RUNTIME)
@WithSecurityContext(factory = WithMockCustomUserSecurityContextFactory.class)
public @interface WithMockCustomUser {

    String username() default "rob";

    String name() default "Rob Winch";
}
```
需要指定一个创建SecurityContext上下文的工厂，实现类如下：
```java
public class WithMockCustomUserSecurityContextFactory
    implements WithSecurityContextFactory<WithMockCustomUser> {
    @Override
    public SecurityContext createSecurityContext(WithMockCustomUser customUser) {
        SecurityContext context = SecurityContextHolder.createEmptyContext();

        CustomUserDetails principal =
            new CustomUserDetails(customUser.name(), customUser.username());
        Authentication auth =
            new UsernamePasswordAuthenticationToken(principal, "password", principal.getAuthorities());
        context.setAuthentication(auth);
        return context;
    }
}
```
创建自定义的工厂时，可以使用spring的编程方式，比如使用@Autowired等；比如：
```java
final class WithUserDetailsSecurityContextFactory
    implements WithSecurityContextFactory<WithUserDetails> {

    private UserDetailsService userDetailsService;

    @Autowired
    public WithUserDetailsSecurityContextFactory(UserDetailsService userDetailsService) {
        this.userDetailsService = userDetailsService;
    }

    public SecurityContext createSecurityContext(WithUserDetails withUser) {
        String username = withUser.value();
        Assert.hasLength(username, "value() must be non-empty String");
        UserDetails principal = userDetailsService.loadUserByUsername(username);
        Authentication authentication = new UsernamePasswordAuthenticationToken(principal, principal.getPassword(), principal.getAuthorities());
        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        return context;
    }
}
```
## 元注解
如果你的测试经常使用相同的用户，重复指定这些值不是个好办法，可以使用元注解的方式减少重复指定属性。
```java
@Retention(RetentionPolicy.RUNTIME)
@WithMockUser(value="rob",roles="ADMIN")
public @interface WithMockAdmin { }
```
# 安全与Spring MVC进程的测试
Spring Security Test支持与MVC的集成。
## 初始化MockMvc与SpringSecurity
为了在Spring MVC测试中使用Spring Security，需要将过滤器链注册为MVC的一个Filter，也需要添加一个TestSecurityContextHolderPostProcessor的bean来支持模拟用户的注解，这个可以通过SecurityMockMvcConfigurers.springSecurity()实现
```java
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.*;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = SecurityConfig.class)
@WebAppConfiguration
public class CsrfShowcaseTests {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mvc;

    @Before
    public void setup() {
        mvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity()) 
                .build();
    }

```
SecurityMockMvcConfigurers.springSecurity()会做所有的用于在MVC中集成Security的工作。
## SecurityMockMvcRequestPostProcessors
Spring MVC提供了一个叫做RequestPostProcessor的接口，可以用来更改Request的内容，Spring Security提供了大量的实现，以便使测试更容易，为了使用这些实现类，建议静态导入的方式导入
```java
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
```
- 测试CSRF保护机制，当测试任何不安全的http方法时，使用CSRF保护，你必须在request中包含有效的CSRF的token，指定token的方式
```java
mvc
    .perform(post("/").with(csrf()))
```
使用header的方式
```java
mvc
    .perform(post("/").with(csrf().asHeader()))

```
指定一个无效的
```java
mvc
    .perform(post("/").with(csrf().useInvalidToken()))
```
- 以指定用户运行Spring MVC测试
有2种指定用户的方式
	- 使用RequestPostProcessor的方式指定用户，有很多可选的选项提供了绑定用户到当前请求的的操作，如下
```java
mvc
    .perform(get("/").with(user("user")))
```
给request绑定用户实际是绑定SecurityContextHolder的上下文，你需要确保SecurityContextPersistenceFilter已经添加到MockMvc实例中，添加的方式如下：
	  - 调用apply(springSecurity())
            -  添加Spring Security的FilterChainProxy到MockMvc;
      - 人工添加SecurityContextPersistenceFilter到MockMvc
可以定制化
```java
mvc
    .perform(get("/admin").with(user("admin").password("pass").roles("USER","ADMIN")))

```
指定一个存在的userDetails对象
```java
mvc
    .perform(get("/").with(user(userDetails)))
``` 
以匿名用户的方式执行
```java
mvc
    .perform(get("/").with(anonymous()))
```
指定authentication
```java
mvc
    .perform(get("/").with(authentication(authentication)))
```
指定上下文的方式
```java
mvc
    .perform(get("/").with(securityContext(securityContext)))
```
也可以为MockMvc指定缺省的用户
```java
mvc = MockMvcBuilders
        .webAppContextSetup(context)
        .defaultRequest(get("/").with(user("user").roles("ADMIN")))
        .apply(springSecurity())
        .build();
```
如果在多个请求中使用了一个用户，可以抽取出来
```java
public static RequestPostProcessor rob() {
    return user("rob").roles("ADMIN");
}
import static sample.CustomSecurityMockMvcRequestPostProcessors.*;

...

mvc
    .perform(get("/").with(rob()))

```
	- 使用注解的方式指定用户，RequestPostProcessor的一种替代方式就是使用上面提到的注解，如下
```java
@Test
@WithMockUser
public void requestProtectedUrlWithUser() throws Exception {
mvc
        .perform(get("/"))
        ...
}
```
- 测试HTTP Basic auth，很早就支持这种认证方式，但是header的格式什么的记不住，使用httpBasic RequestPostProcessor做到这个
```java
mvc
    .perform(get("/").with(httpBasic("user","password")))
```
- 测试OAuth2.0
```java
@GetMapping("/endpoint")
public String foo(@AuthenticationPrincipal OidcUser user) {
    return user.getIdToken().getSubject();
}
```
- 测试OIDC 2.0（忽略）
- 测试OAuth2.0 登录
- 测试OAuth2.0客户端
- 测试JWT认证，为了访问资源服务器某个需要认证的资源，你需要一个bearer的token，如果你的资源服务器使用的方式是JWT，那么bearer token需要被签名并编码，这些不是你关注的重点，Spring Security提供了一些支持，做了这些工作
	- 第一种方式是使用jwt() RequestPostProcessor
```java
mvc
    .perform(get("/endpoint").with(jwt()));
```
	- authentication() RequestPostProcessor的方式
```java
Jwt jwt = Jwt.withTokenValue("token")
    .header("alg", "none")
    .claim("sub", "user")
    .build();
Collection<GrantedAuthority> authorities = AuthorityUtils.createAuthorityList("SCOPE_read");
JwtAuthenticationToken token = new JwtAuthenticationToken(jwt, authorities);

mvc
    .perform(get("/endpoint")
        .with(authentication(token)));
```
- Opaque token测试
## SecurityMockMvcRequestBuilders
Spring MVC测试也提供了RequestBuilder接口，这个接口可以用来创建MockHttpServletRequest，security也提供了一些默认的实现，可以通过静态导入的方式使用
```java
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestBuilders.*;
```
## SecurityMockMvcResultMatchers
