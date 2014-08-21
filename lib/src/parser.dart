library qvs_parser;
import 'package:petitparser/petitparser.dart';
import 'dart:io';
part 'grammar.dart';

class QvsParser extends QvsGrammar {
  static final Set<String> tables = new Set<String>();
  void initialize() {
    super.initialize();
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

bool parseFile(String fileName, bool forceReload, String executable) {
  String input = '';
      var file = new File(fileName);
      if (file.existsSync())
      {
        if (input == '') {
          input = file.readAsStringSync(encoding: const SystemEncoding());
        }  
      } else {
        print('File not found: $fileName');
        return false;
      }

  var qvs = new QvsParser().ref('start');
    
  var id1 = qvs.parse(input);

  if (id1.isFailure) {
    var rowAndCol = Token.lineAndColumnOf(input, id1.position);
    String subInput = input.substring(id1.position); 
    int maxPosition = -1;
    String message;
    int deltaRow = 0;
    int col = rowAndCol[1];
    int row;
    for (Parser p in new QvsGrammar().ref('command').children) {
      Result id2 = p.parse(subInput);
      if (maxPosition < id2.position) {
        maxPosition = id2.position;
        var delta = Token.lineAndColumnOf(subInput, id2.position);
        deltaRow = delta[0];
        col = delta[1];
        message = id2.message;
      }
    }
    row = rowAndCol[0]+ deltaRow - 1;
    print('Parse error. File: $fileName row: $row col: $col message: $message');
    if (forceReload) {
      runQlikView(input, executable, fileName);
    }
  } else {
    print('Parsing OK');
    //print('Tables in memory: ${QvsParser.tables}');
    runQlikView(input, executable, fileName);
  }
  return true;
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
