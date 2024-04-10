一个语义明显且易于阅读的最小化配置文件格式。一个小规模的易于使用的语义化的配置文件格式，可以无二歧义的转换为一个哈希表。TOML可以很容易的解析为各种语言中的数据结构。TOML(Tom's Obvious, Minimal Language)。
# TOML的特点
- TOML以人为先
  - 语义明显，易于阅读
  - 能无歧义的映射为哈希表
  - 易于解析为各种语言中的数据结构
- TOML具备实用的原生类型
  - 键值对
  - 数组
  - 表
  - 内联表
  - 表数组
  - 整数/浮点数
  - 布尔值
  - 日期&时刻，带可选的时区偏移
- TOML受到广泛支持
  - TOML已经拥有大多数当今使用的最流行的编程语言的实现
# 快速上手
- 注释，使用#表示注释
- 字符串，分为基本字符串、多行基本字符串
  ```toml
  str1 = "I'm a string."
  str2 = "You can \"quote\" me."
  str3 = "Name\tJos\u00E9\nLoc\tSF."
  ```
  ```toml
  str1 = """
  Roses are red
  Violets are blue"""

  str2 = """\
  The quick brown \
  fox jumps over \
  the lazy dog.\
  """
  ```
  字面量字符串使用单引号，没有转义行为所见即所得。
  ```toml
  path = 'C:\Users\nodejs\templates'
  path2 = '\\User\admin$\system32'
  quoted = 'Tom "Dubs" Preston-Werner'
  regex = '<\i\c*\s*>'
  ```
  ```toml
  re = '''I [dw]on't need \d{2} apples'''
  lines = '''
  原始字符串中的
  第一个换行被剔除了。
  所有其它空白
  都保留了。
  '''
  ```
- 数字支持多种形式
  ```toml
  # 整数
  int1 = +99
  int2 = 42
  int3 = 0
  int4 = -17

  # 十六进制带有前缀 `0x`
  hex1 = 0xDEADBEEF
  hex2 = 0xdeadbeef
  hex3 = 0xdead_beef

  # 八进制带有前缀 `0o`
  oct1 = 0o01234567
  oct2 = 0o755

  # 二进制带有前缀 `0b`
  bin1 = 0b11010110

  # 小数
  float1 = +1.0
  float2 = 3.1415
  float3 = -0.01

  # 指数
  float4 = 5e+22
  float5 = 1e06
  float6 = -2E-2

  # both
  float7 = 6.626e-34

  # 分隔符
  float8 = 224_617.445_991_228

  # 无穷
  infinite1 = inf # 正无穷
  infinite2 = +inf # 正无穷
  infinite3 = -inf # 负无穷

  # 非数
  not1 = nan
  not2 = +nan
  not3 = -nan 
  ```
- 日期与时刻
  ```toml
  # 坐标日期时刻
  odt1 = 1979-05-27T07:32:00Z
  odt2 = 1979-05-27T00:32:00-07:00
  odt3 = 1979-05-27T00:32:00.999999-07:00

  # 各地日期时刻
  ldt1 = 1979-05-27T07:32:00
  ldt2 = 1979-05-27T00:32:00.999999

  # 各地日期
  ld1 = 1979-05-27

  # 各地时刻
  lt1 = 07:32:00
  lt2 = 00:32:00.999999
  ```
- ini做配置文件:
  ```ini
    ; 最简单的结构

    val_1 = val_1;
    val_2 = val_2; 这些等号后面的值是字符串（句末分号不是必须的；它后面的都是注释）

    ; 稍微复杂一点的单层嵌套结构

    [obj_1]

    x = obj_1.x
    y = obj_2.y

    [obj_2]

    x = obj_2.x
    y = obj_2.y
  ```
- JSON配置文件，阅读与编辑不太方便
  ```json
    {
        "val_1": "val_1"
        ,
        "val_2": "val_2"
        ,
        "obj_1": {
            "x": "obj_1.x"
            ,
            "y": "obj_1.y"
        }
        ,
        "obj_2": {
            "x": "obj_2.x"
            ,
            "y": "obj_2.y"
        }
        ,
        "arr": [
            { "x":"arr[0].x", "y":"arr[0].y" }
            ,
            { "x":"arr[1].x", "y":"arr[1].y" }
        ]
    }
  ```
- YAML，将JSON中的括号去掉保留缩进，时刻要注意缩进，语法过多。
  ```yaml
    val_1: abcd # string
    val_2: true # boolean
    val_3: TRUE # ?
    val_4: True # ?
    val_5: TrUE # ?
    val_6: yes  # ?
    val_7: on   # ?
    val_8: y    # ?

    obj_1:
    x: obj_1.x
    y: obj_1.y
    obj_2:
    x: obj_2.x
    y: obj_2.y

    arr:
    - x: arr[0].x
        y: arr[0].y
    - x: arr[1].x
        y: arr[1].y

    str_1: "a
    b"          # ?
    str_2: "a
            b"  # ?
    str_3: "a
            b" # ?
  ```
TOML抛弃了括号与缩进，采取显式键名链的方式声明。
```toml
val_1 = "val_1"
val_2 = "val_2"

obj_1.x = "obj_1.x"
obj_1.y = "obj_1.y"

[obj_2]

x = "obj_2.x"
y = "obj_2.y"

[[arr]]

x = "arr[0].x"
y = "arr[0].y"

[[arr]]

x = "arr[1].x"
y = "arr[1].y"

[str.x]

y.z = "str.x.y.z"

[str.a]

b.c = """
    str
   .a
  .b
 .c
""" # 等价于 "    str\n   .a\n  .b\n .c\n"

[inline]

points = [
    { x=1, y=1, z=0 },
    { x=2, y=4, z=0 },
    { x=3, y=9, z=0 },
]
```