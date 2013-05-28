library simple_tests;

import 'package:qvs_parser/src/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvsGrammar();


Result _parse(String source, String production) {
  var parser = qvs[production].end();
  return parser.parse(source);
}

dynamic shouldFail(String source, String production) {
  expect(_parse(source, production).isFailure,isTrue);
}

dynamic shouldPass(String source, String production) {
  expect(_parse(source, production).isSuccess,isTrue);
}

void main() {
  var s = r'''RecNo( ) as Af''';
  print(_parse(s,'field').value);
//return;
  test('testIdentifier1', () {
    shouldPass('SimpleName', 'identifier');
  });
  test('testIdentifier2', () {
    shouldPass('_SimpleNameWithUnderscore', 'identifier');
  });
  test('testIdentifier3', () {
    shouldPass('@4', 'identifier');
  });
  test('testIdentifier4', () {
    shouldPass('_КодНоменклатуры', 'identifier');
  });
  test('testIdentifier5', () {
    return shouldFail('~КодНоменклатуры', 'identifier');
  });
  test('testDropTable1',() {
    shouldPass('DROP TABLES WeeklySales;', 'drop table');    
  });
  
  test('testDropTable2',() {
    shouldPass('DROP TABLE WeeklySales, InventTableDepartment, WeeklyZeroSales;', 'drop table');    
  });
  test('tableOrFilename1', () {
    shouldPass('[..\Data\Source\план по подгруппам магазинам и каналам сбыта.xls]','tableOrFilename');   
  });
  test('fieldref1', () {
    shouldPass(' [41275]','fieldref');   
  });
  test('fileOptions1', () {
  String fileOptionsStr = r'''
    (biff, embedded labels,
 header is 1 lines, table is [Sheet1$],
filters(
Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
)
    )''';
    shouldPass(fileOptionsStr,'fileModifier');
  });
  
  test('fileOptions2', () {
  String fileOptionsStr = r'''
(txt, codepage is 1251, no labels, delimiter is '\t', msq, filters(
  Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
  ))
''';
    shouldPass(fileOptionsStr,'fileModifier');
  });
  
  test('tableOrFilename1', () {
  String fileOptionsStr = r'''
[..\Resources\Expressions.qvs]   (txt, codepage is 1251, no labels, delimiter is '\t', msq, filters(
  Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
  ))
''';
    shouldPass(fileOptionsStr,'tableOrFilename');
  });
  
  test('connect1', () {
    String fileOptionsStr = r'''
ODBC CONNECT TO 'Nwind;
DBQ=C:\Program Files\Access\Samples\Northwind.mdb' (UserID is sa, Pass-
word is admin)
 ''';
    shouldPass(fileOptionsStr,'connect');
  });
  
  test('sub start', () {
    shouldPass('SUB Calendar(_startDate, _endDate, _currentDate, _tableName) ','controlStatement');
  });

  test('add load', () {
    shouldPass('add load Name, Number from NewPersons.csv where not exists(Name);','load');
    shouldPass('add only load Name, Number from NewPersons.csv where not exists(Name);','load');
  });
  test('alias', () {
    shouldPass('Alias ID_N as NameID ;','alias');
    shouldPass('Alias A as Name, B as Number, C as Date;','alias');
  });
  test('binaryStatement', () {
    shouldPass('Binary customer.qvw;','binaryStatement');
    shouldPass('Binary c:\qv\customer.qvw;','binaryStatement');
  });
  test('buffer', () {
    shouldPass('buffer select * from MyTable;','load');
    shouldPass('buffer (stale after 7 days) select * from MyTable;','load');
    shouldPass('buffer (incremental) load * from MyLog.log;','load');
  });
  test('load resident where', () {
    var str = '''
    LOAD * RESIDENT AggregationByDepartmentDay
WHERE [~КлючНоменклатураХарактеристика] = 3933
	ORDER BY
		[~КлючНоменклатураХарактеристика],
		ПодразделениеСсылка,
		ПодразделениеХранения,
		Дата;''';
    shouldPass(str,'load');
  });
}
