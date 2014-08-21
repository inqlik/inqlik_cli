library simple_tests;

import 'package:qvs_parser/src/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvsGrammar();


Result _parse(String source, String production) {
  var parser = qvs[production].end();
  return parser.parse(source);
}

shouldFail(String source, String production) {
  expect(_parse(source, production).isFailure,isTrue);
}

shouldPass(String source, String production) {
  expect(_parse(source, production).isSuccess,isTrue, reason: '"$source" did not parse as "$production"' );
}

void main() {
//  var str = r'    LET vL.Ma= = tch = -1  ;';
//  //shouldPass(str,'assignment');
//  var parser = new ActionParser(qvs['assignment'].end(),(v) => [v.length,v]);
//  print(parser.parse(str).value);
//  
//  return;
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
    shouldPass('buffer (stale after 7 hours) select * from MyTable;','load');
    shouldPass('buffer (stale 7 hours) select * from MyTable;','load');
    shouldPass('buffer (stale 7) select * from MyTable;','load');
    shouldPass('buffer (incremental) load * from MyLog.log;','load');
  });
  test('load resident with where clause', () {
    var str = '''
    LOAD * RESIDENT AggregationByDepartmentDay
WHERE [~КлючНоменклатураХарактеристика] = 3933;''';
    shouldPass(str,'load');
  });
  
  test('load resident with where clause with groupBy', () {
    var str = '''
    LOAD * RESIDENT AggregationByDepartmentDay
WHERE [~КлючНоменклатураХарактеристика] = 3933
	GROUP BY
		[~КлючНоменклатураХарактеристика],
		ПодразделениеСсылка,
		ПодразделениеХранения,
		Дата;''';
    shouldPass(str,'load');
  });
  
  
  test('load resident with where clause and orderBy', () {
    var str = '''
    LOAD * RESIDENT AggregationByDepartmentDay
WHERE [~КлючНоменклатураХарактеристика] = 3933
  ORDER BY 
    [~КлючНоменклатураХарактеристика],
    ПодразделениеСсылка ASC,
    ПодразделениеХранения DESC,
    Дата;''';
    shouldPass(str,'load');
  });
  
  test('breaking case 1', () {
    var str = '''
LOAD *
,
     company, 
     itemId,
     city,
     date, 
     if(company = 'kerama' and category = 'Ламинат', price / 0.24,price) as price,
     unitId, 
     category, 
     nameorder 
FROM
C:\QlikDocs\PriceComparision\Data\Source\inventtable.txt
    (txt, utf8, embedded labels, delimiter is '\t', msq)
WHERE (company = 'agora' or itemId = '0101077031');
''';
    shouldPass(str,'load');
  });
  
  test('breaking case 2', () {
    var str = '''
InventTable1:
LOAD *
  ,If(isNull(Менеджер),'РТН не назначен',Менеджер) as Менеджер1
  ,If(isNull(НоменклатураБренд) OR НоменклатураБренд = '','Бренд неопределен',НоменклатураБренд) as НоменклатураБренд1
  ,If(Not IsNull(НоменклатураНаименованиеУровня2), НоменклатураНаименованиеУровня2,
          If(Peek('НоменклатураНаименованиеУровня1')=НоменклатураНаименованиеУровня1 and
             Peek('_НоменклатураНаименованиеУровня2')<>НоменклатураНаименованиеУровня2,
               '^^' & НоменклатураНаименованиеУровня1)) as _НоменклатураНаименованиеУровня2
,     If(Not IsNull(НоменклатураНаименованиеУровня3), НоменклатураНаименованиеУровня3,
          If(Peek('НоменклатураНаименованиеУровня2')=НоменклатураНаименованиеУровня2 and
             Peek('_НоменклатураНаименованиеУровня3')<>НоменклатураНаименованиеУровня3,
               '^^' & НоменклатураНаименованиеУровня2)) as _НоменклатураНаименованиеУровня3,
     If(Not IsNull(НоменклатураНаименованиеУровня4), НоменклатураНаименованиеУровня4,
          If(Peek('НоменклатураНаименованиеУровня3')=НоменклатураНаименованиеУровня3 and
             Peek('_НоменклатураНаименованиеУровня4')<>НоменклатураНаименованиеУровня4,
               '^^' & НоменклатураНаименованиеУровня3)) as _НоменклатураНаименованиеУровня4,  
     If(Not IsNull(НоменклатураНаименованиеУровня5), НоменклатураНаименованиеУровня5,
          If(Peek('НоменклатураНаименованиеУровня4')=НоменклатураНаименованиеУровня4 and
             Peek('_НоменклатураНаименованиеУровня5')<>НоменклатураНаименованиеУровня5,
               '^^' & НоменклатураНаименованиеУровня4)) as _НоменклатураНаименованиеУровня5,
    If(Not IsNull(НоменклатураНаименованиеУровня6), НоменклатураНаименованиеУровня6,
          If(Peek('НоменклатураНаименованиеУровня5')=НоменклатураНаименованиеУровня5 and
             Peek('_НоменклатураНаименованиеУровня6')<>НоменклатураНаименованиеУровня6,
               '^^' & НоменклатураНаименованиеУровня5)) as _НоменклатураНаименованиеУровня6
           RESIDENT InventTable
               ORDER BY
                    НоменклатураНаименованиеУровня1 DESC,
                    НоменклатураНаименованиеУровня2 DESC,
                    НоменклатураНаименованиеУровня3 DESC,
                    НоменклатураНаименованиеУровня4 DESC,
                    НоменклатураНаименованиеУровня5 DESC,
                    НоменклатураНаименованиеУровня6 DESC;
''';
    shouldPass(str,'load');
  });
  
 test('Expressions',() {
    var str = '''If(Not IsNull(НоменклатураНаименованиеУровня2), НоменклатураНаименованиеУровня2,
          If(Peek('НоменклатураНаименованиеУровня1')=НоменклатураНаименованиеУровня1 and
             Peek('_НоменклатураНаименованиеУровня2')<>НоменклатураНаименованиеУровня2,
               '^^' & НоменклатураНаименованиеУровня1))''';
    shouldPass(str,'expression');
  });
 
 test('Bundle', () {
   var str = 'Bundle info Load * from flagoecd.csv;';
   shouldPass(str,'load');
   str = 'Bundle Select * from infotable;';
   shouldPass(str,'load');
 });
 test('Comment FIELD/TABLE WITH',() {
   var str = 'Comment Field Dim1 With "This is a field comment";';
   shouldPass(str,'commentWith');
   str = 'Comment Field Dim1 With This is a field comment;';
//   shouldPass(str,'commentWith');
//   print(_parse(str,'stringOrNotColon').value);
 });
 test('Tag FIELD/TABLE WITH',() {
   var str = r'Tag Field Dim1 With "$date";';
   shouldPass(str,'commentWith');
   str = r'Tag Fields Dim1 With "$date";';
   shouldPass(str,'commentWith');
   
//   shouldPass(str,'commentWith');
//   print(_parse(str,'stringOrNotColon').value);
 });
 skip_test('HierarchyBelongsTo', () {
   var str = '''
BdrLinksTemp:
HierarchyBelongsTo(СтатьяБДР, РодительСтатьиБДР, СтатьяНаименование, AncestorId, АИ_СтатьяБДР)
LOAD РодительСтатьиБДР, 
     СтатьяБДР,
     СтатьяБДР as СтатьяНаименование,
     _АИ_БДР_ФлагКонсолидации
FROM
C:\QlikDocs\Agora_Pilot\Data\Source\АльтернативнаяИерархияБДР.xlsx
(ooxml, embedded labels, table is Лист2);''';
   shouldPass(str,'load');
 });

 solo_test('variable assignment (LET) ',() {
   var str = r'    LET vL.Match= -1  ;';
   //shouldPass(str,'assignment');
   var parser = new ActionParser(qvs['assignment'],(v) => print);
   parser.parse(str); 
 });

 
}
