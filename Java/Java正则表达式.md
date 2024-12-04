正则表达式在很多编程语言中都有，包括grep、Perl、Python、PHP、awk等。它们可能互不兼容，Java中的正则表达式类似Perl。只需要引入`java.util.regex`依赖就可以用了。包含3个类:
- `Pattern`: 编译后的正则表达式，匹配中的状态存储在Matcher对象，所以它是并发安全的，
- `Mather`: 解释模式，在输入的字符串上执行匹配操作，不是并发安全的
- `PatternSyntaxException`: 表明语法错误的非检查异常

正则匹配字符串时可能会匹配0到多次。通过静态方法创建`Pattern`、`Matcher`对象后，调用`find`方法遍历输入为每个匹配返回true。
```java
@Test
public void givenText_whenSimpleRegexMatchesTwice_thenCorrect() {
    Pattern pattern = Pattern.compile("foo");
    Matcher matcher = pattern.matcher("foofoo");
    int matches = 0;
    while (matcher.find()) {
        matches++;
    }

    assertEquals(matches, 2);
}
```
# Meta Character
java正则中包含一些元字符，影响匹配的方式
- `.`也是dot，表示任意一个字符
- x表示单个字符
- \\表示\字符，需要转义
- \0n 8进制数表示的字符
- \0nn 8进制数表示的字符
- \0mnn 8进制数表示的字符
- \xhh 16进制表示的字符
- \uhhhh16 进制表示的字符
- \x{h...h} 16进制表示的字符
- \t
- \n
- \r
- \f
- \a
- \e
- \cx

# Character Class
字符类型，表示字符属于某一种类型
- [abc]也叫做OR字符Class
- NOR Class, [^abc]
- Range Class,[A-Z]或者[^A-Z]
- Union Class, class的union，[1-3[7-9]]
- Intersection Class, [1-6&&[3-9]]
- Subtraction Class, [0-9&&[^2468]]

# Predefined character classes
还有一些预定义的字符类型
- `\d` 数字
- `\D`非数字
- `\h`水平空白字符
- `\H`非水平空白字符
- `\s`空白符
- `\S`非空白符
- `\v`垂直空白符
- `\V`非垂直空白符
- `\w`字母与数字
- `\W`非字母与数字
# POSIX character classes (US-ASCII only)
- `\p{Lower}`	A lower-case alphabetic character: [a-z]
- `\p{Upper}`	An upper-case alphabetic character:[A-Z]
- `\p{ASCII}`	所有ascii字符:[\x00-\x7F]
- `\p{Alpha}`	字母:[\p{Lower}\p{Upper}]
- `\p{Digit}`	数字: [0-9]
- `\p{Alnum}`	字母或者数字:[\p{Alpha}\p{Digit}]
- `\p{Punct}`	标点符号: One of !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
- `\p{Graph}`	可以看到的字符: [\p{Alnum}\p{Punct}]
- `\p{Print}`	可打印字符: [\p{Graph}\x20]
- `\p{Blank}`	空格或者制表符: [ \t]
- `\p{Cntrl}`	控制字符: [\x00-\x1F\x7F]
- `\p{XDigit}`	16进制数字: [0-9a-fA-F]
- `\p{Space}`	空白符: [ \t\n\x0B\f\r]
# java.lang.Character classes (simple java character type)
- `\p{javaLowerCase}`	Equivalent to java.lang.Character.isLowerCase()
- `\p{javaUpperCase}`	Equivalent to java.lang.Character.isUpperCase()
- `\p{javaWhitespace}`	Equivalent to java.lang.Character.isWhitespace()
- `\p{javaMirrored}`	Equivalent to java.lang.Character.isMirrored()
# Classes for Unicode scripts, blocks, categories and binary properties
- `\p{IsLatin}`	A Latin script character (script)
- `\p{InGreek}`	A character in the Greek block (block)
- `\p{Lu}`	An uppercase letter (category)
- `\p{IsAlphabetic}`	An alphabetic character (binary property)
- `\p{Sc}`	A currency symbol
- `\P{InGreek}`	Any character except one in the Greek block (negation)
- `[\p{L}&&[^\p{Lu}]]`	Any letter except an uppercase letter (subtraction)
# 数量
- `?`匹配0或者1次
- `{m,n}`,n可以忽略
- `*`0次或者无数次={0,}
- `+`匹配至少一次={1,}
- `a{3}`精确匹配多少次
- `a{3,}`至少3次
- `a{2,3}`,匹配按照最大数量优先的原则
- `a{2,3}?`指定按照最小数量优先的原则
## Reluctant 数量
- `X??`	X, once or not at all
- `X*?`	X, zero or more times
- `X+?`	X, one or more times
- `X{n}?`	X, exactly n times
- `X{n,}?`	X, at least n times
- `X{n,m}?`	X, at least n but not more than m times

## Possessive quantifiers
`X?+`	X, once or not at all
`X*+`	X, zero or more times
`X++`	X, one or more times
`X{n}+`	X, exactly n times
`X{n,}+`	X, at least n times
`X{n,m}+`	X, at least n but not more than m times
# Logical operators
- `XY`	X followed by Y
- `X|Y`	Either X or Y
- `(X)`	X, as a capturing group
# Back references
- `\n`	Whatever the nth capturing group matched
- `\k<name>`	Whatever the named-capturing group "name" matched
# Quotation
- `\`	Nothing, but quotes the following character
- `\Q`	Nothing, but quotes all characters until \E
- `\E`	Nothing, but ends quoting started by \Q
# Special constructs (named-capturing and non-capturing)
- `(?<name>X)`	X, as a named-capturing group
- `(?:X)`	X, as a non-capturing group
- `(?idmsuxU-idmsuxU)` 	Nothing, but turns match flags i d m s u x U on - off
- `(?idmsux-idmsux:X)`  	X, as a non-capturing group with the given flags i d m s u x on - off
- `(?=X)`	X, via zero-width positive lookahead
- `(?!X)`	X, via zero-width negative lookahead
- `(?<=X)`	X, via zero-width positive lookbehind
- `(?<!X)`	X, via zero-width negative lookbehind
- `(?>X)`	X, as an independent, non-capturing group

# 捕获组
将多个字符看一个一个单元，捕获组有序号，可以通过序号引用捕获组。

# 边界
- `^`	The beginning of a line
- `$`	The end of a line
- `\b`	A word boundary
- `\B`	A non-word boundary
- `\A`	The beginning of the input
- `\G`	The end of the previous match
- `\Z`	The end of the input but for the final terminator, if any
- `\z`	The end of the input
 
# Description
`\`表示转义，也用来quote characters，这样这些字符就会被认为是普通文本而不会被你解析处理，\后面不能跟字母，这是未来扩展用的，0捕获组是中表示整个表达式。
## Line terminators
line terminator表示一个输入的字符串行终止的一个或者2个字符组，下面的字符被认为是line terminators
- \n
- \r\n
- \r
- \u0085
- \u2028
- \u2029

如果是UNIX_LINES模式，识别的line terminator是\n字符，正则表达式中的`.`会匹配任何字符除了行终止符，除非指定`DOTALL`标志。默认情况下^/$分别匹配整个输入的开始与结束，开启`MULTILINE`模式后，^匹配输入的开始或者行终止符之后的位置，$可以匹配行终止符或者输入的结束。
# Groups and Capturing
## Group number
捕获组的编号是通过从左到右的括号计算的，在表达式`((A)(B(C)))`中，有4个捕获组
- ((A)(B(C)))
- (A)
- (B(C))
- (C)

第0组表示整个表达式。捕获组会被存储并在后面可以使用
## Group name
捕获组可以指定名字成为命名捕获组。后面可以反向引用这个名字
# Unicode support
Pattern支持[Unicode Technical Standard #18: Unicode Regular Expressions](http://www.unicode.org/reports/tr18/)的Level1与RL2.1的Canonical Equivalents与RL2.2的Extended Grapheme Clusters. 
- Unicode转义序列（如Java源代码中的 \u2014）的处理方式详见《Java语言规范》第3.3节的描述。这样的转义序列也被正则表达式解析器直接实现，以便Unicode转义可以在从文件或键盘读取的表达式中使用。因此，字符串 "\u2014" 和 "\\u2014" 虽然不相等，但编译成相同的模式，该模式匹配十六进制值为0x2014的字符
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

Pattern类的方法`  public static Pattern compile(String regex, int flags)`,其中flags包含
- 0: 默认行为
- `Pattern.CANON_EQ`: 此标志启用规范等效性。指定后，当且仅当两个字符的完整规范匹配时，才会认为它们匹配。考虑带重音符号的Unicode字符é。其复合代码点是\u00E9。但是，Unicode还为其组成字符e(u0065)和尖音符(u0301)提供了单独的代码点。在默认情况下，复合字符\u00E9与两个字符序列\u0065\u0301是判断不了的，指定这个标志后就可以判断了。
  ```java
    @Test
    public void givenRegexWithoutCanonEq_whenMatchFailsOnEquivalentUnicode_thenCorrect() {
        int matches = runTest("\u00E9", "\u0065\u0301");
    
        assertFalse(matches > 0);
    }
    @Test
    public void givenRegexWithCanonEq_whenMatchesOnEquivalentUnicode_thenCorrect() {
        int matches = runTest("\u00E9", "\u0065\u0301", Pattern.CANON_EQ);
    
        assertTrue(matches > 0);
    }
  ```
- `Pattern.CASE_INSENSITIVE`: 忽略大小写，默认是考虑大小写的，也可以使用`(?i)`内嵌标志表达式来实现同样的效果
- `Pattern.CASE_INSENSITIVE`: 忽略注释，等价的内嵌表达式的形式`(?x)`
- `Pattern.DOTALL`: `.`也会匹配换行符，默认是到换行符终止。等价的内嵌标志表达式`(?s)`
- `Pattern.LITERAL`: 将任何元字符、转义字符与正则语法等都视为普通字符
- `Pattern.MULTILINE`: ^与$表示整个输入文本的开始与结束，没有考虑到换行符。加上这个后就会考虑换行符，内嵌标志表达式是`(?m)`

Matcher类的方法
- Index方法: 提供匹配字符串中的下标
  ```java
    @Test
    public void givenMatch_whenGetsIndices_thenCorrect() {
        Pattern pattern = Pattern.compile("dog");
        Matcher matcher = pattern.matcher("This dog is mine");
        matcher.find();
    
        assertEquals(5, matcher.start());
        assertEquals(8, matcher.end());
    }
  ```
- Study Methods: 遍历输入，返回是否匹配，`matches`与`lookingAt`方法
  ```java
    @Test
    public void whenStudyMethodsWork_thenCorrect() {
        Pattern pattern = Pattern.compile("dog");
        Matcher matcher = pattern.matcher("dogs are friendly");
    
        assertTrue(matcher.lookingAt());
        assertFalse(matcher.matches());
    }
  ```
- Replacement Methods: 替换文本，