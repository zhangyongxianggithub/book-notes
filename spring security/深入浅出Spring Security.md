# 第一章 Spring Security架构概览
Spring Security方便集成在Spring Boot与Spring Cloud项目中，因为它们就是同归属于一个家族。比shiro啥的有优势。
## Spring Security简介
java安全管理的实现方案
- Shiro，轻量、简单、易于集成，但是不擅长微服务;
- Spring Security，支持oauth2，Spring Cloud也推出了相关的支持，更适合微服务;
- 开发者自己实现，网络攻击可能存在.

Spring Security最早叫做Acegi Security，是基于Spring的一种框架，主要是为Spring框架提供安全相关的功能，后来改名了叫Spring Security，一直是配置繁琐；但是Spring Boot的出现解决了这个问题，因为可以提供自动化的配置。
## Spring Security核型功能
- 认证（你是谁）
- 授权（你可以做什么）

支持的认证方式：
- 表单认证
- OAuth2.0认证
- SAML2.0认证
- CAS认证
- RememberMe自动认证
- JAAS认证
- OpenID去中心化认证
- Pre-Authentication Scenarios认证
- X509认证
- HTTP Basic认证
- HTTP Digest认证

也可以引入第三方的支持或者自定义认证逻辑支持更多的认证方式，认证于授权是解耦的，互不影响，Spring Security支持URL请求授权、方法访问授权、SpEL访问控制、域对象安全(ACL)、动态权限配置、RBAC模型等。Spring Security还帮助我们做了网络攻击的防护
## Spring Security整体架构
在Spring Security的设计中，认证（Authentication）与授权（Authorization）是分开的，无论使用什么样的授权方式都不会影响认证；用户的认证信息主要是由Authentication的实现类来保存，Authentication接口如下：
```java
package org.springframework.security.core;

import java.io.Serializable;
import java.security.Principal;
import java.util.Collection;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Represents the token for an authentication request or for an authenticated principal
 * once the request has been processed by the
 * {@link AuthenticationManager#authenticate(Authentication)} method.
 * <p>
 * Once the request has been authenticated, the <tt>Authentication</tt> will usually be
 * stored in a thread-local <tt>SecurityContext</tt> managed by the
 * {@link SecurityContextHolder} by the authentication mechanism which is being used. An
 * explicit authentication can be achieved, without using one of Spring Security's
 * authentication mechanisms, by creating an <tt>Authentication</tt> instance and using
 * the code:
 *
 * <pre>
 * SecurityContextHolder.getContext().setAuthentication(anAuthentication);
 * </pre>
 *
 * Note that unless the <tt>Authentication</tt> has the <tt>authenticated</tt> property
 * set to <tt>true</tt>, it will still be authenticated by any security interceptor (for
 * method or web invocations) which encounters it.
 * <p>
 * In most cases, the framework transparently takes care of managing the security context
 * and authentication objects for you.
 *
 * @author Ben Alex
 */
public interface Authentication extends Principal, Serializable {
	// ~ Methods
	// ========================================================================================================

	/**
	 * Set by an <code>AuthenticationManager</code> to indicate the authorities that the
	 * principal has been granted. Note that classes should not rely on this value as
	 * being valid unless it has been set by a trusted <code>AuthenticationManager</code>.
	 * <p>
	 * Implementations should ensure that modifications to the returned collection array
	 * do not affect the state of the Authentication object, or use an unmodifiable
	 * instance.
	 * </p>
	 *
	 * @return the authorities granted to the principal, or an empty collection if the
	 * token has not been authenticated. Never null.
	 */
	Collection<? extends GrantedAuthority> getAuthorities();

	/**
	 * The credentials that prove the principal is correct. This is usually a password,
	 * but could be anything relevant to the <code>AuthenticationManager</code>. Callers
	 * are expected to populate the credentials.
	 *
	 * @return the credentials that prove the identity of the <code>Principal</code>
	 */
	Object getCredentials();

	/**
	 * Stores additional details about the authentication request. These might be an IP
	 * address, certificate serial number etc.
	 *
	 * @return additional details about the authentication request, or <code>null</code>
	 * if not used
	 */
	Object getDetails();

	/**
	 * The identity of the principal being authenticated. In the case of an authentication
	 * request with username and password, this would be the username. Callers are
	 * expected to populate the principal for an authentication request.
	 * <p>
	 * The <tt>AuthenticationManager</tt> implementation will often return an
	 * <tt>Authentication</tt> containing richer information as the principal for use by
	 * the application. Many of the authentication providers will create a
	 * {@code UserDetails} object as the principal.
	 *
	 * @return the <code>Principal</code> being authenticated or the authenticated
	 * principal after authentication.
	 */
	Object getPrincipal();

	/**
	 * Used to indicate to {@code AbstractSecurityInterceptor} whether it should present
	 * the authentication token to the <code>AuthenticationManager</code>. Typically an
	 * <code>AuthenticationManager</code> (or, more often, one of its
	 * <code>AuthenticationProvider</code>s) will return an immutable authentication token
	 * after successful authentication, in which case that token can safely return
	 * <code>true</code> to this method. Returning <code>true</code> will improve
	 * performance, as calling the <code>AuthenticationManager</code> for every request
	 * will no longer be necessary.
	 * <p>
	 * For security reasons, implementations of this interface should be very careful
	 * about returning <code>true</code> from this method unless they are either
	 * immutable, or have some way of ensuring the properties have not been changed since
	 * original creation.
	 *
	 * @return true if the token has been authenticated and the
	 * <code>AbstractSecurityInterceptor</code> does not need to present the token to the
	 * <code>AuthenticationManager</code> again for re-authentication.
	 */
	boolean isAuthenticated();

	/**
	 * See {@link #isAuthenticated()} for a full description.
	 * <p>
	 * Implementations should <b>always</b> allow this method to be called with a
	 * <code>false</code> parameter, as this is used by various classes to specify the
	 * authentication token should not be trusted. If an implementation wishes to reject
	 * an invocation with a <code>true</code> parameter (which would indicate the
	 * authentication token is trusted - a potential security risk) the implementation
	 * should throw an {@link IllegalArgumentException}.
	 *
	 * @param isAuthenticated <code>true</code> if the token should be trusted (which may
	 * result in an exception) or <code>false</code> if the token should not be trusted
	 *
	 * @throws IllegalArgumentException if an attempt to make the authentication token
	 * trusted (by passing <code>true</code> as the argument) is rejected due to the
	 * implementation being immutable or implementing its own alternative approach to
	 * {@link #isAuthenticated()}
	 */
	void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException;
}
```
- getAuthenorities() 用来获取用户的权限；
- getCredentials()  用来获取用户的凭证，一般来说就是密码；
- getDetials() 用来获取用户携带的详细的信息；
- getPrincipal() 用来获取当前用户，例如是一个用户名或者是一个用户对象；
- isAuthenticated() 当前用户是否认证成功;

不同的认证方式对应不同的Authentication接口的实现，Spring Security中的认证的工作主要由AuthenticationManager负责；该接口的定义如下: 
```java
package org.springframework.security.authentication;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;

/**
 * Processes an {@link Authentication} request.
 *
 * @author Ben Alex
 */
public interface AuthenticationManager {
	// ~ Methods
	// ========================================================================================================

	/**
	 * Attempts to authenticate the passed {@link Authentication} object, returning a
	 * fully populated <code>Authentication</code> object (including granted authorities)
	 * if successful.
	 * <p>
	 * An <code>AuthenticationManager</code> must honour the following contract concerning
	 * exceptions:
	 * <ul>
	 * <li>A {@link DisabledException} must be thrown if an account is disabled and the
	 * <code>AuthenticationManager</code> can test for this state.</li>
	 * <li>A {@link LockedException} must be thrown if an account is locked and the
	 * <code>AuthenticationManager</code> can test for account locking.</li>
	 * <li>A {@link BadCredentialsException} must be thrown if incorrect credentials are
	 * presented. Whilst the above exceptions are optional, an
	 * <code>AuthenticationManager</code> must <B>always</B> test credentials.</li>
	 * </ul>
	 * Exceptions should be tested for and if applicable thrown in the order expressed
	 * above (i.e. if an account is disabled or locked, the authentication request is
	 * immediately rejected and the credentials testing process is not performed). This
	 * prevents credentials being tested against disabled or locked accounts.
	 *
	 * @param authentication the authentication request object
	 *
	 * @return a fully authenticated object including credentials
	 *
	 * @throws AuthenticationException if authentication fails
	 */
	Authentication authenticate(Authentication authentication)
			throws AuthenticationException;
}
```
这个接口只有一个方法authenticate，有3种返回的方式：
- Authentication表示认证成功;
- 抛出AuthenticationException，表示用户输入了无效的凭证;
- 返回null，表示不能判定.

主要的实现类是ProviderManager，ProviderManager管理了众多的AuthenticationProvider实例，AuthenticationProvider有点类似于AuthenticationManager，但是它多了一个supports()方法用来判断是否支持给定的Authentication类型。AuthenticationProvider接口定义如下：
```java
package org.springframework.security.authentication;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;

/**
 * Indicates a class can process a specific
 * {@link org.springframework.security.core.Authentication} implementation.
 *
 * @author Ben Alex
 */
public interface AuthenticationProvider {
	// ~ Methods
	// ========================================================================================================

	/**
	 * Performs authentication with the same contract as
	 * {@link org.springframework.security.authentication.AuthenticationManager#authenticate(Authentication)}
	 * .
	 *
	 * @param authentication the authentication request object.
	 *
	 * @return a fully authenticated object including credentials. May return
	 * <code>null</code> if the <code>AuthenticationProvider</code> is unable to support
	 * authentication of the passed <code>Authentication</code> object. In such a case,
	 * the next <code>AuthenticationProvider</code> that supports the presented
	 * <code>Authentication</code> class will be tried.
	 *
	 * @throws AuthenticationException if authentication fails.
	 */
	Authentication authenticate(Authentication authentication)
			throws AuthenticationException;

	/**
	 * Returns <code>true</code> if this <Code>AuthenticationProvider</code> supports the
	 * indicated <Code>Authentication</code> object.
	 * <p>
	 * Returning <code>true</code> does not guarantee an
	 * <code>AuthenticationProvider</code> will be able to authenticate the presented
	 * instance of the <code>Authentication</code> class. It simply indicates it can
	 * support closer evaluation of it. An <code>AuthenticationProvider</code> can still
	 * return <code>null</code> from the {@link #authenticate(Authentication)} method to
	 * indicate another <code>AuthenticationProvider</code> should be tried.
	 * </p>
	 * <p>
	 * Selection of an <code>AuthenticationProvider</code> capable of performing
	 * authentication is conducted at runtime the <code>ProviderManager</code>.
	 * </p>
	 *
	 * @param authentication
	 *
	 * @return <code>true</code> if the implementation can more closely evaluate the
	 * <code>Authentication</code> class presented
	 */
	boolean supports(Class<?> authentication);
}
```
由于Authentication拥有众多的实现类，不同的实现类由不同的AuthenticationProvider来处理，所以有个supports方法，用来判断Provider是否支持对应的Authentication；在一个完整的认证流程中，可能存在多个Provider（比如项目同时支持表单登录与验证码登录），这些Provider统一由Manager来管理，ProviderManager由一个可选的parent，当所有的AuthenticationProvider都处理失败时，就会调用parent认证。相当于一个备用的认证方式。
授权有2个关键的接口
- AccessDecisionManager
- AccessDecisionVoter

AccessDecisionVoter是一个投票器，用于检查用户是否应该具备应有的角色；AccessDecisionManager是一个决策器，用来决定此次访问是否被允许；它们都有众多的实现类，AccessDecisionManager会挨个遍历AccessDecisionVoter，决定是否允许用户访问；有点类似于AuthenticationProvider与ProviderManager的关系。
在Spring Security中，用户请求资源需要的角色会被封装成ConfigAttributes，投票器做的事情就是判断ConfigAttributes与当前用户的角色是否匹配。
在Spring Security中，认证与授权都是通过过滤器来完成的，下面列表的默认加载是指引入Spring Security依赖后，开发者不做任何配置自动加载的过滤器，Spring Security的过滤器如下：

|过滤器|过滤器的作用|是否默认加载|
|:---:|:---:|:---:|
|ChannelProcessingFilter|过滤请求协议如HTTTP与HTTPS|NO|
|WebAsyncManagerIntegrationFilter|将WebAsyncManager与Spring Security上下文进行集成|YES|
|SecurityContextpersistenceFilter|在处理请求之前，将安全信息加载到SecurityContextHolder种以方便后续使用，请求结束后再擦除SecurityContextHolder中的信息|YES|
|HeaderWriterFilter|头信息加入到响应中|YES|
|CorsFilter|处理跨域问题|NO|
|CsrfFilter|处理CSRF攻击|YES|
|LogoutFilter|处理注销登录|YES|
|OAuth2AuthorizationRequestRedirectFilter|处理OAuth2认证重定向|NO|
|Saml2WebSsoAuthenticationRequestFilter|处理SAML认证|NO|
|X509AuthenticationFilter|处理X509认证|NO|
|AbstractPreAuthenticatedProcessingFilter|处理预认证问题|NO|
|CasAuthenticationFilter|处理CAS单点登录|NO|
|OAuth2LoginAuthenticationFilter|处理OAuth2认证|NO|
|Saml2WebssoAuthenticationFilter|处理SAML认证|NO|
|UsernammePasswordAuthenticationFilter|处理表单登录|YES|
|OpenIDAuthenticationFilter|处理OpenID认证|NO|
|DefaultLoginPageGeneratingFilter|配置默认登录页面|YES|
|DefaultLogoutPageGeneratingFilter|配置默认注销页面|YES|
|ConcurrentSessionFilter|处理Session有效期|NO|
|DigestAuthenticationFilter|处理HTTP摘要认证|NO|
|BearerTokenAuthenticationFilter|处理OAuth2认证时的Access Token|NO|
|BasicAuthenticationFilter|处理HttBasic登录|YES|
|RequestCacheAwareFilter|处理请求缓存|YES|
|SecurityContextHolderAwareRequestFilter|包装原始请求|YES|
|JaasApiIntegrationFilter|处理JAAS认证|NO|
|RememberMeAuthenticationFilter|处理RememberMe登录|NO|
|AnonymousAuthenticationFilter|配置匿名认证|YES|
|OAuth2AuthenticationCodeGrantFilter|处理OAuth2认证中的授权码|NO|
|SessionManagementFilter|处理Session并发问题|YES|
|ExceptionTranslationFilter|处理异常认证/授权中的情况|YES|
|FilterSecurityInterceptor|处理授权|YES|
|SwitchUserFilter|处理账户切换|NO|

Spring Security的所有的功能都是通过这些过滤器来实现的，这些过滤器按照既定的优先级排列形成过滤器链；也可以自定义过滤器，并通过@Order来调整自定义过滤器在过滤器链中的位置。默认的过滤器并不是直接在Web项目的原生过滤器链中，而是通过一个FilterChainProxy来统一管理，Spring Security中的过滤器链通过FilterChainProxy嵌入到Web项目的原生过滤器链中，如下图
![过滤器链通过FilterChainProxy出现在Web容器中](./filterchainproxy.png)
过滤器链可能存在多个
![多个过滤器](./multi-filterchainproxy.png)
FilterChainProxy会通过DelegatingFilterProxy整合到原生过滤器链中。
Spring Security还对登录成功后的用户信息数据做了线程绑定（Session中也会存储一份）。使用的是ThreadLocal的机制，SecurityContextHolder中会存储这个变量，当处理完成，SecurityContextHolder会把数据清空，并放到Session中，以后每当有请求到来，先到session中取出登录数据放到SecurityContextHolder中，然后处理完，再次保存到Session中。但是如果是异步执行的话，线程中获取不到登录用户信息，特别是使用`@Async`时候，Spring Security为此提供了解决方案
```java
@Configuration
public class Config extends AsyncConfigurerSupport {
    @Override
    public Executor getAsyncExecutor() {
        return new DelegatingSecurityContextExecutorService(
                Executors.newFixedThreadPool(5));
    }
}
```
# 第2章 认证
引进依赖
```xml
              <dependency>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-starter-security</artifactId>
                    <version>2.7.1</version>
                </dependency>
```
来看一下请求的流程
![请求流程图](./%E8%AF%B7%E6%B1%82%E6%B5%81%E7%A8%8B%E5%9B%BE.drawio.png)
- 客户端发起请求访问/hello接口，这个接口被鉴权
- 请求达到服务端走了一遍security的过滤器链，然后到达FilterSecurityInterceptor被拦截下来，因为发现用户未认证抛出AccessDeniedException异常
- 异常在ExceptionTranslationFilter中被捕获，ExceptionTranslationFilter通过调用LoginUrlAuthenticationEntryPoint#commence方法给客户端返回302，要求客户端重定向到/login页面
- 客户端发起/login请求
- /login请求被DefaultLoginPageGeneratingFilter过滤器拦截下来，并在该过滤器中返回登录页面

引入Starter依赖后，Spring Boot做了很多事情:
- 开启Spring Security的自动化配置，自动创建一个名叫springDSecurityFilterChain的过滤器，注入到Spring容器中，负责所有安全的事情，包括认证，授权等，实际是里面的过滤器链处理的;
- 创建一个UserDetailsService的实例，负责提供用户数据，默认的用户是基于内存的用户，用户名是user，密码随机生成;
- 给用户生成默认的登录页面
- 开启CSRF攻击防御
- 开启会话固定攻击防御
- 集成X-XSS-Protection
- 集成X-Frame-Options以防止单击劫持

spring security定义了UserDetails接口定义用户对象，提供这个接口的是UserDetailsService，参数是一个username，开发者要自己实现，Spring Security也提供了一些实现，如下图:
![](./UserDetailsService.png)

- UserDetailsManager, 在UserDetailsService基础上额外添加了一些操作用户的方法;
- JdbcDaoImpl通过spring-jdbc实现通过数据库查询用户;
- InMemoryUserDetailsManager,实现基于内存的用户增删改查的方法;
- JdbcUserDetailsManager, 通过jdbc实现用户的增删改查;
- CachingUserDetailsService, 缓存的方式;
- UserDetailsServiceDelegator, 提供UserDetailsService懒加载的功能；
- ReactiveUserDetailsServiceAdapter。 为WebFlux模块定义的UserDetailsService实现

如果没有提供，使用的就是InMemoryUserDetailsManager实现。Spring Security自动化配置的类是UserDetailsServiceAutoConfiguration，Spring Security提供了UserDetails的一个实现叫User，
