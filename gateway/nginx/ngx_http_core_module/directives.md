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
- server_name
* 语法: server_name name ...;
* 默认: server_name "";
* 上下文: server
设置虚拟服务器的名字，比如
```conf
server {
    server_name example.com www.example.com;
}
```
第一个出现的名字成为主要服务器名字.名字可以包含星号*，*号可以放到名字的开头与结尾
```conf
server {
    server_name example.com *.example.com www.example.*;
}
```
这样的名字叫做通配符名字.
上面的2个名字可以组合成一个
```conf
server {
    server_name .example.com;
}
```
也可以在名字中使用正则表达式，需要在名字前面放上波浪线~
```conf
server {
    server_name www.example.com ~^www\d+\.example\.com$;
}
```
正则表达式可以包含捕获的内容，可以在后面的指令中使用
```conf
server {
    server_name ~^(www\.)?(.+)$;

    location / {
        root /sites/$2;
    }
}

server {
    server_name _;

    location / {
        root /sites/default;
    }
}
```
在正则表达式中的命名捕获会创建变量，在后面其他的指令中可以使用这个变量。
```nginx
server {
    server_name ~^(www\.)?(?<domain>.+)$;

    location / {
        root /sites/$domain;
    }
}

server {
    server_name _;

    location / {
        root /sites/default;
    }
}
```
如果指令被设置为$hostname，那么就会使用服务器的hostname，可以描述一个空的服务器名字
```nginx
server {
    server_name www.example.com "";
}
```
这样服务器可以处理没有Host头的请求，而不是必须是默认的服务器名字（address::port），这是默认的设置。在0.8.48版本以前，默认使用物理服务器的hostname，通过名字搜索虚拟服务器的时候，如果名字匹配了多个虚拟服务器的名字，比如同时匹配的通配符名字与正则表达式名字，第一个匹配的名字的优先级更高，优先级如下:
- 精确的名字
- 以*开始的最长通配符匹配的名字;
- 以*结尾的最长通配符匹配的名字;
- 第一个匹配的正则表达式名字.


