library qvs_parser;
import 'package:petitparser/petitparser.dart';
import 'dart:io';
part 'grammar.dart';



bool parseFile(String fileName, bool forceReload, String executable) {
  String input = '';
      var file = new File(fileName);
      if (file.existsSync())
      {
        if (input == '') {
          input = file.readAsStringSync(encoding: Encoding.SYSTEM);
        }  
      } else {
        print('File not found: $fileName');
        return false;
      }

  var qvs = new QvsGrammar().ref('start');
    
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
    print('Parse error File: $fileName row: $row col: $col message: $message');
    if (forceReload) {
      runQlikView(input, executable);
    }
  } else {
    print('Parsing OK');
    runQlikView(input, executable);
  }  
}

void runQlikView(String buffer, String executable) {
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
    var arguments = ['/r', '/Nodata', '/Nosecurity', fileName];
    Process.run(executable, arguments)
    .then((ProcessResult res) {
      var message = 'QlikView reload process finished. ${res.stderr}'; 
      print(message);
    })
    .catchError((Object err) {print('Error while reloading: $err');});
  }
}
