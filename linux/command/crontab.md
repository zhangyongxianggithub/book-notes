Linux crontab是用来定期执行程序的命令。安装完操作系统后，默认便会启动此任务调度命令。**crond**命令每分钟会定期检查是否有要执行的工作，如果有便会自动执行该工作。任务主要分2种:
- 系统执行的工作: 系统周期性所要执行的工作;
- 个人执行的工作: 某个用户定期要做的工作，由用户自己设置.
语法:
>crontab [ -u user ] file
>crontab [ -u user ] { -l | -r | -e }

- crontab是用作固定时间或者固定间隔执行程序用的;
- -u user指定user的时程表;
- -e 使用VI设定时程表;
- -r 删除目前的时程表;
- -l 列出时程表
时间格式如下:
>minute hour day month weekday program
- * 表示每，比如每分钟，每小时，每天等;
- a-b这样的形式表示区间，比如1到10分钟等;
- */n表示每个固定的时间间隔执行;
- a,b,c表示在a，b，c这个时间点要执行;
>*    *    *    *    *
-    -    -    -    -
|    |    |    |    |
|    |    |    |    +----- 星期中星期几 (0 - 6) (星期天 为0)
|    |    |    +---------- 月份 (1 - 12) 
|    |    +--------------- 一个月中的第几天 (1 - 31)
|    +-------------------- 小时 (0 - 23)
+------------------------- 分钟 (0 - 59)

也可以将设定放在文件中，`crontab file`的方式来设定
一些例子:
```bash
* * * * * /bin/ls #每分钟执行一次
```
```bash
0 6-12/3 * 12 * /usr/bin/backup # 在 12 月内, 每天的早上 6 点到 12 点，每隔 3 个小时 0 分钟执行一次 /usr/bin/backup：
```
```bash
0 17 * * 1-5 mail -s "hi" alex@domain.name < /tmp/maildata # 周一到周五每天下午 5:00 寄一封信给 alex@domain.name
```
```bash
20 0-23/2 * * * echo "haha" # 每月每天的午夜 0 点 20 分, 2 点 20 分, 4 点 20 分....执行 echo "haha"
```
```bash
0 */2 * * * /sbin/service httpd restart  意思是每两个小时重启一次apache 

50 7 * * * /sbin/service sshd start  意思是每天7：50开启ssh服务 

50 22 * * * /sbin/service sshd stop  意思是每天22：50关闭ssh服务 

0 0 1,15 * * fsck /home  每月1号和15号检查/home 磁盘 

1 * * * * /home/bruce/backup  每小时的第一分执行 /home/bruce/backup这个文件 

00 03 * * 1-5 find /home "*.xxx" -mtime +4 -exec rm {} \;  每周一至周五3点钟，在目录/home中，查找文件名为*.xxx的文件，并删除4天前的文件。

30 6 */10 * * ls  意思是每月的1、11、21、31日是的6：30执行一次ls命令
```
当程序在你所指定的时间执行后，系统会发一封邮件给当前的用户，显示该程序执行的内容，若是你不希望收到这样的邮件，请在每一行空一格之后加上 > /dev/null 2>&1 即可，如：
```bash
20 03 * * * . /etc/profile;/bin/sh /var/www/runoob/test.sh > /dev/null 2>&1 
```
如果我们使用 crontab 来定时执行脚本，无法执行，但是如果直接通过命令（如：./test.sh)又可以正常执行，这主要是因为无法读取环境变量的原因:
- 所有命令需要写成绝对路径形式，如: /usr/local/bin/docker;
- 在 shell 脚本开头使用以下代码:
  ```bash
  #!/bin/sh

    . /etc/profile
    . ~/.bash_profile
  ```
- 在 /etc/crontab 中添加环境变量，在可执行命令之前添加命令 . /etc/profile;/bin/sh，使得环境变量生效
  ```bash
  20 03 * * * . /etc/profile;/bin/sh /var/www/runoob/test.sh
  ```