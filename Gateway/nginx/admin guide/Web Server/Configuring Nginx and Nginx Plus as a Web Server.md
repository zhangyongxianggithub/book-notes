## Configuring Locations
Nginx可以根据请求URI将流量发送到不同的代理或提供不同的文件。这些块是使用放置在server指令中的location指令定义的。
比如: 例如，您可以定义三个位置块来指示虚拟服务器将一些请求发送到一个代理服务器，将一些请求发送到另一个代理服务器，并通过从本地文件系统传递文件来处理其余请求。
Nginx根据所有location指令的参数测试请求URI，并执行匹配的位置中定义的指令。在每个location块内，通常可以（除了少数例外）放置更多location指令，以进一步优化特定请求组的处理。
location指令有两种类型的参数：前缀字符串（路径名）和正则表达式。对于匹配前缀字符串的请求URI，它必须以前缀字符串开头。
以下带有路径名参数的例子中，location匹配URI以/some/path/开头的请求，例如/some/path/document.html。它与/my-site/some/path不匹配，因为/some/path没有出现在该URI的开头。
```nginx
location /some/path/ {
    #...
}
```
正则表达式前面带有波浪号 (~) 用于区分大小写的匹配，或波浪号-星号 (~*) 用于不区分大小写的匹配。 以下示例的location匹配在任何URI包含字符串.html或.htm的请求。
```nginx
location ~ \.html? {
    #...
}
```
为了找到请求URI的最佳匹配位置，Nginx首先匹配前缀字符串，然后匹配正则表达式。正则表达式具有更高的优先级，除非前缀字符串使用了^~修饰符。 nginx在前缀字符串中选择最具体的一个（即最长最完整匹配前缀字符串）。下面给出了选择处理请求的位置的确切逻辑:
- 匹配所有前缀字符串定义的location;
- =（等号）修饰符定义URI和前缀字符串的精确匹配。如果找到精确匹配，则停止搜索;
- 如果^~(caret-tilde) 修饰符出现在最长匹配前缀字符串前面，则不检查正则表达式;
- 缓存最长匹配的前缀字符串location
- 匹配所有正则表达式定义的location;
- 当找到第一个匹配的正则表达式时停止处理并使用相应的location;
- 如果没有正则表达式匹配，则使用前面缓存的前缀字符串location;
location包含解析请求的指令定义——提供静态文件或将请求传递给代理服务器。在以下示例中，匹配第一个location的请求将被提供/data目录下的文件，匹配第二个location的请求将被传递到www.example.com服务器。
```nginx
server {
    location /images/ {
        root /data;
    }

    location / {
        proxy_pass http://www.example.com;
    }
```
root指令指定静态文件的文件系统路径，nginx会在路径中搜索要提供给请求的静态文件。搜索时请求URI被追加到root后形成要提供的的静态文件的完整path路径。 在上面的示例中，为响应对/images/example.png的请求，nginx交付文件/data/images/example.png。
proxy_pass指令将请求传递给匹配的location中定义的代理服务器。然后将来自代理服务器的响应传递回客户端。 在上面的示例中，所有具有不以/images/开头的URI的请求都被传递到代理服务器。
