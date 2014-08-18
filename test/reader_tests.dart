library reader_tests;

import 'package:qvs_parser/src/qvs_reader.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('test_simple_1', () {
    var code = '''
        LOAD * 
        RESIDENT Table1
          ORDER BY Field1;
      TRACE FINISH;
   ''';  
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
      TRACE FINISH;
   ''';  
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
      TRACE FINISH;
   ''';  
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
    reader.readFile('files/file_with_not_existent_must_included.qvs');
    expect(reader.hasErrors, isTrue);
    expect(reader.entries.length, 3);
    expect(reader.entries[0].sourceFileName,endsWith('file_with_not_existent_must_included.qvs'));
    expect(reader.entries[1].sourceFileName,endsWith('file_with_not_existent_must_included.qvs'));
    expect(reader.entries[2].sourceFileName,endsWith('file_with_not_existent_must_included.qvs'));
  });

}