library simple_tests;

import 'package:qvs/src/parser.dart';
import 'package:qvs/src/productions.dart' as p;
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
  Result res = _parse(source, production);
  String reason = '';
  expect(res.isSuccess,isTrue, reason: '"$source" did not parse as "$production". Message: ${res.message}. ${res.toPositionString()}' );
}

void main() {
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
    shouldPass('DROP TABLES WeeklySales;', 'dropTable');    
  });
  
  test('testDropTable2',() {
    shouldPass('DROP TABLE WeeklySales, InventTableDepartment, WeeklyZeroSales;', 'dropTable');    
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
  
  test('Filter options as expression', () {
  String fileOptionsStr = r'''
  filters(
      Remove(Row, RowCnd(Interval, Pos(Top, 1), Pos(Top, 1), Select(1, 0)))
      )
''';
    shouldPass(fileOptionsStr,p.expression);
  });
  test('Expression in braces', () {
  String expr = r'''
(Qvc.LineageInfo.Source = 'RESIDENT _qvctemp.*')''';
    shouldPass(expr,p.expression);
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
word is admin);
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
 });

 test('fieldrefs',() {
   var str = r'Dim1 ';
   shouldPass(str,p.fieldrefs);
   str = r'Dim1, [Dim2] ';
   shouldPass(str,p.fieldrefs);
   
 });

 test('Tag FIELD/TABLE WITH',() {
   var str = r'Tag Field Dim1 With "$date";';
   shouldPass(str,p.commentWith);
   str = r'Tag Fields Dim1 With "$date";';
   shouldPass(str,p.commentWith);
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

 test('variable assignment (LET) ',() {
   var str = r'    LET vL.Match= -1  ;';
   shouldPass(str,'assignment');
 });

 test('Test trace ',() {
   var str = r"TRACE string ABRAKADABRA;";
   shouldPass(str,p.start);
 });
 
 test('Test sub without param declaration ',() {
   var str = r"SUB dummy";
   shouldPass(str,p.start);
 });
 test('Test sub with param declaration ',() {
   var str = r"SUB dummy(p1, fieldName, table);";
   shouldPass(str,p.start);
 });
 test('Call sub with param',() {
   var str = r"call dummy(p1, fieldName, table);";
   shouldPass(str,p.start);
 });
 test('Call sub without param',() {
   var str = r"call dummy;";
   shouldPass(str,p.call);
 });
 test('Call sub without param with parens',() {
   var str = r"call dummy();";
   shouldFail(str,p.call);
 });
 test('Call sub with params parsing ',() {
   var str = r"call dummy('qwe',Dual('123123',23));";
   Result res = _parse(str,p.call);
   expect(res.value.length,4);
   expect(res.value[1],"dummy");
   expect(res.value[2].length,3);
   expect(res.value[2][1][0].length,2);
   expect(res.value[2][1][0][0],"'qwe'");
   expect(res.value[2][1][0][1],"Dual('123123',23)");
 });
 test('Sub declaration with params parsing ',() {
   var str = r"SUB dummy(param1,param2)";
   Result res = _parse(str,p.subStart);
   expect(res.value.length,3);
   print(res.value);
   expect(res.value[1][0],"dummy");
   expect(res.value[1][1][1].length,2);
   expect(res.value[1][1][1][0],'param1');
   expect(res.value[1][1][1][1],'param2');
 });

 test('Sub declaration without params parsing ',() {
   var str = r"SUB dummy";
   Result res = _parse(str,p.subStart);
   expect(res.value.length,3);
   expect(res.value[1][0],"dummy");
 });
 
 skip_test('Another SET ',() {
   var str = r"SET CD = E:;";
   shouldPass(str,p.assignment);
 });

 test('TRACE with comments on both sides ',() {
   var str = r"""
// dsdfg sdfg sdfgs df
TRACE  1; //adf asdf asdf asdf""";
   shouldPass(str,p.trace);
 });

 test('Trim input from beginning',() {
    var str = r"""
// dsdfg sdfg sdfgs df
TRACE 1;""";
    Result res = _parse(str, p.trimFromStart);
  });
 
 test('Typical load',() {
     var str = r"""
OnHandEom:
LOAD *,
  'EoM_06' as ТипПроводки  
     FROM [C:\QlikDocs\Spar\2.Transform\2.QVD\OnHandMonths\ONHAND_EOM_2014_06.QVD](QVD);
""";
     shouldPass(str,p.load);
   });
 test('Field (Expression as fieldName)',() {
     var str = r"""*, 'EoM_06' as ТипПроводки""";
     shouldPass(str,p.selectList);
   });

 test('DO WHILE',() {
     var str = r"""
DO WHILE Purchase.ProcessDate <= Num(MakeDate(2014,01))
""";
     shouldPass(str,p.start);
   });

 test('DO whithout WHILE',() {
     var str = r"""
DO
""";
     shouldPass(str,p.start);
   });
 test('LOOP WHILE',() {
     var str = r"""
LOOP WHILE Purchase.ProcessDate <= Num(MakeDate(2014,01))""";
     shouldPass(str,p.command);
   });

 test('LOOP whithout WHILE',() {
     var str = r"""
LOOP""";
     shouldPass(str,p.command);
   });

 
 test('Must include with dot in pathname and preceding comments',() {
      var str = r"""
/*as asdf asdf*/
// asdfasdfasdf
/*  asdf*/  $(must_include=C:\QlikDocs\Spar\2.Transform\3.Include\4.Sub\InQlik.qvs);""";
      shouldPass(str,p.start);
    });
 test('SQL SELECT', () {
   var str = '''
SQL SELECT 
        [PURCHID]
    ,   [INVOICEID]
    ,   [INTERNALINVOICEID]
    ,   [INVOICEDATE]
    ,   [INVOICEACCOUNT]
    ,   [ORDERACCOUNT]
    ,   [PMR_PAPERINVOICEDATE]
FROM [dbo.VENDINVOICEJOUR] WITH (NOLOCK)
WHERE DATAAREAID = 'dat';
''';
   shouldPass(str,p.load);
 });
 
 test('SLEEP',() {
      var str = r"""
SLEEP 500;
""";
      shouldPass(str,p.start);
  });
 test('Preceding load with table identifier',() {
      var str = r"""
Calendar:  
   LOAD If(_ПоследнийДеньПериода = Дата,1,0) AS _ФлагПоследнийДеньПериода;
""";
      shouldPass(str,p.load);
  });

 test('SET with trailing spaces',() {
      var str = r"""
SET vMinDate = Num(MakeDate(2013,01));
""";
      shouldPass(str,p.start);
  });

 test('Load from Excel file with dollar sign in table name',() {
      var str = r"""
LOAD 
  Лист, 
  КодМагазина
FROM
  НормативыОборачиваемости_ПривязкаСкладов.xls (biff, embedded labels, table is Лист1$);
""";
      shouldPass(str,p.start);
  });

 test('Connect statement',() {
       var str = r"""
CONNECT32 TO [Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\QlikDocs\Spar\2.Transform\8.Import\НормативыОборачиваемости.xls;Extended Properties="Excel 8.0"];
""";
       shouldPass(str,p.start);
   });

 test('Start ForNext without semicolon',() {
       var str = r"""
for a=1 to 9
""";
       shouldPass(str,p.start);
   });

 test('Start ForNext with semicolon',() {
       var str = r"""
for a=1 to 9;
""";
       shouldPass(str,p.start);
   });

 test('Start ForNext with Step clause and semicolon',() {
       var str = r"""
for a=1 to 9 Step 2;
""";
       shouldPass(str,p.start);
   });
 
 skip_test('SELECT with composite table name',() {
       var str = r"""
 SQL SELECT 
         [PURCHID]
     ,   [INVOICEID]
     ,   [INTERNALINVOICEID]
     ,   [INVOICEDATE]
     ,   [INVOICEACCOUNT]
     ,   [ORDERACCOUNT]
     ,   [PMR_PAPERINVOICEDATE]
 FROM [RETAIL].[dbo].[VENDINVOICEJOUR] WITH (NOLOCK)
 WHERE DATAAREAID = 'dat' ; 
""";
       shouldPass(str,p.start);
   });
 
 test('FOR EACH with list of values',() {
       var str = r"""
 for each a in 1,3,7,'xyz'
 """;
       shouldPass(str,p.start);
   });

 test('FOR EACH with filemask',() {
       var str = r"""
 for each File in filelist (Root&' \*.' &Ext)
 """;
       shouldPass(str,p.start);
   });
 
 test('EXECUTE',() {
       var str = r"""
execute cmd.exe /C move /y file.xls backup\ ; """;
       shouldPass(str,p.start);
   });
 
test('FIRST n',() {
       var str = r"""
DataTemp:
FIRST 1  
LOAD field1
  RESIDENT table2;
""";
       shouldPass(str,p.start);
   });

test('SUB declaration from Qvc',() {
       var str = r"""
SUB Qvc.AsOfTable (_dateField)
""";
       shouldPass(str,p.subStart);
   });
test('REM comments',() {
       var str = r"""
TRACE 1;
REM trace $(asdasdas);
TRACE 2;
""";
       shouldPass(str,p.start);
   });

test('SET dot',() {
       var str = r"""
SET Qvc.Loader.v.ConnectionDir=.;""";
       shouldPass(str,p.start);
   });

test('SET string with semicolon',() {
       var str = r"""
SET var1=';' & ';';
""";
       shouldPass(str,p.setAssignment);
   });
test('MacroFunction',() {
       var str = r"""
$(_Qvc.DefaultIfEmpty('', 'TEST'))""";
       shouldPass(str,p.macroFunction);
   });
test('MacroFunction with empty parameter',() {
       var str = r"""
$(_Qvc.DefaultIfEmpty(, 'TEST'))""";
       shouldPass(str,p.macroFunction);
   });

test('LET assignment without let',() {
       var str = r"""
LET _deltaTransEmtpy = -1;""";
       shouldPass(str,p.assignment);
   });

test('SIMPLE LET assignment',() {
       var str = r"""
LET _deltaTransEmtpy =  Dual(1);""";
       shouldPass(str,p.letAssignment);
   });

test('LET assignment without non-valid expression',() {
       var str = r"""
LET _deltaTransEmtpy = -1 x;""";
       shouldFail(str,p.assignment);
   });


test('STORE TABLE with WHERE clause',() {
       var str = r"""
STORE PlanData INTO ../Data/QVDs/PlanData/PlanData.QVD(QVD)
Where IsNull(_КодОтделМаркетинг) = 0; 
""";
       shouldPass(str,p.start);
   });
test('SqlTables statement',() {
       var str = r"""
ExcelSheets:
SQLtables; 
""";
       shouldPass(str,p.start);
   });

test('Must include without semicolon',() {
       var str = r"""
$(Include=..\qvc_runtime\qvc.qvs)
BigTable:
LOAD 1 as X AutoGenerate 2000;
""";
       shouldPass(str,p.start);
   });

test('EXIT SCRIPT WHEN A=1;',() {
       var str = r"""
EXIT SCRIPT WHEN A=1;
""";
       shouldPass(str,p.start);
   });
test('unless A=1 load * from myfile.csv;',() {
       var str = r"""
unless A=1 load * from myfile.csv;
""";
       shouldPass(str,p.start);
   });

test('Directory;',() {
       var str = r"""
Directory;
""";
       shouldPass(str,p.start);
   });

test('TableIdentifier with dot;',() {
       var str = r"""
Directory;
""";
       shouldPass(str,p.start);
   });

test('Preceding load whith where clause',() {
       var str = r"""
Qvc.LineageInfo:
LOAD 
  *
WHERE (Qvc.LineageInfo.Source = 'RESIDENT _qvctemp.*')
// WHERE NOT mixmatch(Qvc.LineageInfo.Source, DocumentPath())    // Ignore the Self-references
//  AND NOT Qvc.LineageInfo.Source = 'RESIDENT _qvctemp.*'
; 
""";
       shouldPass(str,p.start);
   });

skip_test('Load connection from text file',() {
       var str = r"""
  _qvctemp.Conn_temp:
  LOAD @1:2 as _qvctemp.ConnectString
  FROM [DbExtract\_qvctemp.den.connectionFilename_ASSIGNED_VALUE]
  (fix, codepage is 1252);
""";
       shouldPass(str,p.start);
   });

test('Load connection from text file',() {
       var str = r"""
[_LinkTableTemp_ASSIGNED_VALUE]:
NOCONCATENATE LOAD DISTINCT     
  Product, Color, Size,
  AutoNumberHash128(Product, Color, Size) as %LinkTable_Key
RESIDENT Order;
""";
       shouldPass(str,p.start);
   });

test('Switch statement',() {
       var str = r'''
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
       shouldPass(str,p.start);
   });


}
