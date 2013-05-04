import 'package:petitparser/petitparser.dart';
import 'dart:io';
import 'qvs_grammar.dart';
String input = r'''
JOIN (   [asdf]  ) 
''';
void runQlikView(String buffer) {
  var lines = buffer.split('\n');
  var firstLine = lines[0];
  if (firstLine.startsWith('//!#')) {
    var fileName = firstLine.substring(4);
    var file = new File(fileName);
    if (!file.existsSync())
    {
      print('File not found: $fileName');
//      exit(2);
    }
    var arguments = ['/r', '/Nodata',fileName];
    Process.run("C:\\Program Files\\QlikView\\qv.exe", arguments)
    .then((ProcessResult res) {
      var message = 'QlikView process finished. ${res.stderr}'; 
      print(message);
    });
  }
}
void main() {
  input = '';
  var options = new Options();
  for (var option in options.arguments) {
    if (option.startsWith('-')) {
      if (option == '-?') {
        print('${options.executable} qvs.dart [file]');
        exit(0);
      } else {
        print('Unknown option: $option');
        exit(1);
      }
    } else {
      var file = new File(option);
      if (file.existsSync())
      {
        if (input == '') {
          input = file.readAsStringSync(encoding: Encoding.SYSTEM);
        }  
      } else {
        print('File not found: $option');
        exit(2);
      }
    }
  }
  Parser qvs = new QvsGrammar().ref('start');
    
  Result id1 = qvs.parse(input);

  if (id1.isFailure) {
    var rowAndCol = Token.lineAndColumnOf(input, id1.position);
    String subInput = input.substring(id1.position); 
    int maxPosition = -1;
    String message;
    int deltaRow;
    int col;
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
    print('Parse error on row:$row col: $col.  $message');
    
  } else {
    print('Parsing OK');
    runQlikView(input);
  }  
}
