# 注解
注解又叫做元数据，以正式的方式为代码添加信息，将来可以使用这些信息。注解是为了解决将元数据绑定到源代码的需求，以前都是放在XML等分离的元数据配置文件中的。是对Java表达式的补充，是完整表述程序必须的信息。内置的5个注解:
- `@Override`:覆盖基类中的方法
- `@Deprecated`: 使用未来会被移除的API
- `@SuppressWarning`: 关闭不当的编译警告
- `@SafeVarargs`: 告诉编译器，在可变长参数中的泛型是类型安全的。 可变长参数是使用数组存储的，而数组和泛型不能很好的混合使用。 简单的说，数组元素的数据类型在编译和运行时都是确定的，而泛型的数据类型只有在运行时才能确定下来
- `@FunctionInterface`: 标记注解表明是函数式接口

还有5个元注解。注解的定义类似接口，多了一个`@`符号。必须有元注解`@Retention`与`@Target`(可以无则全部元素都适用)。`@Target`定义你可以在何处应用注解，`@Retention`定义注解的保留范围，有3个范围: 源代码文件、编译后的Class文件与运行时。没有任何元素的注解就是标记注解。5个元注解:
- `@Target`: 注解可以应用的地方，类型是`ElementType`
  - `CONSTRUCTOR`: 构造器声明
  - `FIELD`: 字段声明，包括枚举常量
  - `LOCAL_VARIAVBLE`: 本地变量声明
  - `METHOD`: 方法声明
  - `PACKAGE`: 包声明
  - `PARAMETER`: 参数声明
  - `TYPE`: 类或者接口或者枚举的声明
- `@Retention`: 注解信息可以保存多久，类型是`RetentionPolicy`
  - `SOURCE`: 注解会被编译器丢弃，只在源代码中
  - `CLASS`: 主机在类文件中可以被编译器使用，但会被虚拟机丢弃
  - `RUNTIME`: 虚拟机保留，反射可以获取到注解信息
- `@Documented`: 在Javadoc中引入该注解
- `@Inherited`: 允许子类继承父类注解
- `@Repeatable`: 可以多次应用与同一个声明

通过反射编写注解处理器或者通过javac的编译器钩子在编译时使用注解。通常是使用`getDeclaredMethods()`，`Class`、`Method`、`Field`等都实现了`AnnotatedElement`接口。注解允许的元素类型:
- 所有的基本类型
- String
- Class
- Enum
- Annotation
- 以上任何类型的数组

所有元素都要有默认值，不能是null，注解不支持继承。通常可以通过注解生成外部描述文件，比如生成SQL建表语句、生成XML文件等都是很多框架常用的。以前要程序员自己定义，现在只需要维护一个代码源就可以了。如果不放`@Target`，则默认可以放到所有类型上。
```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface DBTable {
    String name() default "";
}
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Constraints {
    boolean primary() default false;
    
    boolean allowNull() default true;
    
    boolean unique() default false;
}
public class TableCreator {
    @SneakyThrows
    public static void main(final String[] args) {
        if (args.length < 1) {
            System.out.println("arguments: at least one annotated class");
            System.exit(0);
        }
        for (final String arg : args) {
            final Class<?> cl = Class.forName(arg);
            final DBTable dbTable = cl.getAnnotation(DBTable.class);
            if (dbTable == null) {
                System.out.println(
                        "can't find annotation DBTable in class: " + arg);
                continue;
            }
            String tableName = dbTable.name();
            if (tableName.length() < 1) {
                tableName = cl.getName().toUpperCase();
            }
            
            final List<String> coumnDefs = new ArrayList<>();
            for (final Field field : cl.getDeclaredFields()) {
                String columnName = null;
                final Annotation[] anns = field.getDeclaredAnnotations();
                if (anns.length < 1) {
                    continue;
                }
                if (anns[0] instanceof SQLInteger) {
                    final SQLInteger sqlInteger = (SQLInteger) anns[0];
                    if (sqlInteger.name().length() < 1) {
                        columnName = field.getName().toUpperCase();
                    } else {
                        columnName = sqlInteger.name();
                    }
                    coumnDefs.add(columnName + " INT "
                            + getConstraints(sqlInteger.constraints()));
                }
                if (anns[0] instanceof SQLString) {
                    final SQLString sqlString = (SQLString) anns[0];
                    if (sqlString.name().length() < 1) {
                        columnName = field.getName().toUpperCase();
                    } else {
                        columnName = sqlString.name();
                    }
                    coumnDefs.add(columnName + " VARCHAR(" + sqlString.value()
                            + ") " + getConstraints(sqlString.constraints()));
                }
            }
            final StringBuilder createCommand = new StringBuilder(
                    "CREATE TABLE " + tableName + " (");
            for (final String column : coumnDefs) {
                createCommand.append("\n    " + column + ",");
            }
            createCommand.deleteCharAt(createCommand.length() - 1);
            createCommand.append(")");
            System.out.println(
                    "table creation SQL for " + arg + " is:\n" + createCommand);
        }
    }
    
    public static String getConstraints(final Constraints con) {
        String constraints = "";
        if (!con.allowNull()) {
            constraints += " NOT NULL";
        }
        if (con.primary()) {
            constraints += " PRIMARY KEY";
        }
        if (con.unique()) {
            constraints += " UNIQUE";
        }
        return constraints;
    }
}
```
通过javac可以创建编译时注解。注解处理器会不断的创建新的文件，直到不再有新的文件被创建则编译源代码。javac的注解处理器需要使用到`AbstractProcessor`抽象类，同时需要使用到`@SupportedSourceVersion`与`@SupportedAnnotationTypes`2个元注解。在编译代码时，需要通过`javac -processor`的方式指定注解处理器。编译期注解处理器无法使用反射功能，mirror可以代替反射的功能查看源代码中的方法、字段与类型。下面是一个提取类中公共方法到接口的例子
```java
@Retention(RetentionPolicy.SOURCE)
@Target(ElementType.TYPE)
public @interface ExtractInterface {
    String interfaceName() default "";
}
```
```java
@ExtractInterface(interfaceName = "IMultiplier")
public class Multiplier {
    public boolean flag = false;
    private int n = 0;
    
    public int multiply(final int a, final int b) {
        int total = 0;
        for (int i = 1; i <= b; i++) {
            total = add(total, a);
        }
        return total;
    }
    
    public int fortySeven() {
        return 47;
    }
    
    private int add(final int a, final int b) {
        return a + b;
    }
    
    public double timesTen(final double arg) {
        return arg * 10;
    }
    
    public static void main(final String[] args) {
        final Multiplier multiplier = new Multiplier();
        System.out.println("10*10=" + multiplier.multiply(10, 10));
    }
}
```
下面是注解处理器的代码
```java
@SupportedAnnotationTypes("com.zyx.java.onjava8.annotation.ExtractInterface")
@SupportedSourceVersion(SourceVersion.RELEASE_8)
public class IfaceExtractorProcessor extends AbstractProcessor {
    
    private List<Element> interfaceMethods = new ArrayList<>();
    private Elements elementUtils;
    private ProcessingEnvironment processingEnv;
    
    @Override
    public synchronized void init(final ProcessingEnvironment processingEnv) {
        this.processingEnv = processingEnv;
        elementUtils = processingEnv.getElementUtils();
    }
    
    @Override
    public boolean process(final Set<? extends TypeElement> annotations,
            final RoundEnvironment roundEnv) {
        for (final Element element : roundEnv
                .getElementsAnnotatedWith(ExtractInterface.class)) {
            final var interfaceMame = element
                    .getAnnotation(ExtractInterface.class).interfaceName();
            // getEnclosedElements或者当前元素包起来的所有的元素
            for (final Element enclosedElement : element
                    .getEnclosedElements()) {
                if (enclosedElement.getKind() == ElementKind.METHOD
                        && enclosedElement.getModifiers()
                                .contains(Modifier.PUBLIC)
                        && !enclosedElement.getModifiers()
                                .contains(Modifier.STATIC)) {
                    interfaceMethods.add(enclosedElement);
                }
            }
            if (interfaceMethods.size() > 0) {
                writeInterfaceFiles(interfaceMame);
            }
        }
        return false;
    }
    
    private void writeInterfaceFiles(final String interfaceName) {
        try {
            // elementUtils是一个工具的集合，用来获取包名
            final var packageName = elementUtils
                    .getPackageOf(interfaceMethods.get(0)).toString();
            // 一个创建新文件的PrintWriter，Filer对象会让javac可以编译到创建的新的源代码并持续编译
            final Writer writer = processingEnv.getFiler()
                    .createSourceFile(interfaceName).openWriter();
            
            writer.write("package " + packageName + ";\n\n");
            writer.write("public interface " + interfaceName + " {\n\n");
            for (final Element element : interfaceMethods) {
                final ExecutableElement method = (ExecutableElement) element;
                String signature = "    ";
                signature += method.getReturnType() + " ";
                signature += method.getSimpleName();
                signature += createArgList(method.getParameters());
                System.out.println(signature);
                writer.write(signature + ";\n\n");
            }
            writer.write("}\n");
            writer.close();
        } catch (final Exception e) {
            System.err.println("writeInterfaceFiles: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }
    
    private String createArgList(
            final List<? extends VariableElement> parameters) {
        final String args = parameters.stream()
                .map(p -> p.asType() + " " + p.getSimpleName())
                .collect(Collectors.joining(", "));
        return "(" + args + ")";
    }
}
```


