# Overview
包含参考文档与Spring Authorization Server的指南
## Introducing Spring Authorization Server
Spring Authorization Server是一个框架，这个框架提供OAuth 2.1与OpenID Connect 1.0规范的实现还有其他相关的规范，它建立在Spring Security的基础上，可以为创建OpenID Connect 1.0身份提供者与OAuth2 Authorization Server产品提供安全的，轻量级的，可定制的基础设施.
## Feature List
TODO
# Getting Started
如果您刚刚开始使用 Spring Authorization Server，以下部分将引导您创建您的第一个应用程序。
## System Requirements
SAS需要Java8以上版本的运行时环境
## Installing Spring Authorization Server
Spring Authorization Server可以在你已经使用 Spring Security 的任何地方使用。开始使用Spring Authorization Server的最简单方法是创建基于Spring Boot的应用程序。 您可以使用start.spring.io生成基本项目或使用默认授权服务器示例作为指导。 然后将Spring Authorization Server添加为依赖项，如下例所示:
```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-oauth2-authorization-server</artifactId>
    <version>0.3.1</version>
</dependency>
```
## Developing Your First Application
在开始前，你需要在一个Spring的@Configuration类中定义一些必须的组件@Bean，如下代码所示:
```java
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.UUID;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.OAuth2AuthorizationServerConfiguration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.config.ClientSettings;
import org.springframework.security.oauth2.server.authorization.config.ProviderSettings;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;

@Configuration
public class SecurityConfig {

	@Bean (1)
	@Order(1)
	public SecurityFilterChain authorizationServerSecurityFilterChain(HttpSecurity http)
			throws Exception {
		OAuth2AuthorizationServerConfiguration.applyDefaultSecurity(http);
		http
			// Redirect to the login page when not authenticated from the
			// authorization endpoint
			.exceptionHandling((exceptions) -> exceptions
				.authenticationEntryPoint(
					new LoginUrlAuthenticationEntryPoint("/login"))
			);

		return http.build();
	}

	@Bean (2)
	@Order(2)
	public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http)
			throws Exception {
		http
			.authorizeHttpRequests((authorize) -> authorize
				.anyRequest().authenticated()
			)
			// Form login handles the redirect to the login page from the
			// authorization server filter chain
			.formLogin(Customizer.withDefaults());

		return http.build();
	}

	@Bean (3)
	public UserDetailsService userDetailsService() {
		UserDetails userDetails = User.withDefaultPasswordEncoder()
				.username("user")
				.password("password")
				.roles("USER")
				.build();

		return new InMemoryUserDetailsManager(userDetails);
	}

	@Bean (4)
	public RegisteredClientRepository registeredClientRepository() {
		RegisteredClient registeredClient = RegisteredClient.withId(UUID.randomUUID().toString())
				.clientId("messaging-client")
				.clientSecret("{noop}secret")
				.clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
				.authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
				.authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
				.authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
				.redirectUri("http://127.0.0.1:8080/login/oauth2/code/messaging-client-oidc")
				.redirectUri("http://127.0.0.1:8080/authorized")
				.scope(OidcScopes.OPENID)
				.scope("message.read")
				.scope("message.write")
				.clientSettings(ClientSettings.builder().requireAuthorizationConsent(true).build())
				.build();

		return new InMemoryRegisteredClientRepository(registeredClient);
	}

	@Bean (5)
	public JWKSource<SecurityContext> jwkSource() {
		KeyPair keyPair = generateRsaKey();
		RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
		RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
		RSAKey rsaKey = new RSAKey.Builder(publicKey)
				.privateKey(privateKey)
				.keyID(UUID.randomUUID().toString())
				.build();
		JWKSet jwkSet = new JWKSet(rsaKey);
		return new ImmutableJWKSet<>(jwkSet);
	}

	private static KeyPair generateRsaKey() { (6)
		KeyPair keyPair;
		try {
			KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
			keyPairGenerator.initialize(2048);
			keyPair = keyPairGenerator.generateKeyPair();
		}
		catch (Exception ex) {
			throw new IllegalStateException(ex);
		}
		return keyPair;
	}

	@Bean (7)
	public ProviderSettings providerSettings() {
		return ProviderSettings.builder().build();
	}

}
```
这是快速入门的最低配置。 要了解每个组件的用途，请参阅以下说明:
- 一个用于Protocol Endpoints的Spring Security过滤器链;
- 一个用于authentication的Spring Security过滤器链;
- 一个用于要检索认证的用户的UserDetailsService实例对象;
- 一个用于管理客户端的RegisteredClientRepository实例对象;
- 一个用于签名access token的`com.nimbusds.jose.jwk.source.JWKSource`实例;
- 一个java.security.KeyPair实例，用于创建JWKSource;
- 一个ProviderSettings对象来配置SAS
# 配置模型
## 默认配置
`OAuth2AuthorizationServerConfiguration`是一个@Configuration类，为一个SAS提供了最小化的默认配置。`OAuth2AuthorizationServerConfiguration`使用`OAuth2AuthorizationServerConfigurer`来应用默认的配置并注册一个SecurityFilterChain类型的Bean，这个链中包含所有支持OAuth2 认证服务器的基础设施组件。`OAuth2AuthorizationServerConfiguration.applyDefaultSecurity(HttpSecurity)`是一个方便的静态工具方法，可以将OAuth2的默认安全配置应用到HttpSecurity.OAuth2认证服务器的SecurityFilterChain使用洗面的默认的protocol endpoint配置:
- OAuth2 Authentication endpoint
- OAuth2 Token endpoint
- OAuth2 Token Introspection endpoint
- OAuth2 Token Revocation endpoint
- OAuth2 Authorization Server Metadata endpoint
- JWK Set endpoint
- OpenID Connect 1.0 Provider Configuration endpoint
- OpenID Connect 1.0 UserInfo endpoint
下面的例子展示了如何用OAuth2AuthorizationServerConfiguration应用默认配置:
```java
@Configuration
@Import(OAuth2AuthorizationServerConfiguration.class)
public class AuthorizationServerConfig {

	@Bean
	public RegisteredClientRepository registeredClientRepository() {
		List<RegisteredClient> registrations = ...
		return new InMemoryRegisteredClientRepository(registrations);
	}

	@Bean
	public JWKSource<SecurityContext> jwkSource() {
		RSAKey rsaKey = ...
		JWKSet jwkSet = new JWKSet(rsaKey);
		return (jwkSelector, securityContext) -> jwkSelector.select(jwkSet);
	}

}
```
authorization_code 授权要求对资源所有者进行身份验证。 因此，除了默认的 OAuth2 安全配置外，还必须配置用户认证机制。下面的例子展示了如何注册一个JWTDEcoder
```java
@Bean
public JwtDecoder jwtDecoder(JWKSource<SecurityContext> jwkSource) {
	return OAuth2AuthorizationServerConfiguration.jwtDecoder(jwkSource);
}
```

