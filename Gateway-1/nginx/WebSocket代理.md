为了将一对client/server之间的HTTP/1.1协议转换为WebSocket洗衣，需要使用HTTP/1.1协议中的协议切换机制。但是有一些细微的差别，因为Upgrade头是一个hop-by-hop头，是不允许从一个client转发到被代理的服务，在代理转发中，客户端可能会使用CONNECT方法来绕过这个问题，这种方式不能用于反向代理，因为客户端不知道任何的代理服务器，需要在代理服务器上做一些特殊处理。从版本1.3.13开始，nginx实现了特殊的操作模式，允许在一个client与被代理的server间直接建立隧道，如果被代理的服务返回101代码，客户端通过请求中的Upgrade标头请求协议切换。如上所述，包括Upgrade和Connection在内的逐跳标头不会从客户端传递到代理服务器，因此为了让代理服务器了解客户端将协议切换到WebSocket的意图，这些标头必须显式传递:
```nginx
location /chat/ {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}

```
一个更复杂的示例，其中对代理服务器的请求中Connection标头字段的值取决于客户端请求标头中Upgrade字段的存在:
```nginx
http {
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {
        ...

        location /chat/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
        }
    }
```
默认情况下，如果被代理的服务器在60s内没有传输任何数据，那么连接将会被关闭。这个超时时间可以通过proxy_read_time命令修改，另外，被代理的服务器可以做一些配置，可以周期性的发送ping帧来重置超时时间，也可以检查连接是否没断