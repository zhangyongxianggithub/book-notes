# Handling Multipart File Uploads
Spring Boot包含了servlet5的`Part`API支持文件上传，默认情况下，Spring Boot配置Spring MVC的单个请求中一个文件不超过1MB，总的文件大小不能超过10MB，你可以改变通过`MultipartProperties`中的属性改变这些行为。比如如果你不想限制文件大小可以设置`spring.servlet.multipart.max-file-size=-1`。
当您希望在Spring MVC控制器处理程序方法中以`@RequestParam`修饰的`MultipartFile`类型参数的形式接收编码文件数据时，multipart支持非常有用。建议使用Spring对Multipart的内置支持，而不是引入额外的依赖项(例如Apache Commons File Upload)。
