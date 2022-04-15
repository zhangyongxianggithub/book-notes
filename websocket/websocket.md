# WebSocket
WebSocket是一种网络传输协议，可以在单个TCP连接上进行全双工通信，位于OSI模型的应用层。WebSocket协议在2011年由IETF标准化为RFC-6455，后由RFC-7936补充规范。Web IDL的WebSocket API由W3C标准化。
WebSocket使得客户端与服务器之间的数据交换变得更加简单，允许服务器主动向客户端推送数据。在WebSocket API中，浏览器与服务器只需要完成一次握手，2者之间就可以创建持久性的连接，并进行双向数据传输。
## 简介
WebSocket是一种与HTTP不同的协议，都位于OSI模型的应用层，并且都依赖于传输层的TCP协议；虽然它们不同，但是RFC-6455中规定：it is designed to work over HTTP ports 80 and 443 as well as to support HTTP proxies and intermmediaries(WebSocket通过HTTP端口80与443进行工作)并支持HTTP代理与中介)，从而使其于HTTP协议兼容，为了实现兼容性，WebSocket握手使用HTTP Upgrade头从HTTP协议更改为WebSocket协议。
WebSocket协议支持Web浏览器与Web服务器之间的交互，具有较低的开销，便于实现客户端与服务器的实时数据传输。服务器可以通过标准化的方式来实现，而无需客户端首先请求内容，并允许消息在保持连接打开的同时来回传递。通过这种方式，可以在客户端与服务器之间进行双向持续对话。通信通过TCP端口80与443完成，这在防火墙阻止Web网络连接的环境下是有益的。COMET之类的技术已非标准化的方式实现了类似的双向通信.
大多数浏览器都支持WebSocket协议。WebSocket协议规范将ws与wss定义为新的统一资源定位符，支持大部分的URI组件定义。
## 推送技术
- 轮询：每隔一段时间发起HTTP请求，包含头部，数据占比低，延迟性比较高;
- Comet: 长连接，也需要反复发出请求;
- webSocket
```javascript
ws://example.com/wsapi
wss://secure.example.com/wsapi
```
## 优点
- 较少的控制开销，用于协议控制的数据包头部小;
- 更强的实时性，全双工，服务器可以随时给客户端发送数据;
- 保持连接状态，有状态的协议，连接建立后，可以省略部分信息，HTTP是无状态的，每次都要携带所有的信息;
- 更好的二进制支持，WebSocket定义了二进制帧，可以轻松的处理二进制内容;
- 可以支持拓展，WebSocket定义了扩展，用户可以定义子协议
- 更好的压缩效果;
## 握手协议
webSocket通过HTTP/1.1的101状态码握手
一个握手请求如下:
```javascript
GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Origin: http://example.com
Sec-WebSocket-Protocol: chat, superchat
Sec-WebSocket-Version: 13
```
```javascript
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Sec-WebSocket-Protocol: chat
```
- Connection必须设置为Upgrade,表示客户端希望升级
- Upgrade必须设置为WebSocket，表示希望升级到WebSocket协议
- Sec-WebSocket-Key是随机的字符串，服务器会用这些数据来构造出一个SHA-1的信息摘要，把Sec-WebSocket-Key加上一个特殊的字符串258EAFA5-E914-47DA-95CA-C5AB0DC85B11，然后计算SHA-1摘要，之后进行base64编码。将结果作为Sec-WebSocket-Accept头的值，返回给客户端，如此操作，可以尽量避免普通HTTP请求被误认为WebSocket协议.
- Sec-WebSocket-Version,表示支持的webSocket的版本；
- Origin字段是必须的，如果缺少origin字段，WebSocket服务器需要回复HTTP 403 状态码（禁止访问）
- 其他一些定义在HTTP协议中的字段，如Cookie等，也可以在Websocket中使用;
## 服务器支持
- jetty
- Tomcat
- Nginx
## 客户端的API
创建WebSocket对象，就会进行连接
```javascript
var ws = new WebSocket('ws://localhost:8080');
```
webSocket.readyState的状态值
- CONNECTING：值为0，表示正在连接;
- OPEN：值为1，表示连接成功，可以通信了;
- CLOSING：值为2，表示连接正在关闭;
- CLOSED：值为3，表示连接已经关闭，或者打开连接失败;
```javascript
switch (ws.readyState) {
  case WebSocket.CONNECTING:
    // do something
    break;
  case WebSocket.OPEN:
    // do something
    break;
  case WebSocket.CLOSING:
    // do something
    break;
  case WebSocket.CLOSED:
    // do something
    break;
  default:
    // this never happens
    break;
}
```
WebSocket对象的一些回调方法
```javascript
ws.onopen = function () {
  ws.send('Hello Server!');//连接成功后的回调方法
}
```
```javascript
ws.addEventListener('open', function (event) {
  ws.send('Hello Server!');
});
```
```javascript
// 连接关闭的回调方法
ws.onclose = function(event) {
  var code = event.code;
  var reason = event.reason;
  var wasClean = event.wasClean;
  // handle close event
};

ws.addEventListener("close", function(event) {
  var code = event.code;
  var reason = event.reason;
  var wasClean = event.wasClean;
  // handle close event
});
```
```javascript
// 收到服务器数据的回调方法
ws.onmessage = function(event) {
    //  判断数据类型
    if(typeof event.data === String) {
        console.log("Received data string");
    }

    if(event.data instanceof ArrayBuffer){
        var buffer = event.data;
        console.log("Received arraybuffer");
    }
};

ws.addEventListener("message", function(event) {
  var data = event.data;
  // 处理数据
});
```
```javascript
ws.send('your message');//发送文本数据
var file = document// 发送blob数据
    .querySelector('input[type="file"]')
    .files[0];
ws.send(file);
// Sending canvas ImageData as ArrayBuffer 发送ArrayBuffer数据
var img = canvas_context.getImageData(0, 0, 400, 320);
var binary = new Uint8Array(img.data.length);
for (var i = 0; i < img.data.length; i++) {
  binary[i] = img.data[i];
}
ws.send(binary.buffer);
```
webSocket.bufferedAmount可以用来判断还有多少字节没有发送出去
```javascript
var data = new ArrayBuffer(10000000);
socket.send(data);

if (socket.bufferedAmount === 0) {
  // 发送完毕
} else {
  // 发送还没结束
}
```
报错时的回调函数
```javascript
socket.onerror = function(event) {
  // handle error event
};

socket.addEventListener("error", function(event) {
  // handle error event
});
```

