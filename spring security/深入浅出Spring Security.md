# 第一章 Spring Security架构概览
Spring Security方便集成在Spring Boot于Spring Cloud项目中。
## Spring Security简介
java安全管理的实现方案
- Shiro
- Spring Security
- 开发者自己实现
Spring Security最早叫做Acegi Security，是基于Spring的一种框架，后来改名了叫Spring Security，一直是配置繁琐；但是Spring Boot的出现解决了这个问题，因为可以提供自动化的配置。
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
也可以引入第三方的支持或者自定义认证逻辑。
Spring Security支持URL请求授权、方法访问授权、SpEL访问控制、域对象安全、动态权限配置、RBAC模型等。
## Spring Security整体架构
<<<<<<< HEAD
=======
在Spring Security的设计中，认证（Authentication）与授权（Authorization）是分开的，无论使用什么样的授权方式都不会影响授权；用户的认证信息主要是由Authentication的实现类来保存，Authentication接口如下：
```java
/*
 * Copyright 2004, 2005, 2006 Acegi Technology Pty Limited
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
Spring Security中的认证的工作主要由AuthenticationManager负责；该接口的定义如下：
```java
/*
 * Copyright 2004, 2005, 2006 Acegi Technology Pty Limited
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
/*
 * Copyright 2004, 2005, 2006 Acegi Technology Pty Limited
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
由于Authentication拥有众多的实现类，不同的实现类由不同的AuthenticationProvider来处理，所以又个supports方法，用来判断Provider是否支持对应的Authentication；在一个完整的认证流程中，可能支持多个Provider，这些Provider统一由Manager来管理，ProviderManager由一个可选的parent，当所有的AuthenticationProvider都处理失败时，就会调用parent认证。相当于一个备用的认证方式。
授权有2个关键的接口
- AccessDecisionManager
- AccessDecisionVoter
AccessDecisionVoter是一个投票器，用于检查用户是否应该具备应有的角色；AccessDecisionManager是一个决策器，用来决定此次访问是否被允许；它们都有众多的实现类，AccessDecisionManager会挨个遍历AccessDecisionVoter，决定是否允许用户访问；有点类似于AuthenticationProvider与ProviderManager的关系。
在Spring Security中，用户请求资源需要的角色会被封装成ConfigAttributes，投票器做的事情就是判断ConfigAttributes与当前用户的角色是否匹配。
在Spring Security中，认证与授权都是通过过滤器来完成的，Spring Security的过滤器如下：

|过滤器|过滤器的作用|是否默认加载|
|:---:|:---:|:---:|
|ChannelProcessingFilter|过滤请求协议如HTTTP与HTTPS|NO|
|WebAsyncManagerIntegrationFilter|将WebAsyncManager与Spring Security上下文进行集成|YES|
||||

>>>>>>> f0b67b9 (update)
