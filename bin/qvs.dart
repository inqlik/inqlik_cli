//import 'package:petitparser/petitparser.dart';
import 'package:args/args.dart';
import 'package:qvs/qvs_runner.dart';
import 'package:qvs/src/qvs_reader.dart';
import 'dart:io';
String input = r'''
JOIN (   [asdf]  ) 
''';
void main(arguments) {
  var ap = new ArgParser();
  ap.addOption('command', allowed: ['check_and_reload', 'open','force_reload'], abbr: 'c', defaultsTo: 'check_and_reload');
  ap.addFlag('show-resident-tables', negatable: false, defaultsTo: false);
  ap.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  ap.addOption('qlikview', abbr: 'q', defaultsTo: r'C:\Program Files\QlikView\qv.exe', help: "Full path to QlikView executable");

  var args = ap.parse(arguments);
  if (args["help"] || args.rest.isEmpty) {
    print('Usage: dart qvs.(dart|snapshot) [options] fileToParse');
    print('options are:\n');
    print(ap.getUsage());
    print('\nExamples:\n');
    print(r'dart qvs.dart.snapshot --qlikView="c:\QlikView\qv.exe" --command=  inventory.qvs');
    return;
  }
  QvsFileReader reader = run(args.rest[0], args['command']=='open', args['show-resident-tables']);
//  reader.data.variables.forEach((key,value) {
//    print('$key = $value');
//  });
//  reader.data.subMap.values.forEach((value) {
//    print('$value');
//  });

  var cmArgs = [];
  String executable = args['qlikview'];
  if (reader.data.qvwFileName == null) {
    print('Cannot locate qvw file for script ${reader.data.rootFile}');
    exit(2);
  }
  if (args['command']=='open') {
    cmArgs = ['/C', executable, reader.data.qvwFileName];
    print('Opening file ${reader.data.qvwFileName}');
  } else {
    if (args['command']=='check_and_reload') {
      if (reader.errors.isNotEmpty) {
        exit(1);
      }
    }
    cmArgs = ['/C', executable, '/r', '/Nodata', '/Nosecurity',reader.data.qvwFileName];
    print('Reloading file ${reader.data.qvwFileName}');
  }
  Process.run('cmd', cmArgs)
  .then((ProcessResult res) {
    var message = 'QlikView process finished. ${res.stderr}'; 
    print(message);
  })
  .catchError((Object err) {print('Error while invoking qlikview: $err');});
}

