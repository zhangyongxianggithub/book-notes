#!/usr/bin/env python3
from clang.cindex import Index, TranslationUnit, Config
import clang
# Config.set_library_file('/Library/Developer/CommandLineTools/usr/lib/libclang.dylib')
Config.set_library_file('/usr/lib/x86_64-linux-gnu/libclang-18.so.1')

def dump_ast(filename, output_filename):
  # 创建索引对象
  index =  clang.cindex.Index.create()


  # 解析源文件
  tu = index.parse(filename)
  # 获取主翻译单元
  # tu = translation_unit.getPrimaryTranslationUnit()
  # 创建 AST 访问器
  ast_visitor = ASTVisitor()

  # 遍历 AST 并访问节点
  ast_visitor.visit(tu.cursor)

  # 将 AST 写入文件
  with open(output_filename, 'w') as f:
    f.write(ast_visitor.ast_dump)

class ASTVisitor(object):
  def __init__(self):
    self.ast_dump = ''

  def visit(self, cursor, parent=None):
    if cursor.kind == 'FunctionDecl':
      self.ast_dump += f'FunctionDecl: {cursor.spelling}\n'
    elif cursor.kind == 'VarDecl':
      self.ast_dump += f'VarDecl: {cursor.spelling}\n'
    elif cursor.kind == 'Stmt':
      self.ast_dump += f'Stmt: {cursor.kind}\n'

    for child in cursor.get_children():
      self.visit(child, cursor)

if __name__ == '__main__':
  filename = 'acksync.cpp'
  output_filename = 'asksync.ast'

  dump_ast(filename, output_filename)
