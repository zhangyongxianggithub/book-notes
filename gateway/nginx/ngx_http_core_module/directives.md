- location
* syntax location [=|~|~*|^~] uri {...} location @name {...}
* default --
* Context server,location
根据请求的URI设置配置。匹配标准化的URI，也就是PATH转义之前的URI，支持相对路径.与..，而且可以把相邻的多个/压缩为一个/。一个location要么是前缀字符串定义，要么是正则表达式定义。正则表达式在路径前面使用～*(忽略大小写)修饰或者～(大小写敏感)修饰。为了找到与给定请求匹配的位置，nginx 首先检查使用前缀字符串（前缀位置）定义的位置。其中，匹配前缀最长的位置被选中并临时缓存（记住）。然后匹配正则表达式，以正则表达式位置在配置文件中定义的顺序匹配。只要找到匹配的正则表达式，就终止匹配并使用匹配的正则表达式位置，如果没有匹配的正则表达式位置，则使用前面记住的前缀位置的配置。
位置块可以嵌套，下面会提到一些例外情况。
对于macOS和Cygwin等不区分大小写的操作系统，匹配前缀字符串会忽略大小写 (0.7.7)。但是，比较仅限于一字节语言环境。
正则表达式可以包含捕获变量，捕获变量可以被随后的其他指令使用 (0.7.40)。
如果最长匹配前缀位置具有^~修饰符，则不检查正则表达式。
此外，使用=修饰符可以定义URI和location的精确匹配。如果找到精确匹配，则搜索终止。例如，如果/请求频繁发生，定义location = /将加速这些请求的处理，因为搜索在第一次比较后立即终止。这样的location显然不能包含嵌套location。
0.7.1～0.8.41的版本中，只要请求匹配了前缀表达式就不会检查正则表达式的位置。举个例子:
```nginx
location = / {
    [ configuration A ]
}

location / {
    [ configuration B ]
}

location /documents/ {
    [ configuration C ]
}

location ^~ /images/ {
    [ configuration D ]
}

location ~* \.(gif|jpg|jpeg)$ {
    [ configuration E ]
}
```
/请求将匹配配置A，/index.html请求将匹配配置B，/documents/document.html请求将匹配配置C，/images/1.gif请求将匹配配置D，/documents/1.jpg请求将匹配配置E。
@前缀定义了一个命名location。这样的位置不用于常规请求处理，而是用于请求重定向。它们不能嵌套，也不能包含嵌套位置。如果位置由以/字符结尾的前缀字符串定proxy_pass、fastcgi_pass、uwsgi_pass、scgi_pass、memcached_pa​​ss或grpc_pass处理，则默认执行特殊逻辑处理。如果发送的请求的URI没有尾部/，nginx将返回301永久重定向响应，重定向的地址为末尾加上/的URI请求。如果不希望这样，可以定义如下的location: 
```nginx
location /user/ {
    proxy_pass http://user.example.com;
}

location = /user {
    proxy_pass http://login.example.com;
}
```
