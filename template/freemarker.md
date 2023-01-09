# 模板开发指南
## 入门
### 模板+数据模型=输出
### 数据模型一览
### 模板一览
## 数值，类型
### 基本内容
### 类型
## 模板
### 总体结构
### 指令
### 表达式
### 插值
## 其他
### 自定义指令
### 在模板中定义变凉
### 命名空间
### 替换(方括号)语法
# 程序开发指南
## 入门
### 创建Configuration实例
首创建`freemarker.template.Configuration`实例，然后调整设置，`Configuration`实例是存储FreeMarker应用级设置的核心部分，同时，它处理创建和缓存预解析模板的工作。也许你只在应用生命周期的开始执行一次:
```java
// Create your Configuration instance, and specify if up to what FreeMarker
// version (here 2.3.22) do you want to apply the fixes that are not 100%
// backward-compatible. See the Configuration JavaDoc for details.
Configuration cfg = new Configuration(Configuration.VERSION_2_3_22);

// Specify the source where the template files come from. Here I set a
// plain directory for it, but non-file-system sources are possible too:
cfg.setDirectoryForTemplateLoading(new File("/where/you/store/templates"));

// Set the preferred charset template files are stored in. UTF-8 is
// a good choice in most applications:
cfg.setDefaultEncoding("UTF-8");

// Sets how errors will appear.
// During web page *development* TemplateExceptionHandler.HTML_DEBUG_HANDLER is better.
cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
```
应该使用单例实例配置。不需要重复创建`Configuration`实例；它的代价很高，尤其是会丢失缓存。`Configuration`实例就是应用级别的单例。当使用多线程应用程序(比如Web网站)，`Configuration`实例中的设置就不能被修改。它们可以被视作为有效的不可改变的对象，也可以继续使用安全发布技术(参考JSR 133和相关的文献)来保证实例对其它线程也可用。比如，通过final或volatile字段来声明实例，或者通过线程安全的IoC容器，但不能作为普通字段。(Configuration中不处理修改设置的方法是线程安全的。)
### 创建数据模型
在简单的示例中你可以使用java.lang和java.util包中的类，还有用户自定义的Java Bean来构建数据对象:
- 使用java.lang.String来构建字符串;
- 使用java.lang.Number来派生数字类型;
- 使用java.lang.Boolean来构建布尔值;
- 使用java.util.List或Java数组来构建序列;
- 使用java.util.Map来构建哈希表;
- 使用自定义的bean类来构建哈希表，bean中的项和bean的属性对应。比如，product的price属性(getProperty())可以通过product.price获取。(bean的action也可以通过这种方式拿到；要了解更多可以参看[这里](file:///Users/zhangyongxiang/Downloads/FreeMarker_2.3.23_Manual_zh_CN/pgui_misc_beanwrapper.html);

如果配置设置项object_wrapper的值是用于所有真实步骤，这里描述的行为才好用。任何由ObjectWrapper包装成的哈希表可以用作根root，也可以在模板中和点、 []操作符使用。如果不是包装成哈希表的对象不能作为根root，也不能像那样在模板中使用。
### 获取模版
模板代表了`freemarker.template.Template`实例。典型的做法是从`Configuration`实例中获取一个`Template`实例。无论什么时候你需要一个模板实例， 都可以使用它的`getTemplate`方法来获取。在之前设置的目录中的test.ftl文件中存储示例模板，那么就可以这样来做:
```java
Template temp = cfg.getTemplate("test.ftl");
```
当调用这个方法的时候，将会创建一个test.ftl的Template实例，通过读取/where/you/store/templates/test.ftl文件，之后解析(编译)它。Template 实例以解析后的形式存储模板， 而不是以源文件的文本形式。Configuration缓存Template实例，当再次获得test.ftl的时候，它可能再读取和解析模板文件了， 而只是返回第一次的Template实例。
### 合并模板语数据模型
### 将代码放在一起
## 数据模型
### 基本内容
### 标量
### 容器
### 方法
### 指令
### 结点变量
### 对象包装
## 配置
### 基本内容
### 共享变量
### 配置设置
### 模板加载
### 错误控制
### 不兼容改进设置
## 其他
### 变量，范围
当调用Template.process方法时，它会在方法内部创建一个Environment对象，在process返回之前一直使用，该对象存储模板执行时的运行状态信息。除了这些，他还会存储有模板中指令，如assign、macro、local、global创建的变量，它不会尝试修改传递给process的数据模型对象，也不会创建或替换存储在配置中的共享变量。FreeMarker查找变量的优先级如下:
- Environment变量
  - 如果在循环中，在循环变量的集合中，循环变量由list指令等创建;
  - 如果在macro中，在macro的局部变量集合中，局部变量可以由local指令创建，而且，宏的参数也是局部变量;
  - 在当前的命名空间中，可以使用assign指令将变量放到一个命名空间中;
  - 在由global指令创建的变量集合中。FTL将它们视为数据模型的普通成员变量一样来控制它们。也就是说，它们在所有的命名空间中都可见，
    你也可以像访问一个数据模型中的数据一样来访问它们。
- 传递给process方法的数据模型对象
- Configuration对象存储的共享变量集合
  
在实际操作中，来自模板设计者的观点是这6种情况应该只有4种，因为从那种观点来看，后面3种(由global创建的变量，真实的数据模型对象，共享变量)共同构成了全局变量的集合。
### 字符集问题
### 多线程
在多线程运行环境中，Configuration实例，Template实例和数据模型应该是永远不能改变(只读)的对象。也就是说，创建和初始化它们(如使用set等方法)之后，就不能再修改它们了(比如不能再次调用set等修改方法)。这就允许我们在多线程环境中避免代价很大的同步锁问题。要小心Template实例；当使用了Configuration.getTemplate方法获得Template一个实例时，也许得到的是从模板缓存中缓存的实例，这些实例都已经被其他线程使用了，所以不要调用它们的set方法(当然调用process方法还是不错的)。如果只从同一个独立线程中访问所有对象，那么上面所述的限制将不会起作用。使用FTL来修改数据模型对象或者共享变量是不太可能的，除非将方法(或其他对象)放到数据模型中来做。我们不鼓励你编写修改数据模型对象或共享变量的方法。多试试使用存储在环境对象(这个对象是为独立的Template.process调用而创建的，用来存储模板处理的运行状态)中的变量，所以最好不要修改那些由多线程使用的数据。要获取更多信息，请阅读：变量，范围。
### Bean的包装
### 日志
### 在Servlet中使用FreeMarker
### 为FreeMarker配置安全策略
### 遗留的XML包装实现
### 和Ant一起使用FreeMarker
### Jython包装器
# 模板语言参考
## 内建函数参考
## 指令参考
## 特殊变量参考
## FTL中的保留名称
## 废弃的FTL结构
# XML处理指南
## 前言
## 揭示XML文档
## 必要的XML处理
## 声明的XML处理
