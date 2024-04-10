# Packaging OCI Images
插件可以使用CNB(Cloud Native Buildpacks)从一个jar/war文件创建一个OCI镜像，镜像可以通过命令行构建，使用build-image这个goal，这会确保在镜像创建前package的生命周期都得到执行。因为安全的原因，镜像构建与运行不能使用root用户，这是CNB规范规定的。最简单的方式是在一个项目上执行`mvn spring-boot:build-image`，这个不论package是否执行都会自动构建镜像，如下图所示:
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <executions>
                <execution>
                    <goals>
                        <goal>build-image-no-fork</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```
将目标绑定到包生命周期时使用build-image-no-fork。此目标类似于build-image但不会fork生命周期以确保package已运行。在本节的其余部分，build-image用于指代build-image或build-image-no-fork目标。
虽然buildpack从可执行归档文件运行，但没有必要首先执行repackage目标，因为可执行存档程序会在必要时自动创建。当build-image repackage应用时，它应用与repackage目标相同的设置，即可以使用排除选项排除依赖项，默认情况下会自动排除Devtools（您可以使用 excludeDevtools属性进行控制）
## Docker Daemon
