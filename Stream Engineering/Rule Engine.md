# 开源的方案
- incubator-kie-drools
- easy-rules
- liteflow
- radar
- rulebook
- QLExpress
- ice
- RuleEngine
- jetlinks/rule-engine
- evrete/evrete
# liteflow
轻量请打的规则引擎框架，用于复杂的组件化业务的编排，使用DSL规则驱动整个复杂业务，实现平滑刷新热部署，支持多种脚本语言的嵌入。特点
- 强大的EL: 简单低学习成本的EL，丰富的关键字，完成任意模式的逻辑编排
- 皆为组件: 独特的设计理念，所有逻辑皆为组件，上下文隔离，组件单一指责，组件可以复用并互相解耦
- 脚本支持: 可以使用7种脚本语言写逻辑Java、Groovy、Js、Python、Lua、QLExpress、Aviator
- 规则存储: 支持把规则和脚本存储在任何关系型数据库，支持大部分的注册中心zk、nacos、etcd、appolo、redis
- 平滑热刷: 编排规则、脚本组件，不需要重启应用即时刷新，实时替换逻辑
- 支持度广: JDK8~JDK17,Spring 2.x ~ Spring 3.x
- 高级特性: 很多
# QLExpress
一个总台脚本引擎/解析工具，用于阿里的电商业务规则、表达式、特殊数学公式计算、语法分析、脚本二次定制等场景。特点:
- 线程安全，引擎运算过程中的产生的临时变量都是ThreadLocal的
- 执行高效，脚本编译可以缓存，临时变量采用了缓冲池的技术
- 弱类型脚本语言，和Groovy、Javascript类似，灵活
- 安全控制
- 代码少

添加依赖
```xml
<dependency>
  <groupId>com.alibaba</groupId>
  <artifactId>QLExpress</artifactId>
  <version>3.3.3</version>
</dependency>
```
语法
```java
//支持 +,-,*,/,<,>,<=,>=,==,!=,<>【等同于!=】,%,mod【取模等同于%】,++,--,
//in【类似sql】,like【sql语法】,&&,||,!,等操作符
//支持for，break、continue、if then else 等标准的程序控制逻辑
n = 10;
sum = 0;
for(i = 0; i < n; i++) {
   sum = sum + i;
}
return sum;

//逻辑三元操作
a = 1;
b = 2;
maxnum = a > b ? a : b;
```
- 不支持try-catch
- 注释只支持/****/,不支持单行注释
- 不支持Java8的lambda表达式
- 不支持for循环集合操作
- 弱类型语言，不要定义类型生命，不要用Template
- array的声明不一样
- min,max,round,print,println,like,in 都是系统默认函数的关键字，请不要作为变量名

```java
//java语法：使用泛型来提醒开发者检查类型
keys = new ArrayList<String>();
deviceName2Value = new HashMap<String, String>(7);
String[] deviceNames = {"ng", "si", "umid", "ut", "mac", "imsi", "imei"};
int[] mins = {5, 30};

//ql写法：
keys = new ArrayList();
deviceName2Value = new HashMap();
deviceNames = ["ng", "si", "umid", "ut", "mac", "imsi", "imei"];
mins = [5, 30];

//java语法：对象类型声明
FocFulfillDecisionReqDTO reqDTO = param.getReqDTO();
//ql写法：
reqDTO = param.getReqDTO();

//java语法：数组遍历
for(Item item : list) {
}
//ql写法：
for(i = 0; i < list.size(); i++){
    item = list.get(i);
}

//java语法：map遍历
for(String key : map.keySet()) {
    System.out.println(map.get(key));
}
//ql写法：
keySet = map.keySet();
objArr = keySet.toArray();
for (i = 0; i < objArr.length; i++) {
    key = objArr[i];
    System.out.println(map.get(key));
}
```
Java的对象操作
```java
import com.ql.util.express.test.OrderQuery;
//系统自动会import java.lang.*,import java.util.*;

query = new OrderQuery();           // 创建class实例，自动补全类路径
query.setCreateDate(new Date());    // 设置属性
query.buyer = "张三";                // 调用属性，默认会转化为setBuyer("张三")
result = bizOrderDAO.query(query);  // 调用bean对象的方法
System.out.println(result.getId()); // 调用静态方法
```
脚本中定义function
```java
function add(int a, int b){
    return a + b;
};

function sub(int a, int b){
    return a - b;
};

a = 10;
return add(a, 4) + sub(a, 9);
```
## 扩展操作符：Operator
替换关键字
```java
runner.addOperatorWithAlias("如果", "if", null);
runner.addOperatorWithAlias("则", "then", null);
runner.addOperatorWithAlias("否则", "else", null);

express = "如果 (语文 + 数学 + 英语 > 270) 则 {return 1;} 否则 {return 0;}";
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.execute(express, context, null, false, false, null);
```
定义一个Operator
```java
import java.util.ArrayList;
import java.util.List;

/**
 * 定义一个继承自com.ql.util.express.Operator的操作符
 */
public class JoinOperator extends Operator {
    public Object executeInner(Object[] list) throws Exception {
        Object opdata1 = list[0];
        Object opdata2 = list[1];
        if (opdata1 instanceof List) {
            ((List)opdata1).add(opdata2);
            return opdata1;
        } else {
            List result = new ArrayList();
            for (Object opdata : list) {
                result.add(opdata);
            }
            return result;
        }
    }
}
```
使用Operator
```java
//(1)addOperator
ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.addOperator("join", new JoinOperator());
Object r = runner.execute("1 join 2 join 3", context, null, false, false);
System.out.println(r); // 返回结果 [1, 2, 3]

//(2)replaceOperator
ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.replaceOperator("+", new JoinOperator());
Object r = runner.execute("1 + 2 + 3", context, null, false, false);
System.out.println(r); // 返回结果 [1, 2, 3]

//(3)addFunction
ExpressRunner runner = new ExpressRunner();
DefaultContext<String, Object> context = new DefaultContext<String, Object>();
runner.addFunction("join", new JoinOperator());
Object r = runner.execute("join(1, 2, 3)", context, null, false, false);
System.out.println(r); // 返回结果 [1, 2, 3]
```
## 绑定java类或者对象的method
```java
public class BeanExample {
    public static String upper(String abc) {
        return abc.toUpperCase();
    }
    public boolean anyContains(String str, String searchStr) {
        char[] s = str.toCharArray();
        for (char c : s) {
            if (searchStr.contains(c+"")) {
                return true;
            }
        }
        return false;
    }
}

runner.addFunctionOfClassMethod("取绝对值", Math.class.getName(), "abs", new String[] {"double"}, null);
runner.addFunctionOfClassMethod("转换为大写", BeanExample.class.getName(), "upper", new String[] {"String"}, null);

runner.addFunctionOfServiceMethod("打印", System.out, "println", new String[] { "String" }, null);
runner.addFunctionOfServiceMethod("contains", new BeanExample(), "anyContains", new Class[] {String.class, String.class}, null);

String express = "取绝对值(-100); 转换为大写(\"hello world\"); 打印(\"你好吗？\"); contains("helloworld",\"aeiou\")";
runner.execute(express, context, null, false, false);
```
## macro 宏定义
```java
runner.addMacro("计算平均成绩", "(语文+数学+英语)/3.0");
runner.addMacro("是否优秀", "计算平均成绩>90");
IExpressContext<String, Object> context = new DefaultContext<String, Object>();
context.put("语文", 88);
context.put("数学", 99);
context.put("英语", 95);
Object result = runner.execute("是否优秀", context, null, false, false);
System.out.println(r);
//返回结果true
```
## 编译脚本，查询外部需要定义的变量和函数
```java
String express = "int 平均分 = (语文 + 数学 + 英语 + 综合考试.科目2) / 4.0; return 平均分";
ExpressRunner runner = new ExpressRunner(true, true);
String[] names = runner.getOutVarNames(express);
for(String s:names){
    System.out.println("var : " + s);
}

//输出结果：
var : 数学
var : 综合考试
var : 英语
var : 语文
```
## 关于不定参数的使用
```java
@Test
public void testMethodReplace() throws Exception {
    ExpressRunner runner = new ExpressRunner();
    IExpressContext<String, Object> expressContext = new DefaultContext<String, Object>();
    runner.addFunctionOfServiceMethod("getTemplate", this, "getTemplate", new Class[]{Object[].class}, null);

    //(1)默认的不定参数可以使用数组来代替
    Object r = runner.execute("getTemplate([11,'22', 33L, true])", expressContext, null, false, false);
    System.out.println(r);
    //(2)像java一样,支持函数动态参数调用,需要打开以下全局开关,否则以下调用会失败
    DynamicParamsUtil.supportDynamicParams = true;
    r = runner.execute("getTemplate(11, '22', 33L, true)", expressContext, null, false, false);
    System.out.println(r);
}

//等价于getTemplate(Object[] params)
public Object getTemplate(Object... params) throws Exception{
    String result = "";
    for(Object obj:params){
        result = result + obj + ",";
    }
    return result;
}
```
## 关于集合的快捷写法
```java
@Test
public void testSet() throws Exception {
    ExpressRunner runner = new ExpressRunner(false, false);
    DefaultContext<String, Object> context = new DefaultContext<String, Object>();
    String express = "abc = NewMap(1:1, 2:2); return abc.get(1) + abc.get(2);";
    Object r = runner.execute(express, context, null, false, false);
    System.out.println(r);
    express = "abc = NewList(1, 2, 3); return abc.get(1) + abc.get(2)";
    r = runner.execute(express, context, null, false, false);
    System.out.println(r);
    express = "abc = [1, 2, 3]; return abc[1] + abc[2];";
    r = runner.execute(express, context, null, false, false);
    System.out.println(r);
}
```
## 集合的遍历
```java
//遍历map
map = new HashMap();
map.put("a", "a_value");
map.put("b", "b_value");
keySet = map.keySet();
objArr = keySet.toArray();
for (i = 0; i < objArr.length; i++) {
    key = objArr[i];
    System.out.println(map.get(key));
}
```
## 运行参数和API列表介绍
![QLExpressRunner](EL/qlexpress/qlexpress.jpeg)
### 属性开关
- `private boolean isPrecise = false;`: 是否需要高精度计算,不丢失精度
- `private boolean isShortCircuit = true;`: 是否使用逻辑短路
- `private boolean isTrace = false;`:  是否输出所有的跟踪信息，同时还需要log级别是DEBUG级别

### 调用入参
```java
/**
 * 执行一段文本
 * @param expressString 程序文本
 * @param context 执行上下文，可以扩展为包含ApplicationContext
 * @param errorList 输出的错误信息List
 * @param isCache 是否使用Cache中的指令集,建议为true
 * @param isTrace 是否输出详细的执行指令信息，建议为false
 * @param aLog 输出的log
 * @return
 * @throws Exception
 */
Object execute(String expressString, IExpressContext<String, Object> context, List<String> errorList, boolean isCache, boolean isTrace);
```
### 功能扩展API列表
实现`Operator`自定义操作符，通过`addFunction`或者`addOperator`注入到`ExpressRunner`中
```java
public abstract Object executeInner(Object[] list) throws Exception;
import java.util.ArrayList;
import java.util.List;

public class JoinOperator extends Operator {
    public Object executeInner(Object[] list) throws Exception {
        List result = new ArrayList();
        Object opdata1 = list[0];
        if (opdata1 instanceof List) {
            result.addAll((List)opdata1);
        } else {
            result.add(opdata1);
        }
        for (int i = 1; i < list.length; i++) {
            result.add(list[i]);
        }
        return result;
    }
}
```
function相关API
```java
//通过name获取function的定义
OperatorBase getFunciton(String name);

//通过自定义的Operator来实现类似：fun(a, b, c)
void addFunction(String name, OperatorBase op);

//fun(a, b, c) 绑定 object.function(a, b, c)对象方法
void addFunctionOfServiceMethod(String name, Object aServiceObject, String aFunctionName, Class<?>[] aParameterClassTypes, String errorInfo);

//fun(a, b, c) 绑定 Class.function(a, b, c)类方法
void addFunctionOfClassMethod(String name, String aClassName, String aFunctionName, Class<?>[] aParameterClassTypes, String errorInfo);

//给Class增加或者替换method，同时支持 a.fun(b), fun(a, b) 两种方法调用
//比如扩展String.class的isBlank方法:"abc".isBlank()和isBlank("abc")都可以调用
void addFunctionAndClassMethod(String name, Class<?> bindingClass, OperatorBase op);
```
Operator相关API
```java
//添加操作符号,可以设置优先级
void addOperator(String name, Operator op);
void addOperator(String name, String aRefOpername, Operator op);

//替换操作符处理
OperatorBase replaceOperator(String name, OperatorBase op);

//添加操作符和关键字的别名，比如 if..then..else -> 如果。。那么。。否则。。
void addOperatorWithAlias(String keyWordName, String realKeyWordName, String errorInfo);
```
宏定义相关API
```java
//比如addMacro("天猫卖家", "userDO.userTag &1024 == 1024")
void addMacro(String macroName, String express);
```
java class的相关api
```java
//添加类的属性字段
void addClassField(String field, Class<?>bindingClass, Class<?>returnType, Operator op);

//添加类的方法
void addClassMethod(String name, Class<?>bindingClass, OperatorBase op);
```
语法树解析变量、函数的API
```java
//获取一个表达式需要的外部变量名称列表
String[] getOutVarNames(String express);
String[] getOutFunctionNames(String express);
```
语法解析校验api, 脚本语法是否正确，可以通过ExpressRunner编译指令集的接口来完成。
```java
String expressString = "for(i = 0; i < 10; i++) {sum = i + 1;} return sum;";
InstructionSet instructionSet = expressRunner.parseInstructionSet(expressString);
//如果调用过程不出现异常，指令集instructionSet就是可以被加载运行（execute）了！
```
令集缓存相关的api, 因为QLExpress对文本到指令集做了一个本地HashMap缓存，通常情况下一个设计合理的应用脚本数量应该是有限的，缓存是安全稳定的，但是也提供了一些接口进行管理。
```java
//优先从本地指令集缓存获取指令集，没有的话生成并且缓存在本地
InstructionSet getInstructionSetFromLocalCache(String expressString);
//清除缓存
void clearExpressCache();
```
### 安全风险控制
- 防止死循环
  ```java
    try {
        express = "sum = 0; for(i = 0; i < 1000000000; i++) {sum = sum + i;} return sum;";
        //可通过timeoutMillis参数设置脚本的运行超时时间:1000ms
        Object r = runner.execute(express, context, null, true, false, 1000);
        System.out.println(r);
        throw new Exception("没有捕获到超时异常");
    } catch (QLTimeOutException e) {
        System.out.println(e);
    }
  ```
- 防止调用不安全的系统api
  ```java
    ExpressRunner runner = new ExpressRunner();
    QLExpressRunStrategy.setForbiddenInvokeSecurityRiskMethods(true);

    DefaultContext<String, Object> context = new DefaultContext<String, Object>();
    try {
        express = "System.exit(1);";
        Object r = runner.execute(express, context, null, true, false);
        System.out.println(r);
        throw new Exception("没有捕获到不安全的方法");
    } catch (QLException e) {
        System.out.println(e);
    }
  ```
### 增强上下文参数Context相关的api
- 与spring框架的无缝集成，上下文参数`IExpressContext context`非常有用，它允许put任何变量，然后在脚本中识别出来。在实际中我们很希望能够无缝的集成到spring框架中，可以仿照下面的例子使用一个子类。
  ```java
    public class QLExpressContext extends HashMap<String, Object> implements IExpressContext<String, Object> {
        private final ApplicationContext context;

        // 构造函数，传入context 和 ApplicationContext
        public QLExpressContext(Map<String, Object> map, ApplicationContext aContext) {
            super(map);
            this.context = aContext;
        }

        /**
        * 抽象方法：根据名称从属性列表中提取属性值
        */
        public Object get(Object name) {
            Object result;
            result = super.get(name);
            try {
                if (result == null && this.context != null && this.context.containsBean((String)name)) {
                    // 如果在Spring容器中包含bean，则返回String的Bean
                    result = this.context.getBean((String)name);
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
            return result;
        }

        public Object put(String name, Object object) {
            return super.put(name, object);
        }
    }
  ```
- 自定义函数操作符获取原始的context控制上下文，自定义的Operator需要直接继承OperatorBase，获取到parent即可，可以用于在运行一组脚本的时候，直接编辑上下文信息，业务逻辑处理上也非常有用。
  ```java
    public class ContextMessagePutTest {
        class OperatorContextPut extends OperatorBase {
            public OperatorContextPut(String aName) {
                this.name = aName;
            }

            @Override
            public OperateData executeInner(InstructionSetContext parent, ArraySwap list) throws Exception {
                String key = list.get(0).toString();
                Object value = list.get(1);
                parent.put(key, value);
                return null;
            }
        }

        @Test
        public void test() throws Exception {
            ExpressRunner runner = new ExpressRunner();
            OperatorBase op = new OperatorContextPut("contextPut");
            runner.addFunction("contextPut", op);
            String express = "contextPut('success', 'false'); contextPut('error', '错误信息'); contextPut('warning', '提醒信息')";
            IExpressContext<String, Object> context = new DefaultContext<String, Object>();
            context.put("success", "true");
            Object result = runner.execute(express, context, null, false, true);
            System.out.println(result);
            System.out.println(context);
        }
    }
  ```
## 多级别安全控制
QLExpress与本地JVM交互的方式有:
- 应用中的自定义函数/操作符/宏: 该部分不在QLExpress运行时的管控范围，属于应用开放给脚本的业务功能，不受安全控制，应用需要自行确保这部分是安全的
- 在QLExpress运行时中发生的交互: 安全控制可以对这一部分进行管理, QLExpress会开放相关的配置给应用
  - 通过 .操作符获取Java对象的属性或者调用Java对象中的方法
  - 通过 import 可以导入JVM中存在的任何类并且使用, 默认情况下会导入`java.lang`, `java.util`以及`java.util.stream`

在不同的场景下，应用可以配置不同的安全级别，安全级别由低到高：
- 黑名单控制：QLExpress默认会阻断一些高危的系统 API, 用户也可以自行添加, 但是开放对 JVM 中其他所有类与方法的访问, 最灵活, 但是很容易被反射工具类绕过，只适用于脚本安全性有其他严格控制的场景，禁止直接运行终端用户输入

白名单控制：QLExpress 支持编译时白名单和运行时白名单机制, 编译时白名单设置到类级别, 能够在语法检查阶段就暴露出不安全类的使用, 但是无法阻断运行时动态生成的类(比如通过反射), 运行时白名单能够确保运行时只可以直接调用有限的 Java 方法, 必须设置了运行时白名单, 才算是达到了这个级别

沙箱模式：QLExpress 作为一个语言沙箱, 只允许通过自定义函数/操作符/宏与应用交互, 不允许与 JVM 中的类产生交互


# RuleEngine
非常简单的规则引擎，容易使用，可以用多种方式来表示规则，xml、drools、database等。添加依赖
```xml
    <dependency>
        <groupId>com.github.hale-lee</groupId>
        <artifactId>RuleEngine</artifactId>
        <version>0.2.0</version>
    </dependency>
```

