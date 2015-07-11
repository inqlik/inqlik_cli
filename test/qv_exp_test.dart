library reader_tests;

import 'package:inqlik_cli/src/qv_exp_reader.dart';
import 'package:test/test.dart';
part 'qv_exp_test_constants.dart';
void shouldBeSuccess(QvExpReader reader) {
  for (var error in reader.errors) {
    print('------------------------------');
    print(error.commandWithError);
    print('>>>>> ' + error.errorMessage);
  }
  expect(reader.hasErrors, isFalse,reason: 'Script must have no errors');
}
void main() {
  test('test_simplest', () {
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

  test('Test splitted lines', () {
    var code = r'''
---
set: Sales
definition: Sum(Amount)
label: Sales
comment: Sales amount for 
  selected period
backgroundColor: =LightGreen(96)
tag: Another tag
''';  
    var reader = newReader()..readFile('test.qlikview-vars',code);
    expect(reader.entries.length, 1);
    expect(reader.entries[0].entryType,EntryType.EXPRESSION);
    Expression exp = reader.entries[0].expression;
    expect(exp.name,'Sales');
    expect(exp.tags['label'],' Sales');
    expect(exp.tags['comment'],startsWith(' Sales amount for '));

  });

  
  
  test('Test directives', () {
    var code = r'''
#define ABRACADABRA = 1

#SECTION :Chart expressions
---
set: DynamicDim
definition: $(=Only(DimField)) 
---
set: Sales
definition: Sum(Amount)
label: Sales
comment: Sales amount for 
  selected period
backgroundColor: =LightGreen(96)
tag: Another tag
''';  
    var reader = newReader()..readFile('test.qlikview-vars',code);
    expect(reader.entries.length, 5);
    expect(reader.entries[0].entryType,EntryType.DEFINE);
    expect(reader.entries[1].entryType,EntryType.BLANK);
    expect(reader.entries[2].entryType,EntryType.SECTION_HEADER);
    expect(reader.entries[3].entryType,EntryType.EXPRESSION);
    Expression exp = reader.entries[3].expression;
    expect(exp.name,'DynamicDim');
    expect(exp.section, ':Chart expressions');
    expect(reader.entries[4].entryType,EntryType.EXPRESSION);
    exp = reader.entries[4].expression;
    expect(exp.name,'Sales');
    expect(exp.tags['label'],' Sales');
    expect(exp.tags['comment'],startsWith(' Sales amount for '));

  });

  test('Expression splitTag', () {
    var exp = new Expression();
    var tuple = exp.splitTag('set: abrakadabra');
    expect(tuple.key, 'set');
    expect(tuple.value.trim(), 'abrakadabra');

  });
 
  
  test('Reader printOut', () {
    var source = TEST_FILE_CONTENTS.replaceAll("\r\n", "\n");
    var reader = newReader()..readFile('test.qlikview-vars',source);
    source = source +"\n";
    expect(reader.printOut(),source);
  });

//  test('Csv export', () {
//    var source = TEST_FILE_CONTENTS;
//    var reader = newReader()..readFile('test.qlikview-vars',source);
//    var out = reader.CsvOut();
//    File outFile = new File('CsvOut.csv');
//    outFile.writeAsBytesSync(out);
//  });
  

  
  test('Macros', () {
    var source = r"""
---
set: MacroFunc
definition: Sum($1)
---
set: MacroApplication
macro: MacroFunc
  - Field1
""";
    var reader = newReader()..readFile('test.qlikview-vars',source);
    expect(reader.entries.length, 2);
    expect(reader.entries[0].entryType,EntryType.EXPRESSION);
    expect(reader.entries[1].entryType,EntryType.MACRO);
    expect(reader.entries[1].expression.definition,'Sum(Field1)');
//    print(reader.printOut());
  });
  
  
  test('Simplest syntax check', () {
    var source = r"""
---
set: SumAmount
definition: Sum(Amount)
""";
    var reader = newReader()..readFile('test.qlikview-vars',source);
    expect(reader.entries.length, 1);
    reader.checkSyntax();
    shouldBeSuccess(reader);
  });
    
  test('Syntax check with define directive', () {
    var source = r"""
#define #Sales 12
---
set: SumAmount
definition: Sum({<Sales={#Sales}>} Amount)
""";
    var reader = newReader()..readFile('test.qlikview-vars',source);
    expect(reader.entries.length, 2);
    expect(reader.entries.last.expression.definition.trim(), 'Sum({<Sales={12}>} Amount)');
    reader.checkSyntax();
    shouldBeSuccess(reader);
  });

  test('Syntax check - supress error', () {
    var source = r"""
#SECTION :Set filter snippets //#!QvSuppressError
---
set: FilterSnippet
definition: Field1={2}
""";
    var reader = newReader()..readFile('test.qlikview-vars',source);
    expect(reader.entries.length, 2);
    expect(reader.entries.last.expression.definition.trim(), 'Field1={2}');
    reader.checkSyntax();
    shouldBeSuccess(reader);
  });

  test('Functional test', () {
    var reader = newReader()..readFile('exp_parser\\App.Variables.qlikview-vars');
    reader.checkSyntax();
    shouldBeSuccess(reader);
  },skip: true);

}
