# Configuration(knobs,baby)
HikariCP具有合理的默认设置，无需额外调整即可在大多数部署中表现良好。除了下面标记的"必需品"之外，每个属性都是可选的。HikariCP对所有时间值都使用毫秒单位。
HikariCP依靠精确的计时器来实现高性能和可靠性。您的服务器必须与时间源（例如NTP服务器）同步。特别是当您的服务器在虚拟机中运行时。为什么？[在这里阅读更多内容](https://dba.stackexchange.com/a/171020)。不要依赖hypervisor设置来同步虚拟机的时钟。在虚拟机内部配置时间源同步。如果您对因缺乏时间同步而导致的问题寻求支持，您将在Twitter上遭到公开嘲笑。
- dataSourceClassName(Essentials): JDBC驱动提供的`DataSource`实现类的名字，参考你的JDBC驱动文档来获取这个类名。或者参考下面的[表格](https://github.com/brettwooldridge/HikariCP#popular-datasource-class-names)，记住不支持XA数据源，XA数据源需要一个real的事务管理器比如bitronix，如果你正在使用`jdbcUrl`或者更老式的基于`DriverManager`的JDBC驱动设置，你不需要设置这个属性。Default: none
- jdbcUrl(Essentials):指示HikariCP使用`DriverManager-based`配置，由于多种原因，我们认为DataSource-based的配置更好。但是2种方式对于很多部署来说几乎没有显著差异。当将此属性与旧驱动程序一起使用时，您可能还需要设置`driverClassName`属性，但首先尝试不设置。请注意，如果使用此属性，您仍然可以使用DataSource属性来配置驱动程序，实际上建议使用该属性，而不是在URL本身中指定的驱动程序参数。Default: none
- username(Essentials): 此属性设置从底层驱动程序获取连接时使用的默认身份验证用户名。请注意，对于`DataSource`，这通过在底层`DataSource`上调用`DataSource.getConnection(*username*,password)`以非常确定的方式工作。但是，对于`Driver-based`的配置，每个驱动都是不同的。在`Driver-based`情况下，HikariCP将使用此用户名属性在传递给驱动程序的 `DriverManager.getConnection(jdbcUrl, props)`调用的属性中设置用户属性。如果这不是您所需要的，请完全跳过此方法并调用`addDataSourceProperty("username", ...)`。Default: none
- password(Essentials): 此属性设置从底层驱动程序获取连接时使用的默认身份验证密码。请注意，对于`DataSource`，这通过在底层`DataSource`上调用`DataSource.getConnection(username, *password*)`以非常确定的方式工作。但是，对于`Driver-based`配置，每个驱动都是不同的。在`Driver-based`的情况下，HikariCP将使用此密码属性在传递给驱动程序的 `DriverManager.getConnection(jdbcUrl, props)`调用的属性中设置密码属性。如果这不是您所需要的，请完全跳过此方法并调用`addDataSourceProperty("pass", ...)`。Default: none
- autoCommit(Frequently used): 这个属性控制从池中返回的连接的自动提交的行为，boolean值，Default: true
- connectionTimeout(Frequently used): 这个属性控制客户端等待池中的连接的最大毫秒数，如果超过了并且没有返回可用的连接则会抛出一个`SQLException`的异常，最小的设置是250ms，Default: 30000
- idleTimeout(Frequently used): 这个属性控制一个connection在池中的最大空闲时间，这个设置只有在`minimumIdle`被定义为小于`maximumPoolSize`的场景下才有效，一旦池中的连接数达到了`minimumIdle`后，空闲连接则不会被回收，连接是否因空闲而退出，最大变化为+30秒，平均变化为+15秒，在超时前，连接不会因为空闲而回收。0意味着空闲连接永远不会从池中回收。最小值是10000ms，Default: 600000(10 minutes)
- keepaliveTime(Frequently used): 这个属性控制HikariCP保持连接alive的频率，这是为了防止连接因为数据库或者网络基础设置造成的超时；这个值必须小于`maxLifetime`，keepalive只会作用在空闲的连接上，当时间达到了keepalive定义的时间，连接会从池中移除。通过ping操作返回到池中，ping操作是下面的操作之一:
  - 调用JDBC4的`isValid()`方法
  - 执行`connectionTestQuery`
  
  通常，池外的持续时间都是几号秒或者亚毫秒级别，因此应该没有明显的性能影响。允许的最小值为30000ms(30s)，但分钟范围内的值是最理想的。Default: 0(Disabled)
- maxLifetime(Frequently used): 控制池中的连接的最大lifetime，一个使用中的连接不会被回收，只有当closed的时候，它才会被移除。在逐个连接的基础上，应用较小的negative attenuation以避免池中的大规模灭绝。 我们强烈建议设置此值，它应该比任何数据库或基础设施施加的连接时间限制短几秒。 值0表示没有最大生命周期（无限生命周期），当然取决于`idleTimeout`设置。允许的最小值为30000ms（30s）。Default：1800000(30 minutes)
- connectionTestQuery(Frequently used): 如果你的驱动支持JDBC4，我们强烈建议不要设置这个属性，这是为不支持JDBC4的`Connection.isValid()`API的老式驱动准备的属性，他是一个查询，在连接从池中取出前执行，用来验证连接是否是alive的。Default: none
- minimumIdle(Frequently used): 这个属性控制连接池的最小空闲连接数量，如果空闲连接数量低于这个值并且池中总的连接数小于`maximumPoolSize`，HikariCP将会快速高效的添加连接到池中，然而，为了更好的响应大量的连接需求，我们建议不要设置这个值而是让HikariCP自己充当一个固定大小的连接池，Default: same as maximumPoolSize
- maximumPoolSize: 这个属性控制池的最大大小，包括空闲的与使用中的连接。基本上，这个值决定了实际连接到数据库的连接的最大数量，这个值最好由你的执行环境决定，当pool达到这个大小时并且此时没有空闲连接可用，调用`getConnection()`将会阻塞`connectionTimeout`毫秒数，然后抛出超时异常，Default: 10
- metricRegistry: 这个属性只有在编程配置或者IoC容器中有用，允许你在pool中指定一个`Codahale/Dropwizard MetricRegistry`类型的实例来记录各种各样的指标。Default: none
- healthCheckRegistry: 这个属性只有在编程配置或者IoC容器中有用，允许你在pool中指定一个`Codahale/Dropwizard HealthCheckRegistry`类型的实例来报告当前的健康信息。Default: none
- poolName: 这个属性表示连接池的用户自定义名字，主要出现在logging/JMX management consoles中来标识pools与pool配置，Default: auto-generated
- initializationFailTimeout: 此属性控制如果无法获取一个initial连接是否快速失败，任何的正数都是尝试获取initial连接的毫秒时间，应用线程在此期间将会阻塞等待，如果在给定的时间内不能获取到一个连接，将会抛出一个异常。这个超时在connectionTimeout周期之后应用。如果设置为0，HikariCP将会尝试获取并验证连接，如果获取了连接但是验证失败，将会抛出一个异常并且pool不会启动，然而如果获取不了连接，池会启动但是后续获取连接会失败。小于0的值将会绕过任何initial连接尝试，pool会立即启动并在后台尝试获取连接。因此，稍后获取连接的努力可能会失败。 默认值：1
- isolateInternalQueries: 此属性确定HikariCP是否在其自己的事务中隔离内部池查询，例如连接alive测试。 由于这些通常是只读查询，因此很少需要将它们封装在自己的事务中。仅当禁用autoCommit时此属性才适用。Default: false
- allowPoolSuspension: 该属性控制是否可以通过JMX暂停和恢复连接池。这对于某些故障转移自动化场景很有用。 当池挂起时，对`getConnection()`的调用不会超时，并将一直保持到池恢复为止。默认值：false
- readOnly: 该属性控制从池中获取的连接默认是否处于只读模式。请注意，某些数据库不支持只读模式的概念，而一些数据库则在连接设置为只读模式时提供查询优化。您是否需要此属性在很大程度上取决于您的应用程序和数据库。Default：false
- registerMbeans: 此属性控制是否注册JMX管理Bean（“MBean”）。Default: false
- catalog: 这个属性设置支持catalog概念的数据库的默认的catalog，如果没有指定这个属性，则使用JDBC驱动定义的默认的catalog，Default: driver default
- connectionInitSql: 这个属性设置一个SQL语句，在每次一个新的连接创建加入到池之前执行这个SQL语句，如果SQL无效或者抛出异常，则会认为是连接失败然后执行标准的重试逻辑，Default: none
- driverClassName: HikariCP将尝试仅根据`jdbcUrl`通过`DriverManager`解析驱动程序，但对于某些较旧的驱动程序，还必须指定`driverClassName`。除非您收到表明未找到驱动程序的明显错误消息，否则请忽略此属性。Default：none
- transactionIsolation: 此属性控制从池返回的连接的默认事务隔离级别。如果未指定此属性，则使用JDBC驱动程序定义的默认事务隔离级别。仅当您有所有查询通用的特定隔离要求时才使用此属性。此属性的值是`Connection`类中的常量名称，例如`TRANSACTION_READ_COMMITTED`、`TRANSACTION_REPEATABLE_READ`等。Default：driver default
- validationTimeout: 此属性控制测试连接活动性的最长时间。该值必须小于connectionTimeout。可接受的最低验证超时为250ms。Default: 5000
- leakDetectionThreshold: 这个属性指定连接可以处于池外的时间，超过这个时间后将会打印一个message表明可能发生了连接泄漏，0标识禁用泄漏检测。启用泄漏检测的最低可接受值为2000。Default: 0
- dataSource: 此属性只能通过编程配置或IoC容器使用。此属性允许您直接设置要由池包装的`DataSource`实例，而不是让HikariCP通过反射来构造它。这在某些依赖注入框架中非常有用。指定此属性后，`dataSourceClassName`属性和所有特定于DataSource的属性将被忽略。Default: none
- schema: 这个属性设置支持schema概念的数据库的默认的schema，如果没有指定这个属性，则使用JDBC driver定义的默认的schema，Default: driver default
- threadFactory: 此属性只能通过编程配置或IoC容器使用。此属性允许您设置`java.util.concurrent.ThreadFactory`的实例，该实例将用于创建池使用的所有线程。在一些受限的执行环境中需要它，在这些环境中线程只能通过应用程序容器提供的ThreadFactory创建。Default: none
- scheduledExecutor: 此属性只能通过编程配置或IoC容器使用。此属性允许您设置一个将用于各种内部调度任务的 `java.util.concurrent.ScheduledExecutorService`的实例。如果为HikariCP提供 `ScheduledThreadPoolExecutor`实例，建议使用`setRemoveOnCancelPolicy(true)`。Default: none