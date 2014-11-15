library reader_tests;

import 'package:qvs/src/qv_exp_reader.dart';
import 'package:unittest/unittest.dart';

void shouldBeSuccess(QvExpReader reader) {
  for (var error in reader.errors) {
    print('------------------------------');
    print(error.commandWithError);
    print('>>>>> ' + error.errorMessage);
  }
  expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
}
void main() {
  solo_test('test_simplest', () {
    var code = r'''
---
set: vL.Dim
definition: $(=Only(Field1))
---
set: vL.Sum
definition: sum($(=Only(Field1)))
''';  
    var reader = newReader()..readFile('test.qlikview-vars',code);
    expect(reader.entries.length, 2);
    expect(reader.entries[0].sourceLineNum,1);
    expect(reader.entries[0].expression.name,'vL.Dim');
    expect(reader.entries[1].sourceLineNum,4);
    expect(reader.entries[1].expression.name,'vL.Sum');

  });
 
  test('Expression splitTag', () {
    var exp = new Expression();
    var tuple = exp.splitTag('set: abrakadabra');
    expect(tuple.key, 'set');
    expect(tuple.value, 'abrakadabra');

  });
 
  
  
}