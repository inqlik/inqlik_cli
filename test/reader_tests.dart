library reader_tests;

import 'package:qvs/src/file_reader.dart';
import 'package:qvs/src/qvs_reader.dart';
import 'package:unittest/unittest.dart';

void shouldBeSuccess(FileReader reader) {
  for (var error in reader.errors) {
    print('------------------------------');
    print(error.commandWithError);
    print('>>>>> ' + error.errorMessage);
  }
  expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
}

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
    var nestedReader = reader.readIncludeFile('test2.qvs','TRACE in test2;',null);
    nestedReader.readIncludeFile('test3.qvs','TRACE in test3;',null);
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
    expect(reader.subMap['test'].startIndex, 1);
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
    expect(reader.subMap['myLib.test'].startIndex, 1);
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

  test('Test recursive expansion with assignment', () {
    var reader = newReader();
    var code = r'''
      LET var1 = 1;
      TRACE $(var$(var1))$(var1);''';  
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 2);
    expect(reader.entries[1].expandedText.trim(),'TRACE 11;');
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
Sub Dummy
    LET LoadInterval.FromDate = Date(MakeDate(LoadInterval.Year),'YYYY-DD-MM');
End Sub''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length,3);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('Unmatched end of sub declaration', () {
    var reader = newReader();
    var code = r'''
    LET LoadInterval.FromDate = Date(MakeDate(LoadInterval.Year),'YYYY-DD-MM');
End Sub''';  
    reader.readFile('test.qvs',code);
    expect(reader.entries.length,2);
    expect(reader.hasErrors, isTrue,reason: 'Redundant end of sub should be error');
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
    expect(reader.entries[0].commandType, CommandType.COMMENT_LINE);
    expect(reader.entries[1].commandType, CommandType.COMMENT_LINE);
    expect(reader.entries[2].commandType, CommandType.COMMENT_LINE);
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
      expect(reader.entries[1].expandedText.trim(), "TRACE 'message_NULL_VALUE';");
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
      expect(reader.entries[0].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,CommandType.COMMENT_LINE);
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
      expect(reader.entries[0].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,CommandType.COMMENT_LINE);
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
      expect(reader.entries[0].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[1].commandType,CommandType.COMMENT_LINE);
      expect(reader.entries[2].commandType,CommandType.COMMENT_LINE);
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

  test('Test command with trailing one-line comment', () {
    var reader = newReader();
    var code = r'UNQUALIFY "_qvctemp.*"; // UNQUALIFY all qvctemp field';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.length, 1);
  });
  
  test('FOR NEXT loop create variable', () {
    var reader = newReader();
    var code = r'''
FOR i = 1 to 3
  TRACE $(i);
NEXT i;
TRACE $(i);
''';
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 5);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('LOOP is control statement', () {
    var reader = newReader();
    var code = r'''
  DO WHILE Purchase.ProcessDate <= Num(MakeDate(2014,01))
      LET Purchase.ProcessYear = Year(Purchase.ProcessDate);
LOOP
TRACE $(Purchase.ProcessYear);''';
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 4);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('Suppress Errors shebang comment statemet', () {
    var reader = newReader();
    var code = r'''
      ABRAKADABRA; //#!SUPPRESS_ERROR''';
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 1);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });
  
  test('For each with filelist create variable', () {
    var reader = newReader();
    var code = r'''
  for each File in filelist ('*.xls')
    trace $(File);    
  next
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries[1].expandedText.trim(),'trace *.xls;');    
  });

  test('For each with value list create variable', () {
    var reader = newReader();
    var code = r'''
  for each ext in 'qvw', 'qva', 'qvo', 'qvs'
    trace $(ext);    
  next
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries[1].expandedText.trim(),'trace qvw;');    
  });

  test('Ignore comments at end of line', () {
    var reader = newReader();
    var code = r'''
SET vMinDate = Num(MakeDate(2012,01));//$(DateRange.Min);
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries.first.expandedText.trim(),'SET vMinDate = Num(MakeDate(2012,01));');  
  });

  test('SKIP_PARSING shebang comment statement', () {
    var reader = newReader();
    var code = r'''
//#!..\..\1.Application\
//#!SKIP_PARSING
ABRAKADABRA ;
ANOTHER ABRAKADABRA;
SOME OTHER ABRAKADABRA;
''';
    reader.readFile('test.qvs',code);
    expect(reader.entries.length, 1);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
  });

  test('Test qvw file location without shebang directive ', () {
    var reader = newReader();
    reader.readFile('files1\\file_without_shebang_qvw_directive.qvs');
    expect(reader.entries.isEmpty, isFalse);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.qvwFileName, isNotNull);
    expect(reader.data.qvwFileName,contains('files1\\file_without_shebang_qvw_directive.qvw'));
  });

  test('Test qvw file location with shebang directive ', () {
    var reader = newReader();
    reader.readFile('files/file_with_shebang_qvw_directive.qvs');
    expect(reader.entries.isEmpty, isFalse);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.qvwFileName, isNotNull);
    expect(reader.data.qvwFileName,contains('files1\\file_with_shebang_qvw_directive.qvw'));
  });
  
  test('Test table management', () {
    var reader = newReader();
    var code = r'''
Table1:
LOAD *;
LOAD * FROM 123.qvd(qvd);
Concatenate(Table1)
LOAD * RESIDENT Table1;
Join(Table1)
LOAD * RESIDENT Table1;
Table2:
LOAD * RESIDENT xxx;
RENAME TABLE Table1 to TableFinal;
DROP TABLE Table2;
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.tables.length,1);
    expect(reader.data.tables.first,'TableFinal');
  });

  test('Variable creation in FOR NEXT. Initialized by expression', () {
    var reader = newReader();
    var code = r'''
FOR n = Num(now()) TO Num(MakeDate(2016))
 TRACE $(n);
NEXT n    
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.entries.length,4);
    expect(reader.data.entries[1].expandedText.trim(), 'TRACE n_ASSIGNED_VALUE;');
  });
  
  test('Nested subroutines', () {
    var reader = newReader();
    var code = r'''
SUB Dummy(outParam)
  SUB _NestedInDummy(innerParam) 
    TRACE $(outParam) $(innerParam);  
  END SUB
  CALL _NestedInDummy('Inner');
  TRACE $(outParam);
END SUB
CALL Dummy('Outer');
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.entries[2].expandedText.trim(),'TRACE Outer Inner;');
  });

  
  test('Multiline comment on one line', () {
    var reader = newReader();
    var code = r'''
/* asdfasdf*/
LET var1 =  1;
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.variables.length,1);
  });

  test('LET assignment without let', () {
    var reader = newReader();
    var code = r'''
 var1 =  1;
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.variables.length,1);
  });

  test('LET assignment without let', () {
    var reader = newReader();
    var code = r'''
 var1 =  1;
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
    expect(reader.data.variables.length,1);
  });

  test('SUB default parameters assignment pattern: If/let', () {
    var reader = newReader();
    var code = r'''
  SUB GenerateBaseQVD(GenerateBaseQVD_DocumentType, GenerateBaseQVD_StartYear)
    IF Len('$(GenerateBaseQVD_StartYear)') = 0 THEN
      LET GenerateBaseQVD_StartYear = 0;
    ELSE 
     LET GenerateBaseQVD_StartYear = $(GenerateBaseQVD_StartYear);
    ENDIF
  END SUB
  CALL GenerateBaseQVD('asd',2);
''';
    reader.readFile('test.qvs',code);
    expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');

  });
  
  test('TEST Expressions in SUB parameters', () {
    var reader = newReader();
    var code = r'''
  SUB LoadPlanByYear(LoadByYear.Year)
    Plan:
    LOAD * FROM Plan_$(LoadByYear.Year).QVD(QVD);
  END SUB
//  CALL LoadPlanByYear('2014');
  CALL LoadPlanByYear(Max(Year)-1);
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });

  test('Include statement without semicolon', () {
    var reader = newReader();
    var code = r'''
$(Include=..\qvc_runtime\qvc.qvs)
BigTable:
LOAD 1 as X AutoGenerate 2000;
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });
  
  test('Multilene comment on one line followed by REM comment', () {
    var reader = newReader();
    var code = r'''
/* Logging subroutine */
REM Default configuration for Qvc.Log;
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });

  test('On-line comment in string ', () {
    var reader = newReader();
    var code = r'''
  _colorTable:
  LOAD trim(ColorVariable) as _qvctemp.ColorVariable,
       trim(ColorValue) as _qvctemp.ColorValue
  FROM
  [_themeFile]
  (ooxml, embedded labels, table is Sheet1)
  WHERE len(trim(ColorVariable))>0 and left(trim(ColorVariable),2) <> '//'
  ;
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });

  test('Recursive Subroutines', () {
    var reader = newReader();
    var code = r'''
SUB Recurse(_dir, _goInto)
   IF Len('$(_goInto)') = 0 THEN
      CALl Recurse('$(_dir)','-1')
   END IF  
END SUB
CALL Recurse('dummyDir');
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });

  test('Recursive Subroutines', () {
    var reader = newReader();
    var code = r'''
SUB Recurse(_dir, _goInto)
   IF Len('$(_goInto)') = 0 THEN
      CALl Recurse('$(_dir)','-1')
   END IF  
END SUB
CALL Recurse('dummyDir');
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });
  
  skip_test('Variable with parameter expansion (Macrofunction)', () {
    var reader = newReader();
    var code = r'''
SET mask=;
SET _Qvc.DefaultIfEmpty = if(len('$1')= 0,'$2', '$1');
LET mask = $(_Qvc.DefaultIfEmpty($(mask), '*'));
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
    expect(reader.entries[2].expandedText, r"LET mask = if(len('$(mask)')= 0,'*', $(mask);");
  });
  skip_test('Variable with parameter expansion - error on wrong parameter', () {
    var reader = newReader();
    var code = r'''
SET mask=;
SET _Qvc.DefaultIfEmpty = if(len('$1')= 0,'$2', '$1');
LET mask = $(_Qvc.DefaultIfEmpty('$(mask)', '*'));
''';
    reader.readFile('test.qvs',code);
    expect(reader.errors.isNotEmpty, isTrue);
  });

  test('Mixed lang name of subroutine', () {
    var reader = newReader();
    var code = r'''
SUB ПродажиТоваровByMonth(OnHandByMonth.Year, OnHandByMonth.Month, OnHandByMonth.removeTmpFiles)
  LET OnHandByMonth.Month = Num(OnHandByMonth.Month,'00');
END SUB
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });

  test('Switch statement', () {
    var reader = newReader();
    var code = r'''
LET I = 2;
switch I
case 1
load '$(I): CASE 1' as case autogenerate 1;
case 2
load '$(I): CASE 2' as case autogenerate 1;
default
load '$(I): DEFAULT' as case autogenerate 1;
end switch
''';
    reader.readFile('test.qvs',code);
    shouldBeSuccess(reader);
  });
}