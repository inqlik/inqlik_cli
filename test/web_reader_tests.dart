library reader_tests;

import 'package:qvs/src/qvs_reader.dart';
import 'package:unittest/unittest.dart';

void shouldBeSuccess(QvsReader reader) {
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
    var reader = readQvs('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.entries[1].sourceLineNum,4);
    expect(reader.entries[1].internalLineNum,2);
    expect(reader.entries[1].sourceText.trim(),'TRACE FINISH;');
    expect(reader.entries[0].sourceLineNum,1);
    expect(reader.entries[0].internalLineNum,1);
  });
  test('Incude directive in web mode should fail gracefully', () {
    var code = r'''
LET DayNames = 'Пн;Вт;Ср;Чт;Пт;Сб;Вс';
$(must_include=InQlik.qvs);''';  
    var reader = readQvs('test.qvs',code);
    expect(reader.entries.length, 2);
    expect(reader.errors.isNotEmpty, isTrue);
  });
  test('One simple line without semicolon', () {
    var code = r'''
  Some abrakadabra
''';  
    var reader = readQvs('test.qvs',code);
    expect(reader.entries.length, 1);
    expect(reader.errors.isNotEmpty, isTrue);
  });

}