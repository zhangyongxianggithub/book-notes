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

