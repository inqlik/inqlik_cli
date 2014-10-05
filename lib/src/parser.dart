library qvs_parser;
import 'package:petitparser/petitparser.dart';
import 'qvs_reader.dart';
import 'productions.dart' as p;
part 'grammar.dart';


class QvsParser extends QvsGrammar {
  FileReader reader;
  QvsParser(this.reader): super();
  String _stripBrakets(String val) {
    if (val.startsWith('[')) {
      val = val.substring(1,val.length-1);  
    }
    return val;
  }
  void initialize() {
    super.initialize();
    action(p.call, (List list) {
      String subName = list[1];
      List<String> actualParams = [];
      if (list[2] != null) {
        actualParams.addAll(list[2][1][0]);
      }
      return [subName, actualParams];
    });

    action(p.assignment, (List list) {
      bool isLetCommand = list[0] == null || (list[0] as String).trim().toUpperCase() == 'LET';
      String varName = list[1];
      String varValue = list[3];
      reader.processAssignmentCommand(varName, varValue, isLetCommand);
      return list;
    });
    action(p.forNextStart, (List list) {
      reader.processAssignmentCommand(list[1], list[3], true);
      return list;
    });
    action(p.forEachStart, (List list) {
      reader.processAssignmentCommand(list[2], list[4][0], true);
      return list;
    });
    action(p.forEachFileMaskStart, (List list) {
      reader.processAssignmentCommand(list[2], list[6], true);
      return list;
    });
    action(p.dropTable, (v) {
      for (var table in v[3]) {
        reader.data.tables.remove(_stripBrakets(table));
      }
    });
    action(p.load, (v) {
//      print('LOAD STATEMENT: $v');
    });

    action(p.renameTable, (v) {
      reader.data.tables.remove(_stripBrakets(v[2]));
      reader.data.tables.add(v[4]);
    });
    action(p.tableIdentifier, (v){
      reader.data.tables.add(_stripBrakets(v[0]));
      return v;
    });
    action(p.macroFunction, (v){
//      print("macro ${v[1][0]} param ${v[1][2]}");
      return [v[1][0], v[1][2]];
    });

  }
}
