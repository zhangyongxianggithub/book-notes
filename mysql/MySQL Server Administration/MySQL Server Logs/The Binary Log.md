binary log包含事件，这些事件包括所有的数据库变更，比如创建表或者改变表数据。也包含可能产生数据变更的statements(在row-based模式下除外)。也包含statements的执行时间。有2个目的:
- 用于复制
- 数据恢复操作

Binlog不会记录没有变更数据的statements