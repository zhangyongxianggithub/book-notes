HTTP提供了用于权限控制欲认证的通用框架，最常用的HTTP认证方案是HTTP Basic认证.
## 通用的HTTP认证框架
RFC-7235定义了一个HTTP身份验证框架，服务器可以用来针对客户端的请求发送challenge（质询信息），客户端则可以用来提供身份验证凭证，工作流程如下:
- 服务器向客户端返回401（Unauthorized）状态码，并在WWW-Authenticate首部提供如何进行验证的信息，其中至少包含一种质询方式;
- 之后有意向证明自己身份的客户端可以再新的请求中添加Authorization首部字段进行验证，字段值为身份凭证信息;

### 代理认证
与正常的认证基本一样，区别在于独立的头信息与响应状态码，代理认证，询问质疑的状态码是407，提供Proxy-Authenticate相应头，使用Proxy-Authorization头提供身份认证信息给代理服务器;
### 访问拒绝
当服务器收到一个合法的认证信息时，若认证没有请求资源的权限，则服务器返回403，说明权限不够;
### 跨域图片认证
### HTTP认证的字符与编码
统一使用UTF-8
### WWW-Authenticate与Proxy-Authenticate
WWW-Authenticate 与 Proxy-Authenticate 响应消息首部指定了为获取资源访问权限而进行身份验证的方法。它们需要明确要进行验证的方案，这样希望进行授权的客户端就知道该如何提供凭证信息。这两个首部的语法形式如下：
> WWW-Authenticate: <type> realm=<realm>
Proxy-Authenticate: <type> realm=<realm>

type指的是验证方案，realm用来描述进行保护的区域，或者指代保护的范围。
### Authorization与Proxy-Authorization首部
Authorization 与 Proxy-Authorization 请求消息首部包含有用来向（代理）服务器证明用户代理身份的凭证。这里同样需要指明验证的类型，其后跟有凭证信息，该凭证信息可以被编码或者加密，取决于采用的是哪种验证方案。
> Authorization: <type> <credentials>
Proxy-Authorization: <type> <credentials>
### 验证方案
通用 HTTP 身份验证框架可以被多个验证方案使用。不同的验证方案会在安全强度以及在客户端或服务器端软件中可获得的难易程度上有所不同。最常见的验证方案是“基本验证方案”（"Basic"），该方案会在下面进行详细阐述。 IANA 维护了一系列的验证方案，除此之外还有其他类型的验证方案由虚拟主机服务提供，例如 Amazon AWS 。常见的验证方案包括：
- Basic: base64编码凭证;
- Bearer: bearer令牌通过OAuth2.0保护资源;
- Digest: md5散列活着hash散列值;
- HOBA: HTTP Origin-Bound认证，基于数字签名;
- Mutual:
- AWS4-HMAC-SHA256

## 基本验证方案
"Basic" HTTP 验证方案是在 RFC 7617中规定的，在该方案中，使用用户的 ID/密码作为凭证信息，并且使用 base64 算法进行编码。由于ID与密码是以明文的形式传输的，所以基本验证方案是不安全的；

