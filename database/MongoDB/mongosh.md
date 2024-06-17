# 执行CRUD操作
## 查询文档
`db.collection.find()`查询集合中的文档
- 读取集合中的所有文档: `db.collection.find({})`或者`db.collection.find()`
- 指定条件匹配的文档，`db.movies.find( { "title": "Titanic" } )`
- 使用[查询运算符](https://www.mongodb.com/zh-cn/docs/manual/core/document/#document-query-filter)执行更复杂的筛选，类似`{ <field1>: { <operator1>: <value1> }, ... }`比如`db.movies.find( { rated: { $in: [ "PG", "PG-13" ] } } )`, 
- 多个条件默认是`AND`逻辑，`$or`操作符指定符合查询
  ```javascript
    db.movies.find( {
        year: 2010,
        $or: [ { "awards.wins": { $gte: 5 } }, { genres: "Drama" } ]
    } )
  ```
- 