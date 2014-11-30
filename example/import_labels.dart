library reader_tests;

import 'package:inqlik_cli/src/qv_exp_reader.dart';
void main() {
  var reader = newReader()..readFile(r'exp_files\App.Variables.qlikview-vars');
//  reader.saveAsCsv(r'exp_files\App.Variables.For_Edit.csv');
//  var file = new File(r'exp_files\Updated.test.qlikview-vars');
  reader.importLabels(r'exp_files\App.Variables.For_Edit.csv', r'exp_files\App.Variables.Updated.qlikview-vars');
//  var file = new File(r'exp_files\Updated.test.qlikview-vars');
//  file.writeAsStringSync(reader.printOut());
}
