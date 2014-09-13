library qvs_parser;
import 'package:petitparser/petitparser.dart';
import 'dart:io';
import 'qvs_reader.dart';
import 'productions.dart' as p;
part 'grammar.dart';


class QvsParser extends QvsGrammar {
  QvsFileReader reader;
  QvsParser(this.reader): super();
  static final Set<String> tables = new Set<String>();
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
      bool isLetCommand = (list[0] as String).trim().toUpperCase() == 'LET';
      String varName = list[1];
      String varValue = list[3];
      reader.processAssignmentCommand(varName, varValue, isLetCommand);
      return list;
    });
    action(p.forNextStart, (List list) {
      reader.processAssignmentCommand(list[1], list[3], false);
      return list;
    });

    
    //    action('tableIdentifier', (v) {
////      print(v);
//      tables.add(v.value.first.value);
//    });
//    action('drop table', (v) {
////      print(v);
//      for(var each in v[3]) {
//        tables.remove(each.value);
//      }
//    });
//    action('rename table', (v) {
////      print(v);
//      tables.remove(v[2].value);
//      tables.add(v[4].value);
//    });
//    action('load', (v){
//      print(v);
//      print(' ${v[5].value}');
//    });

  }
}

void runQlikView(String buffer, String executable, String scriptName) {
  var lines = buffer.split('\n');
  var firstLine = lines[0];
  if (firstLine.startsWith('//#!')) {
    var fileName = firstLine.substring(4).trim();
    var file = new File(fileName);
    if (!file.existsSync())
    {
      print('Reload unterrupted. File not found: $fileName');
      exit(2);
    }
    file = new File(executable);
    if (!file.existsSync())
    {
      print('Reload unterrupted. QlikView executable not found: $executable');
      exit(2);
    }
    print('Reloading file $fileName');
    var arguments = ['/c',executable,'/r', '/Nodata', '/Nosecurity', '/vss=$scriptName', fileName];
    print('cmd $arguments');
    Process.run('cmd', arguments)
    .then((ProcessResult res) {
      var message = 'QlikView reload process finished. ${res.stderr}'; 
      print(message);
    })
    .catchError((Object err) {print('Error while reloading: $err');});
  }
}
