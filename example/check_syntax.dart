library reader_tests;

import 'package:inqlik_cli/src/qv_exp_reader.dart';
void main() {
  var reader = newReader()..readFile(r'example\exp_files\App.Variables.qlikview-vars');
  reader.checkSyntax();
  print(reader.errors);
}