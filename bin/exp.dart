import 'package:args/args.dart';
import 'package:qvs/src/qv_exp_reader.dart';
main(args) {
  
  String sourceFile = args[0];
  var reader = newReader()..readFile(sourceFile);
  reader.checkSyntax();
  reader.printStatus();
}