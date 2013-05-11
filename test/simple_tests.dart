// Copyright (c) 2013, Lukas Renggli <renggli@gmail.com>

library simple_tests;

import 'package:qvs_parser/qvs_parser.dart';
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvsGrammar();


Result _parse(String source, String production) {
  var parser = qvs[production].end();
  return parser.parse(source);
}

dynamic shouldFail(String source, String production) {
  return expect(_parse(source, production).isFailure,isTrue);
}

dynamic shouldPass(String source, String production) {
  return expect(_parse(source, production).isSuccess,isTrue);
}

void main() {

  test('testIdentifier1', () {
    return shouldPass('SimpleName', 'identifier');
  });
  test('testIdentifier2', () {
    return shouldPass('_SimpleNameWithUnderscore', 'identifier');
  });
  test('testIdentifier3', () {
    return shouldPass('@4', 'identifier');
  });
  test('testIdentifier4', () {
    return shouldPass('_КодНоменклатуры', 'identifier');
  });
  test('testIdentifier5', () {
    return shouldFail('~КодНоменклатуры', 'identifier');
  });
  test('testDropTable1',() {
    return shouldPass('DROP TABLES WeeklySales;', 'drop table');    
  });
  
  test('testDropTable2',() {
    return shouldPass('DROP TABLE WeeklySales, InventTableDepartment, WeeklyZeroSales;', 'drop table');    
  });
  test('tableOrFilename1', () {
    return shouldPass('[..\Data\Source\план по подгруппам магазинам и каналам сбыта.xls]','tableOrFilename');   
  });
  test('fieldref1', () {
    return shouldPass(' [41275]','fieldref');   
  });
  test('fileOptions1', () {
  String fileOptionsStr = r'''
    (biff, embedded labels,
 header is 1 lines, table is [Sheet1$],
filters(
Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
)
    )''';
    return shouldPass(fileOptionsStr,'fileModifier');
  });
  
  test('fileOptions2', () {
  String fileOptionsStr = r'''
(txt, codepage is 1251, no labels, delimiter is '\t', msq, filters(
  Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
  ))
''';
    return shouldPass(fileOptionsStr,'fileModifier');
  });
  
  test('tableOrFilename1', () {
  String fileOptionsStr = r'''
[..\Resources\Expressions.qvs]   (txt, codepage is 1251, no labels, delimiter is '\t', msq, filters(
  Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
  ))
''';
    return shouldPass(fileOptionsStr,'tableOrFilename');
  });
  
  test('connect1', () {
    String fileOptionsStr = r'''
ODBC CONNECT TO 'Nwind;
DBQ=C:\Program Files\Access\Samples\Northwind.mdb' (UserID is sa, Pass-
word is admin)
 ''';
    _parse(fileOptionsStr,'connect').value;
    return shouldPass(fileOptionsStr,'connect');
  });
  
  test('sub start', () {
    return shouldPass('SUB Calendar(_startDate, _endDate, _currentDate, _tableName) ','controlStatement');
  });
}
