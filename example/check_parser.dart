library check_parser;
import 'package:inqlik_cli/src/parser.dart';
main() {
  var grammar = new QvsGrammar();
  var res = grammar.parse('LET asd = 1;   ');
  print(res.isFailure);
}