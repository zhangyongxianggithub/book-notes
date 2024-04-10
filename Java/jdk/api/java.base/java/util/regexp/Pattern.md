# Line terminators
line terminator表示一个输入的字符串行终止的一个或者2个字符组，下面的字符被认为是line terminators
- \n
- \r\n
- \r
- \u0085
- \u2028
- \u2029

1. 如果是UNIX_LINES模式，识别的line terminator是\n字符
# Groups and Capturing
## Group number
捕获组的编号是通过从左到右的括号计算的，在表达式`((A)(B(C)))`中，有4个捕获组
- ((A)(B(C)))
- (A)
- (B(C))
- (C)

第0组表示整个表达式。
## Group name
捕获组可以指定名字成为命名捕获组。后面可以反向引用这个名字
# Unicode support
Pattern支持[Unicode Technical Standard #18: Unicode Regular Expressions](http://www.unicode.org/reports/tr18/)的Level1与RL2.1的Canonical Equivalents与RL2.2的Extended Grapheme Clusters. 
- Unicode转义序列（如Java源代码中的 \u2014）的处理方式详见《Java语言规范》第3.3节的描述。这样的转义序列也被正则表达式解析器直接实现，以便Unicode转义可以在从文件或键盘读取的表达式中使用。因此，字符串 "\u2014" 和 "\u2014" 虽然不相等，但编译成相同的模式，该模式匹配十六进制值为0x2014的字符
- Unicode字符名称由命名字符结构`\N{...}`支持，例如，`\N{WHITE SMILING FACE}`指定字符`\u263A`。此类支持的字符名称是由 `Character.codePointOf(name)`匹配的有效Unicode字符名称
- Unicode extended grapheme clusters是通过grapheme cluster matcher \X与boundary matcher \b{g}支持
- Unicode scripts、blocks、categories、binary properties写在\p与\P结构中，\p{prop}表示要匹配的文本具有属性prop，\P{prop}表示输入没有prop的文本。Unicode scripts、blocks、categories、binary properties可以使用在character class的内部或者外部
- Unicode scripts通过前缀Is指定，比如IsHiragana，或者使用script(sc)关键词来指定，比如`script=Hiragana`或者`sc=Hiragana`，Pattern支持的script名字是定义在[UnicodeScript.forName](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Character.UnicodeScript.html#forName(java.lang.String))
- Blocks通过前缀In指定的，比如InMongolian或者使用关键词block(blk)比如`block=Mongolian`或者`blk=Mongolian`，Pattern支持的block名字是通过[UnicodeBlock.forName](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Character.UnicodeBlock.html#forName(java.lang.String))定义的
- Categories是通过可选的前缀Is指定的，\p{L}与\p{IsL}表示Unicode letter的种类，Categories也可以通过关键词指定，比如`general_category=Lu`与`gc=Lu`，支持的Categories定义在Charcter类中的[The Unicode Standard](http://www.unicode.org/standard/standard.html)，类别名称是标准中定义的名称，既具有规范性又具有参考性。
- Binary properties通过前缀Is指定，比如IsAlphabetic，Pattern支持的Binary properties如下:
  - Alphabetic
  - Ideographic
  - Letter
  - Lowercase
  - Uppercase
  - Titlecase
  - Punctuation
  - Control
  - White_Space
  - Digit
  - Hex_Digit
  - Join_Control
  - Noncharacter_Code_Point
  - Assigned
  - Emoji
  - Emoji_Presentation
  - Emoji_Modifier
  - Emoji_Modifier_Base
  - Emoji_Component
  - Extended_Pictographic
`Predefined Character classes`与`POSIX character classes`遵守附件C的建议
![表格](infoflow%202024-02-04%2017-22-16.png)
# Comparision to Perl 5
模式引擎执行传统的基于NFA的匹配，并按Perl 5中的顺序交替进行匹配。Pattern类中不支持的Perl概念
- 反向引用，\g{n}对于index捕获组，以及\g{name}的命名捕获组
- 条件概念`(?(condition)X) and (?(condition)X|Y)`
- 内嵌的code概念`constructs (?{code})`与`(??{code})`
- 内嵌的注释语法`(?#comment)`
- 预处理操作符\l \u \L \U

Pattern支持的但是Perl不支持的
- Character-class union and intersection

与Perl的主要的区别
- 在Perl中，\1到\9始终被解析为反向引用。大于9的\xx如果确实有这个数量的子捕获组，则表示捕获组，否则被认为是8进制数字的转义。在Pattern中8进制转义的形式始终是\0xxx。在此类中，\1到\9始终被解释为反向引用，并且如果正则表达式中的该点至少存在那么多子表达式，则接受更大的数字作为反向引用，否则解析器将丢弃数字，直到数字小于或等于现有组数或者是一位数。
- Perl使用`g`标志来请求从上次匹配中断处继续匹配。此功能由`Matcher`类隐式提供：重复调用`find`方法将从上次匹配停止的位置恢复，除非重置匹配器。
- 在Perl中，表达式顶层的嵌入标志会影响整个表达式。在Pattern中，嵌入标志始终在它们出现时生效，无论它们是在顶层还是在组内；在后一种情况下，标志会在组末尾恢复，就像在Perl中一样。
- Perl 中的自由间距模式（在此类中称为注释模式）在正则表达式中由 (?x) 表示（或在编译表达式时由 COMMENTS 标志）表示，不会忽略字符类内部的空格。 在此类中，字符类内部的空格必须进行转义，才能在注释模式下被视为正则表达式的一部分。