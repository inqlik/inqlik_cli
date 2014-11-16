library reader_tests;

import 'package:qvs/src/qv_exp_reader.dart';
void main() {
  var reader = newReader()..readFile(r'exp_files\App.Variables.qlikview-vars');
  reader.checkSyntax();
  reader.printErrors();
}