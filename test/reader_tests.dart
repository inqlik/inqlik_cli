library reader_tests;

import 'package:qvs_parser/src/qvs_reader.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('test_simplest', () {
    var code = '''
        LOAD * 
        RESIDENT Table1
          ORDER BY Field1;
      TRACE FINISH;''';  
    var reader = newReader()..readFile('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.entries[1].sourceLineNum,4);
    expect(reader.entries[1].internalLineNum,2);
    expect(reader.entries[1].sourceText.trim(),'TRACE FINISH;');
    expect(reader.entries[0].sourceLineNum,1);
    expect(reader.entries[0].internalLineNum,1);
  });

  test('test_semicolon_in_string', () {
    var code = '''
        LOAD * as ';'
        RESIDENT Table1
          ORDER BY Field1;
      TRACE FINISH;''';  
    var reader = newReader()..readFile('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.entries[1].sourceLineNum,4);
    expect(reader.entries[1].internalLineNum,2);
    expect(reader.entries[1].sourceText.trim(),'TRACE FINISH;');
    expect(reader.entries[0].sourceLineNum,1);
    expect(reader.entries[0].internalLineNum,1);
  });

  test('test_simple_control_statement', () {
    var code = '''
      IF 2 = 3 THEN
        LOAD * 
        RESIDENT Table1
          ORDER BY Field1;
      END IF
      TRACE FINISH;''';  
    var reader = newReader()..readFile('test.qvs',code);
    expect(reader.entries.length, 4);
    expect(reader.entries[2].sourceText.trim(),'END IF');
    expect(reader.entries[2].sourceLineNum,5);
  });
  test('test_read_mock_files', () {
    var code = '''
      IF 2 = 3 THEN
        LOAD * 
        RESIDENT Table1
          ORDER BY Field1;
      END IF
      TRACE FINISH;
   ''';  
    var reader = newReader();
    reader.readFile('test1.qvs','TRACE in test1;');
    var nestedReader = reader.createNestedReader()..readFile('test2.qvs','TRACE in test2;');
    nestedReader.createNestedReader()..readFile('test3.qvs','TRACE in test3;');
    reader.readFile('test1.qvs','TRACE FINAL in test1;');
    expect(reader.entries.length, 4);
    expect(reader.entries[0].sourceFileName,endsWith('test1.qvs'));
    expect(reader.entries[1].sourceFileName,endsWith('test2.qvs'));
    expect(reader.entries[2].sourceFileName,endsWith('test3.qvs'));
    expect(reader.entries[3].sourceFileName,endsWith('test1.qvs'));
  });
  test('test_simplest_file', () {
    var reader = newReader();
    reader.readFile('files/file_included.qvs');
    expect(reader.hasErrors, isFalse);
    expect(reader.entries.length, 1);
    expect(reader.entries[0].sourceFileName,endsWith('file_included.qvs'));
  });
  test('test_file_with_include', () {
    var reader = newReader();
    reader.readFile('files/file_with_include.qvs');
    expect(reader.hasErrors, isFalse);
    expect(reader.entries.length, 4);
    expect(reader.entries[0].sourceFileName,endsWith('file_with_include.qvs'));
    expect(reader.entries[2].sourceFileName,endsWith('file_included.qvs'));
    expect(reader.entries[3].sourceFileName,endsWith('file_with_include.qvs'));
  });
  test('Test file with not-existent must_include file', () {
    var reader = newReader();
    reader.readFile('files/file_with_not_existent_must_include.qvs');
    expect(reader.hasErrors, isTrue);
    expect(reader.entries.length, 3);
    expect(reader.entries[0].sourceFileName,endsWith('file_with_not_existent_must_include.qvs'));
    expect(reader.entries[1].sourceFileName,endsWith('file_with_not_existent_must_include.qvs'));
    expect(reader.entries[2].sourceFileName,endsWith('file_with_not_existent_must_include.qvs'));
  });

  test('Test file with not-existent include file', () {
    var reader = newReader();
    reader.readFile('files/file_with_not_existent_include.qvs');
    expect(reader.hasErrors, isFalse);
    expect(reader.entries.length, 3);
    expect(reader.entries[0].sourceFileName,endsWith('file_with_not_existent_include.qvs'));
    expect(reader.entries[1].sourceFileName,endsWith('file_with_not_existent_include.qvs'));
    expect(reader.entries[2].sourceFileName,endsWith('file_with_not_existent_include.qvs'));
  });

  test('Test with simplest subroutine', () {
    var reader = newReader();
    var code = '''
      TRACE START;
      SUB test
        TRACE IN SUB test;
      END SUB
      TRACE FINISH;''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 5);
    expect(reader.subMap.containsKey('test'),isTrue);
    expect(reader.subMap['test'], 1);
  });

  test('Test with subroutine with dotted name', () {
    var reader = newReader();
    var code = '''
      TRACE START;
      SUB myLib.test(param1,param2)
        TRACE IN SUB test;
      END SUB
      TRACE FINISH;''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 5);
    expect(reader.subMap.containsKey('myLib.test'),isTrue);
    expect(reader.subMap['myLib.test'], 1);
  });

  test('Test simplest expansion', () {
    var reader = newReader();
    var code = r'''
      TRACE $(var1);''';  
    reader.data.variables['var1']='11';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.entries[0].expandedText.trim(),'TRACE 11;');
  });
  test('Test recursive expansion', () {
    var reader = newReader();
    var code = r'''
      TRACE $(var$(var1))$(var1);''';  
    reader.data.variables['var1']='1';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.entries[0].expandedText.trim(),'TRACE 11;');
  });

  test('Test variable creation (simple numeric)', () {
    var reader = newReader();
    var code = r'''
      LET var1 = 1;''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], '1');
  });

  test('Test variable creation (String quoted)', () {
    var reader = newReader();
    var code = r'''
      LET vL.var1 = 'Abc';''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('vL.var1'), isTrue);
    expect(reader.data.variables['vL.var1'], "Abc");
  });

  test('Test variable creation and expansion (String quoted)', () {
    var reader = newReader();
    var code = r'''
      LET vL.var1 = 'Abc';
      TRACE $(vL.var1)$(vL.var1);''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 2);
    expect(reader.entries[1].expandedText.trim(), 'TRACE AbcAbc;');
  });

  test('Test error for unclosed subroutine declaration', () {
    var reader = newReader();
    var code = r'''
      SUB test
        TRACE 1
      END SUB''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.hasErrors, isTrue,reason: 'Script shoud have error abour unclosed subroutine declaration');
  });
  test('Test skip parsing in subroutine declaration', () {
    var reader = newReader();
    var code = r'''
      SUB test
        TRACE 1;
      END SUB''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 3);
    expect(reader.hasErrors, isFalse);
    expect(reader.entries[1].parsed,isFalse);
    expect(reader.entries[0].parsed,isTrue);
    expect(reader.entries[2].parsed,isFalse);
  });
 
  test('Test simple parse error', () {
    var reader = newReader();
    var code = r'''
       TRACE asdf; string with single quote;''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 1);
    expect(reader.hasErrors, isTrue);
  });

  test('Test simple subroutine call', () {
    var reader = newReader();
    var code = r'''
SUB dummy
  LET x =  1;
END SUB
CALL dummy;''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 4);
    expect(reader.hasErrors, isFalse);
    expect(reader.entries[1].expandedText.trim(),'LET x =  1;');
    expect(reader.entries[1].parsed, isTrue);
    expect(reader.data.variables.length,1);
  });

  test('Test simple subroutine call', () {
    var reader = newReader();
    var code = r'''
SUB dummy
  LET x =  1;
  call dummy_internal;
END SUB
SUB dummy_internal
  LET y = 1;
END SUB
CALL dummy;''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse);
    expect(reader.entries.length, 8);
    expect(reader.data.variables.length,2);
  });

  test('Test call of undeclared subroutine', () {
    var reader = newReader();
    var code = r'''
CALL dummy('y');''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isTrue);
  });

  
  test('Test subroutine with parameter call (parameter use)', () {
    var reader = newReader();
    var code = r'''
SUB dummy (param1)
  LET x =  '$(param1)';
END SUB
CALL dummy('y');''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 4);
    expect(reader.hasErrors, isFalse);
    expect(reader.entries[1].expandedText.trim(),"LET x =  'y';");
    expect(reader.entries[1].parsed, isTrue);
    expect(reader.data.variables.length,1);
    expect(reader.data.variables['x'],'y');
  });
  
  test('Test read file with default_include.qvs in directory', () {
    var reader = newReader();
    reader.readFile(r'files1\test.qvs');
    expect(reader.entries.length, 2);
    expect(reader.hasErrors, isFalse);
    expect(reader.data.variables.containsKey('x'), isTrue);
    expect(reader.entries[1].expandedText.trim(),"TRACE 1;");
  });

  test('Test variable clearing', () {
    var reader = newReader();
    var code = r'''
      SET var1 = ; ''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], '');
  });

  test('Supress expansion in one-line commented blocks ', () {
    var reader = newReader();
    var code = r'''
      // TRACE $(x);
      SET var1 = ;''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 2);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], '');
  });

  test('Sub declaration properly closed ', () {
    var reader = newReader();
    var code = r'''
    LET LoadInterval.FromDate = Date(MakeDate(LoadInterval.Year),'YYYY-DD-MM');
End Sub''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length,2);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });
  
  test('Supress expansion in multi-line commented blocks ', () {
    var reader = newReader();
    var code = r'''
      /** 
        TRACE $(x);
        LET var2 = 4;
        asdf asdfasdf asdfasdf
      */
      SET var1 = ;''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries[0].commandType, QvsCommandType.COMMENT_LINE);
    expect(reader.entries[1].commandType, QvsCommandType.COMMENT_LINE);
    expect(reader.entries[2].commandType, QvsCommandType.COMMENT_LINE);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 6);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables.length, 1);
    expect(reader.data.variables['var1'], '');
  });

  test('IF function is not a control structure statement ', () {
    var reader = newReader();
    var code = r'''
  AsOfPeriodTable2:
  LOAD *,
       If (ТипПериода = 10 OR ТипПериода = 11 OR ТипПериода = 12 OR ТипПериода = 13, Day(MonthEnd(Дата)), _ДнейПрошлогоПериодаВМесяце) as _ДнейПрошлогоПериодаВМесяцеNew
  RESIDENT AsOfPeriodTable; ''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 1);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('Variable expansion in table identifier ', () {
    var reader = newReader();
    var code = r'''
  LET _tableName = 'Календарь';
  $(_tableName):
  LOAD *,If(_ПоследнийДеньПериода = Дата,1,0) AS _ФлагПоследнийДеньПериода;''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.data.variables.length, 1);
    expect(reader.data.variables['_tableName'], 'Календарь');
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });
  test('Subroutine with param. Parameter value not assigned on call. Param using should not be error', () {
      var reader = newReader();
      var code = r'''
Sub Dummy(message)
  TRACE '$(message)';
End Sub;
CALL Dummy;      ''';  
      reader.readFile('test.qvs',code);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
      expect(reader.entries[1].expandedText.trim(), "TRACE '';");
    });

  
  
  test('Parameter modification within subroutine. Parameter initially not assigned', () {
      var reader = newReader();
      var code = r'''
Sub Dummy(message)
  LET message = 'test';
  TRACE '$(message)';
End Sub;
CALL Dummy;
TRACE 'Out $(message)'; ''';  
      reader.readFile('test.qvs',code);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
      expect(reader.data.variables.length,1);
      expect(reader.data.variables['message'],'test');
      expect(reader.entries[2].expandedText.trim(),"TRACE 'test';");
      expect(reader.entries[5].expandedText.trim(),"TRACE 'Out test';");
    });

  test('Parameter modification within subroutine. Parameter assigned in call site', () {
      var reader = newReader();
      var code = r'''
Sub Dummy(message)
  LET message = 'test';
  TRACE '$(message)';
End Sub;
CALL Dummy('test1');
TRACE 'Out $(message)'; ''';  
      reader.readFile('test.qvs',code);
      expect(reader.hasErrors, isTrue,reason: 'Global variable should not been created');
      expect(reader.data.variables.isEmpty,isTrue);
      expect(reader.entries[2].expandedText.trim(),"TRACE 'test';");
    });
  test('One line comments within a command', () {
      var reader = newReader();
      var code = r'''
LOAD 
  Field1,
//  Field2,
  Field3 
    RESIDENT table1; ''';  
      reader.readFile('test.qvs',code);
      expect(reader.entries.length,1);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });
  
  test('Multi-line coment block', () {
      var reader = newReader();
      var code = r'''
/* 111111
2222222
333333*/ ''';  
      reader.readFile('test.qvs',code);
      expect(reader.entries.length,3);
      expect(reader.entries[0].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });
  
  test('One-line coment block', () {
      var reader = newReader();
      var code = r'''
// 111111
// 2222222
// 333333 ''';  
      reader.readFile('test.qvs',code);
      expect(reader.entries.length,3);
      expect(reader.entries[0].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('One-line coment block after empty line', () {
      var reader = newReader();
      var code = r'''

// 111111
// 2222222
// 333333 ''';  
      reader.readFile('test.qvs',code);
      expect(reader.entries.length,4);
      expect(reader.entries[0].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,QvsCommandType.COMMENT_LINE);
      expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  
  test('Test numeric const variable assigned be LET operation', () {
    var reader = newReader();
    var code = r'''
      LET var1 = 1; ''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], '1');
  });

  test('Test string const variable assigned be LET operation', () {
    var reader = newReader();
    var code = r'''
      LET var1 = 'test'; ''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], 'test');
  });
  test('Test expression assigned to variable by SET operation', () {
    var reader = newReader();
    var code = r'''
      SET var1 = purgeChar(peek('TABLE_NAME', i, 'ExcelSheets'), chr(39)); ''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], "purgeChar(peek('TABLE_NAME', i, 'ExcelSheets'), chr(39))");
  });
  test('Test expression assigned to variable by LET operation (fake value assigned)', () {
    var reader = newReader();
    var code = r'''
      LET var1 = purgeChar(peek('TABLE_NAME', i, 'ExcelSheets'), chr(39)); ''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
    expect(reader.data.variables.containsKey('var1'), isTrue);
    expect(reader.data.variables['var1'], "var1_ASSIGNED_VALUE");
  });

  
}