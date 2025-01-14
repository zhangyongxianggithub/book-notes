一个传统的企业级应用不可能只有一个对象或者按照Spring方法只有一个Bean，即便最简单的应用也会有大量的对象还有之间的交互协作来提供用户需要的功能。下一节将介绍如何从定义多个独立的bean定义转变为一个完整实现的应用程序，这个应用中的对象互相协作实现功能目标。
# 依赖注入
依赖注入也叫做DI，就是定义了依赖的对象。有3种定义依赖的方式：构造函数参数、工厂方法参数与十六对象的成员属性。当创建Bean的时候容器注入需要的依赖。这个过程是Bean本身负责实例化依赖(直接通过依赖的构造函数或者Service Locator模式)的反转，也就是控制反转。使用DI思想编写的代码更整洁。解藕性更好。对象不需要自己寻找依赖，不需要知晓依赖的位置或者Class实现。因此，类更容易测试尤其是依赖是接口或者抽象类的情况。允许在单元测试中使用stub或者mock实现。
## Constructor-based Dependency Injection
容器调用class的对应参数的构造方法，每一个参数都代表一个依赖，这等同与调用相同参数的静态工厂方法，他们2个都会产生对象。下面的例子是一个使用构造函数注入的例子：
```java
public class SimpleMovieLister {

	// the SimpleMovieLister has a dependency on a MovieFinder
	private final MovieFinder movieFinder;

	// a constructor so that the Spring container can inject a MovieFinder
	public SimpleMovieLister(MovieFinder movieFinder) {
		this.movieFinder = movieFinder;
	}
	// business logic that actually uses the injected MovieFinder is omitted...
}
```
这个类没什么特别的，就是个POJO。

	基于构造器的依赖注入会首先解析参数的类型与顺序，如果使用的是XML的配置方式，如果类型通过配置不能明显表达，则需要指定，比如：

	或者：

	还可以：

	使用参数名字来配置构造器的方法，必须启用编译器的debug标志，因为字节码文件会丢失方法的参数名字信息，使用debug模式则不会，或者使用@ConstructorProperties注解指定参数名。
2.基于setter方法的依赖注入：这种方法是通过容器调用bean的setter方法来完成的。ApplicationContext支持基于构造器的依赖注入与基于setter方法的依赖注入，也支持BeanDefinition的方式，这种方式需要与PropertyEditor实例一起使用；但是这种方式是一种编程式的，通常较少使用。
	强制依赖使用构造器依赖方法注入，setter方法注入用于可选依赖的注入（@Required）；Spring团队更推荐构造器依赖注入。

	容器进行依赖解析的步骤如下：
ApplicationContext被初始化；
bean创建后，提供依赖；	
根据进行进行类型转换；
	单例Bean会跟随容器的初始化一起初始化，其他scope的bean都是请求的时候才初始化为实例，一个Bean的初始化会造成很多Bean的实例化操作；循环依赖：如果使用基于构造器的依赖注入方式，可能会造成循环依赖；开发者基本可以信任Spring会做出正确的事情，Spring会检测配置问题，并且总是尽可能在Bean创建足够晚的时间后才回去设置属性并解析依赖关系；这意味着，可能容器已经正确启动并初始化了所有的涉及的到的bean，但是可能有某个Bean的依赖出现问题，而产生后续的异常；
1.1.4.2 依赖配置的细节
1.<value>直接注入字符串，Spring的conversion服务会把字符串转换为property或者构造器参数的实际类型；

还可以使用命名空间的方式配置依赖：

如果配置的依赖是java.util.Properties类型的，可以直接使用以下方式配置：

引用bean可以使用<idRef>标签，并且这个标签比传统的设值注入的方式多了错误检测功能。
2.引用其他Bean
ref元素表达的意思是bean的属性有依赖容器中的其他的Bean，需要注意的是parent属性表达的是依赖的bean再上级容器中;
3.内部Bean，在属性内创建匿名的Bean，不需要指定id或者name;
4.集合，List、Set、Map、Properties；merge=true，合并父子Bean中的属性；
5.null值与空值；
6.p命名空间；
7.c命名空间；
8.混合属性。
1.1.4.3 使用depends-on
强制依赖的bean被初始化，即使没有依赖它的Bean要被初始化。就是定义Bean初始化的时机。
1.1.4.4 懒初始化Bean
所有的单例Bean都是在启动时初始化的，可以立即发现配置与环境中的错误，但是如果不想要Bean被立即初始化，可以设置lazy-init=true，告诉IoC容器，不要立即初始化，使用时再初始化就可以。
1.1.4.5 注入依赖
Spring容器可以自动装配相关联的Bean，自动装配功能具有以下的优势：
自动装配减少代码量，不需要指定properties或者构造器参数的信息等；
自动装配可以根据对象的变化而更新配置。
当使用的是基于XML的配置元数据时，你可以通过<bean>的autowire属性来指定Bean的自动装配模式，有4种装配模式：
no：缺省模式，不会自动装配，必须通过ref指定装配的bean，不建议在已经存在的比较大的系统中更改缺省的装配模式，因为明确的指定依赖关系可以让开发者对系统有更好的控制，因为从某种程度来说，它描述了系统的结构；
byName：通过属性名装配，指定根据Bean内的属性名来装配，Spring容器寻找与属性相同名字的bean来装配；
byType：根据属性的类型来装配，如果此类型的bean存在多个，则抛出一个异常，如果没有匹配的Bean发现，则注入null；
constructor：与byType类似，但是匹配的是构造器参数的类型，如果没有相关类型的Bean存在，则抛出异常。
使用byType或者constructor的自动装配模式，可以装配数组与集合类型的数据。
自动装配的限制：
明确的指定property与constructor-arg的值会覆盖自动装配机制，自动装配也不能装配基本类型值，String、Class或者是这些类型的数组；假如容器内有多个满足类型的bean定义，而且不是集合类型的装配的话，不知道装配哪个bean；
为了避免自动装配可能存在的问题：
开发者可以明确指定依赖来覆盖自动装配机制、设置autowire-candidate=false来禁止自动装配、设置一个Bean为primary属性；
设置<bean/>的autowire-candidate=false后，此Bean不参与容器的自动装配系统，但是只对根据类型的自动装配有影响。
1.1.4.6 方法注入
在大多数的应用场景下，容器内的bean都是单例的；当一个单例的bean需要依赖其他的单例Bean或者非单例bean需要依赖其他的非单例Bean时，开发者只需要在定义Bean时，把相关的依赖定义成propery等；这时候，如果Bean的生命周期是不同的就会发生一定的问题，假设单例Bean A依赖多例Bean B，可能A的每个方法的调用都需要调用B的相关的逻辑；容器只会初始化一次A，并且只会在初始化时设置一次A的依赖，此时B在ABean中变成了单例，并没有在每个方法调用时都生成新的B。
上述问题的一种解决方案就是放弃控制反转的自动装配依赖，可以让Bean实现ApplicatonContextAware接口来让Bean持有容器，并通过调用容器的getBean(“B”)方法来每次获取新的B实例；上述的解决方案并不令人满意，因为它把业务代码与Spring框架的代码耦合在了一起；Method Injection，是Spring容器的高级特性，可以完美解决这种情况。

Lookup方法注入技术是一种容器覆写容器中Bean中方法的技术，这种lookup方法会返回容器内的其他的Bean；这种技术一般就是用于返回多例Bean；Spring框架是通过字节码生成器CGLIB来动态生成一个子类，通过子类覆写lookup方法，由于要动态生成子类，所以定义类不能是final的，同时需要覆写的方法不能是final的；单元测试情况，你需要自己实现类的子类，，并提供抽象方法的实现方法；Lookup方法的限制就是lookup方法Bean不能使用工厂方法的方式创建，尤其是不能通过@Bean的注解方式创建的Bean，因为在这种情况下，并不是容器负责生成的实例，因此，不能创建一个运行时子类。
上面代码可以改造为：

配置的XML：

	Lookup方法可以是abstract的也可以不是abstract的。
在基于注解配置的组件模型中，开发者可以在lookup方法上加上注解@Lookup。通常来说，配置基于注解的lookup方法时需要类是实际的实现类，方法是普通的实现方法，这是为了与Spring的组件扫描规则相兼容，因为缺省情况下，Spring容器会忽略抽象类，但是，如果明确注册了抽象类为bean或者明确的通过imported的bean配置，则不会忽略抽象类。
还有获取不同生命周期Bean的方式是ObjectFactory/Provider。
任意方法替换
一种使用较少的方法注入方案是方法替换，当使用XML配置时，可以使用replaced=method元素来替换方法；