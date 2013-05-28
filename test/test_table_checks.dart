library simple_tests;

import 'package:qvs_parser/src/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

const input1 = r'''
Table1:
LOAD A FROM B;
Table2:
Noconcatenate
LOAD A FROM B;
DROP TABLE Table1;
RENAME TABLE Table2 TO Table3;
''';
main () {
  var qvs = new QvsParser();
  qvs.parse(input1);
  print(QvsParser.tables);
}