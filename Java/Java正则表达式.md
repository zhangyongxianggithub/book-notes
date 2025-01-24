正则表达式在很多编程语言中都有，包括grep、Perl、Python、PHP、awk等。它们可能互不兼容，Java中的正则表达式类似Perl。只需要引入`java.util.regex`依赖就可以用了。包含3个类:
- `Pattern`: 编译后的正则表达式，匹配中的状态存储在Matcher对象，所以它是并发安全的，
- `Mather`: 解释模式，在输入的字符串上执行匹配操作，不是并发安全的
- `PatternSyntaxException`: 表明语法错误的非检查异常

正则匹配字符串时可能会匹配0到多次。通过静态方法创建`Pattern`、`Matcher`对象后，调用`find`方法遍历输入，为每个匹配返回true。
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
正则表达式首先被编译为`Pattern`类，然后匹配生成`Mathcer`对象，所有的执行状态保存在`Matcher`对象内，所以`Pattern`是并发安全的。`Pattern`类也定义了一个`matches`方法，当正则只使用一次的场景可以用，
# Meta Character
java正则中包含一些元字符，影响匹配的方式
- `.`也是dot，表示任意一个字符
- x表示单个字符
- \\表示\字符，需要转义
- \0n 8进制数表示的字符
- \0nn 8进制数表示的字符
- \0mnn 8进制数表示的字符
- \xhh 16进制表示的字符
- \uhhhh 16进制表示的字符
- \x{h...h} 16进制表示的字符，(`Character.MIN_CODE_POINT`  <= 0xh...h <=  `Character.MAX_CODE_POINT`)
- \t 制表符(\u0009)
- \n 换行符(\u000A)
- \r 回车符(\u000D)
- \f 换页符(\u000C)
- \a 报警生意bell(\u0007)
- \e 转义符号(\u001B)
- \cx x字符的控制字符

# Character Class
字符类型，表示字符属于某一种类型
- OR Class, [abc]也叫做OR字符Class
- NOR Class, [^abc]
- Range Class,[A-Z]或者[^A-Z]，inclusive
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
- `\p{javaLowerCase}`	等价于`java.lang.Character.isLowerCase()`
- `\p{javaUpperCase}`	等价于`java.lang.Character.isUpperCase()`
- `\p{javaWhitespace}` 等价于`java.lang.Character.isWhitespace()`
- `\p{javaMirrored}`	等价于`java.lang.Character.isMirrored()`
# Classes for Unicode scripts, blocks, categories and binary properties
- `\p{IsLatin}`	Latin字母
- `\p{InGreek}`	希腊字母
- `\p{Lu}` 大写字母
- `\p{IsAlphabetic}` 字母字符
- `\p{Sc}`货币符号
- `\P{InGreek}`除了希腊字母外的任何字符
- `[\p{L}&&[^\p{Lu}]]`除了大写字母外的任何字符
# 边界匹配
- `^`一行的开始
- `$`一行的结束
- `\b`单词的边界
- `\B`非单词边界
- `\A`输入的开始
- `\G`前面匹配的结束
- `\Z`输入的结束，表示的是最终的终止符号
- `\z`输入的结束
- `\R`换行字符，等价于`\u000D\u000A|[\u000A\u000B\u000C\u000D\u0085\u2028\u2029]`
# 贪婪模式数量
Greedy quantifiers: 一次读取所有字符进行匹配，再进行回溯
- `X?`匹配X0或者1次
- `X{m,n}`,至少m词，不超过n次
- `X*`0次或者无数次={0,}
- `X+`匹配至少一次={1,}
- `X{n}`精确匹配n次
- `X{n,}`至少n次
# 勉强模式数量
Reluctant quantifiers: 从左往右读，直到读完字符序列
- `X??`	X, 匹配X0或者1次
- `X*?`	X, 0次或者无数次={0,}
- `X+?`	X, 匹配至少一次={1,}
- `X{n}?`	X, 精确匹配n次
- `X{n,}?`	X, 至少n次
- `X{n,m}?`	X, 至少m次，不超过n次
# 独占模式数量
Possessive quantifiers: 一次读取所有字符匹配，不进行回溯
`X?+`	X, 匹配X0或者1次
`X*+`	X, 0次或者无数次={0,}
`X++`	X, 匹配至少一次={1,}
`X{n}+`	X, 精确匹配n次
`X{n,}+`	X, 至少n次
`X{n,m}+`	X, 至少m次，不超过n次

[关于3种数量的解答文档](https://stackoverflow.com/questions/5319840/greedy-vs-reluctant-vs-possessive-qualifiers)
# Logical operators
- `XY`	X followed by Y
- `X|Y`	要么X要么Y
- `(X)`	X, 一个捕获组，将多个字符看一个单元，捕获组有序号，可以通过序号引用捕获组。
# 向后引用
- `\n`第n个捕获组
- `\k<name>`命名的捕获组
# 引用
- `\`表示引用下面的字符
- `\Q`表示引用直到`\E`的所有的字符
- `\E`表示引用的结束
# 特殊结构 (named-capturing and non-capturing)
- `(?<name>X)`	X, 一个命名捕获组
- `(?:X)`	X, 一个非命名捕获组
- `(?idmsuxU-idmsuxU)` 	Nothing, but turns match flags i d m s u x U on - off
- `(?idmsux-idmsux:X)`  	X, as a non-capturing group with the given flags i d m s u x on - off
- `(?=X)`	X, via zero-width positive lookahead
- `(?!X)`	X, via zero-width negative lookahead
- `(?<=X)`	X, via zero-width positive lookbehind
- `(?<!X)`	X, via zero-width negative lookbehind
- `(?>X)`	X, 一个独立的非命名捕获组

# Backslashes、escaped and quoting
反斜杠字符`\`表示转义，也用来引用字符(表示不需要转义的字符)，这样这些字符就会被认为是普通文本而不会被解析转义处理，`\\`表示反斜杠字符本身，`\{`表示左括号。`\`后面不能跟字母，这是未来扩展用的，`\`可以放在任何的非字母前面，不论字符是否是普通文本的一部分。Java源代码中的字符串文字中的反斜杠按照Java™语言规范的要求解释为 Unicode转义或其他字符转义。因此，有必要在表示正则表达式的字符串文字中使用双反斜杠，以防止它们被Java字节码编译器解释。例如，字符串文字`\b`在解释为正则表达式时匹配单个退格字符，而`\\b`匹配单词边界。字符串文字`\(hello\)`是非法的，会导致编译时错误；为了匹配字符串`(hello)`，必须使用字符串文字`\\(hello\\)`。
# Charater Classes
字符类可以出现在其他字符类中。默认是是区并集操作。也可以取交集操作`&&`，集合操作的优先级如下:
- Literal escape: \x
- Grouping: [...]
- Range: a-z
- Union: [a-e][i-u]
- Intersection: [a-z&&[aeiou]]

请注意，字符类内部和外部的元字符集有所不同。例如，正则表达式`.`在字符类内部会失去其特殊含义，而表达式`-`则会变成范围元字符。
## Line terminators
line terminator表示一个输入的字符串序列中一行终止的一个或者2个字符，下面的字符被认为是line terminators
- \n
- \r\n
- \r
- \u0085=\n
- \u2028 行分隔符
- \u2029 段落分隔符

如果激活了`UNIX_LINES`模式，识别的line terminator是`\n`字符，正则表达式中的`.`会匹配任何字符除了行终止符，除非指定`DOTALL`标志。默认情况下`^`与`$`会忽略行终止符分别匹配整个输入的开始与结束，开启`MULTILINE`模式后，`^`匹配输入的开始或者行终止符之后的位置，$可以匹配行终止符之前或者输入的结束。
# Groups and Capturing
## Group number
捕获组的编号是通过从左到右的括号顺序计算得到的，在表达式`((A)(B(C)))`中，有4个捕获组
- ((A)(B(C)))
- (A)
- (B(C))
- (C)

第0组表示整个表达式。捕获组可以命名，会被存储并在后面可以使用(通过back reference)，也能从matcher中检索。
## Group name
捕获组可以指定名字成为命名捕获组。后面可以通过名字反向引用这个捕获组，捕获组名字有下面的字符组成
- A-Z
- a-z
- 0-9

与组关联的捕获输入始终是该组最近匹配的子序列。如果由于量化而对组进行第二次评估，则如果第二次评估失败，则将保留其先前捕获的值（如果有）。例如，将字符串`aba`与表达式`(a(b)?)+`匹配，会使第二组设置为`b`。每次匹配开始时，所有捕获的输入都会被丢弃。以`(?`开头的组要么是纯粹的非捕获组，不捕获文本，也不计入组总数，要么是命名捕获组
# Unicode support
Pattern支持[Unicode Technical Standard #18: Unicode Regular Expressions](http://www.unicode.org/reports/tr18/)的Level1与RL2.1的Canonical Equivalents与RL2.2的Extended Grapheme Clusters. 
- Unicode转义序列: Java源代码中的Unicode转义序列(例如\u2014)的处理方式如Java™语言规范第3.3节所述。此类转义序列也由正则表达式解析器直接实现，因此 Unicode转义可用于从文件或键盘读取的表达式中。因此，字符串`\u2014`和`\\u2014`虽然不相等，但编译成相同的模式，该模式与十六进制值为0x2014的字符匹配。Unicode 字符也可以通过直接使用其十六进制表示法(十六进制代码点值)在正则表达式中表示，如构造`\x{...}`中所述，例如，可以将补充字符U+2011F指定为\x{2011F}，而不是代理对\uD840\uDD1F的两个连续Unicode转义序列。Unicode脚本、块、类别和二进制属性使用\p和\P构造编写，就像在Perl中一样。如果输入具有属性prop，则`\p{prop}`匹配，而如果输入具有该属性，则`\P{prop}`不匹配。脚本、块、类别和二进制属性可以在字符类内部和外部使用。
- Unicode scripts通过前缀`Is`指定，比如`IsHiragana`，或者使用`script(sc)`关键词来指定，比如`script=Hiragana`或者`sc=Hiragana`，Pattern支持的script名字是定义在[UnicodeScript.forName](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Character.UnicodeScript.html#forName(java.lang.String))
- Blocks通过前缀`In`指定的，比如`InMongolian`或者使用关键词`block(blk)`比如`block=Mongolian`或者`blk=Mongolian`，Pattern支持的block名字是通过[UnicodeBlock.forName](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Character.UnicodeBlock.html#forName(java.lang.String))定义的
- Categories是通过可选的前缀`Is`指定的，`\p{L}`与`\p{IsL}`表示Unicode letter的种类，Categories也可以通过关键词指定，比如`general_category=Lu`与`gc=Lu`，支持的Categories定义在Charcter类中的[The Unicode Standard](http://www.unicode.org/standard/standard.html)，类别名称是标准中定义的名称，既具有规范性又具有参考性。
- Binary properties通过前缀`Is`指定，比如`IsAlphabetic`，Pattern支持的Binary properties如下:
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
| **Classes** | **Matches**                                                                                  |
|-------------|----------------------------------------------------------------------------------------------|
| \p{Lower}   | A lowercase character:\p{IsLowercase}                                                        |
| \p{Upper}   | An uppercase character:\p{IsUppercase}                                                       |
| \p{ASCII}   | All ASCII:[\x00-\x7F]                                                                        |
| \p{Alpha}   | An alphabetic character:\p{IsAlphabetic}                                                     |
| \p{Digit}   | A decimal digit character:\p{IsDigit}                                                        |
| \p{Alnum}   | An alphanumeric character:[\p{IsAlphabetic}\p{IsDigit}]                                      |
| \p{Punct}   | A punctuation character:\p{IsPunctuation}                                                    |
| \p{Graph}   | A visible character: [^\p{IsWhite_Space}\p{gc=Cc}\p{gc=Cs}\p{gc=Cn}]                         |
| \p{Print}   | A printable character: [\p{Graph}\p{Blank}&&[^\p{Cntrl}]]                                    |
| \p{Blank}   | A space or a tab: [\p{IsWhite_Space}&&[^\p{gc=Zl}\p{gc=Zp}\x0a\x0b\x0c\x0d\x85]]             |
| \p{Cntrl}   | A control character: \p{gc=Cc}                                                               |
| \p{XDigit}  | A hexadecimal digit: [\p{gc=Nd}\p{IsHex_Digit}]                                              |
| \p{Space}   | A whitespace character:\p{IsWhite_Space}                                                     |
| \d          | A digit: \p{IsDigit}                                                                         |
| \D          | A non-digit: [^\d]                                                                           |
| \s          | A whitespace character: \p{IsWhite_Space}                                                    |
| \S          | A non-whitespace character: [^\s]                                                            |
| \w          | A word character: [\p{Alpha}\p{gc=Mn}\p{gc=Me}\p{gc=Mc}\p{Digit}\p{gc=Pc}\p{IsJoin_Control}] |
| \W          | A non-word character: [^\w]                                                                  |

# Comparision to Perl 5
模式引擎执行传统的基于NFA的匹配，并按Perl 5中的顺序交替进行匹配。Pattern类中不支持的Perl结构
- back reference，`\g{n}`对于第n个捕获组，以及`\g{name}`的命名捕获组的定义
- 条件结构`(?(condition)X)`与`(?(condition)X|Y)`
- 内嵌的code结构`constructs (?{code})`与`(??{code})`
- 内嵌的注释语法`(?#comment)`
- 预处理操作符`\l`、`\u`、`\L`、`\U`

Pattern支持的但是Perl不支持的
- Character-class union and intersection

与Perl的主要的区别
- 在Perl中，`\1`到`\9`始终被解析为反向引用。大于9的\xx如果确实有这个数量的子捕获组，则表示捕获组，否则被认为是8进制数字的转义。在Pattern中8进制转义的形式始终是\0xxx。在此类中，\1到\9始终被解释为反向引用，并且如果正则表达式中的该点至少存在那么多子表达式，则接受更大的数字作为反向引用，否则解析器将丢弃数字，直到数字小于或等于现有组数或者是一位数。
- Perl使用`g`标志来请求从上次匹配中断处继续匹配。此功能由`Matcher`类隐式提供：重复调用`find`方法将从上次匹配停止的位置恢复，除非重置匹配器。
- 在Perl中，表达式顶层的嵌入标志会影响整个表达式。在Pattern中，嵌入标志始终在它们出现时生效，无论它们是在顶层还是在组内；在后一种情况下，标志会在组末尾恢复，就像在Perl中一样。
- Perl 中的自由间距模式（在此类中称为注释模式）在正则表达式中由 (?x) 表示（或在编译表达式时由 COMMENTS 标志）表示，不会忽略字符类内部的空格。 在此类中，字符类内部的空格必须进行转义，才能在注释模式下被视为正则表达式的一部分。
# 使用
## Pattern
Pattern类的方法`public static Pattern compile(String regex, int flags)`,其中flags包含
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

## Matcher
执行匹配操作的引擎，通过Pattern创建，执行3类操作
- matches: 尝试匹配整个输入与模式
- lookingAt: 尝试从某个点开始匹配输入与模式
- find: 扫描整个输入，寻找下一个匹配模式的子序列

返回值表明成功还是失败，成功更多的信息可以通过获取Matcher的状态得到。匹配器在其输入(称为区域)的子集中查找匹配项。默认情况下，区域包含匹配器的所有输入。可以通过`region`方法修改区域，并通过`regionStart`和`regionEnd`方法查询区域。可以更改区域边界与某些模式接口交互的方式。有关更多详细信息，请参阅[useAnchoringBounds](https://devdocs.io/openjdk~21/java.base/java/util/regex/matcher#useAnchoringBounds(boolean))和 [useTransparentBounds](https://devdocs.io/openjdk~21/java.base/java/util/regex/matcher#useTransparentBounds(boolean))。此类还定义了用于字符串替换的方法，如果需要，可以从匹配结果中计算新字符串的内容。可以结合使用 `appendReplacement`和`appendTail`方法，以便将结果收集到现有的字符串缓冲区或字符串生成器中。或者，可以使用更方便的`replaceAll`方法来创建一个字符串，其中替换输入序列中的每个匹配子序列。匹配器的显式状态包括最近成功匹配的开始和结束索引。它还包括模式中每个捕获组捕获的输入子序列的起始和结束索引以及此类子序列的总数。为方便起见，还提供了以字符串形式返回这些捕获的子序列的方法。匹配器的显式状态最初未定义；在成功匹配之前尝试查询它的任何部分将导致抛出 `IllegalStateException`。匹配器的显式状态由每个匹配操作重新计算。匹配器的隐式状态包括输入字符序列以及附加位置，该位置最初为零，并由`appendReplacement`方法更新。可以通过调用匹配器的`reset()`方法显式重置匹配器，或者如果需要新的输入序列，则调用其`reset(CharSequence)`方法。重置匹配器会丢弃其显式状态信息并将附加位置设置为零。此类的实例是并发不安全的
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
- Replacement Methods: 替换文本

