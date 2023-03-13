一个小规模的易于使用的语义化的配置文件格式，可以无二异性的转换为一个哈希表。TOML(Tom's Obvious, Minimal Language)。
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