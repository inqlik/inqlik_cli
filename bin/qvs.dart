//import 'package:petitparser/petitparser.dart';
import 'package:args/args.dart';
import 'package:qvs/qvs_runner.dart';
import 'package:qvs/src/file_reader.dart' as qvs;
import 'dart:io';
String input = r'''
JOIN (   [asdf]  ) 
''';
void printUsage(ArgParser ap) {
  print('-------------------');
  print('Parser for QlikView load scripts');
  print(ap.usage);
  print('Usage example:');
  print(r'c:\qvs\dart.exe c:\qvs\qvs.snapshot -c check -i initial_include.qvs c:\my_project\scripts\LoadData.qvs');
}
void main(arguments) {
  var ap = new ArgParser();
  ap.addOption('command', allowed: ['check_and_reload', 'open','force_reload','check', 'check_directories'], abbr: 'c', defaultsTo: 'check_and_reload',
    allowedHelp: {
         'check_and_reload': 'Check script for errors and run reload task on success',
         'open': 'Open related qvw application',
         'force_reload': 'Check syntax and run reload task regardless of errors',
         'check': 'Check syntax, do not run reload task',
         'check_directories': 'Read file passed as parameter -d --directories, get list of directories to batch check syntax'}  
  );
  ap.addOption('include', abbr: 'i',defaultsTo: 'default_include.qvs');
//  ap.addFlag('show-resident-tables', negatable: false, defaultsTo: false);
  ap.addOption('directories',abbr: 'd', defaultsTo: '');
  ap.addOption('qlikview', abbr: 'q', defaultsTo: r'C:\Program Files\QlikView\qv.exe', help: "Full path to QlikView executable");
  ap.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  var args;
  try {
    args = ap.parse(arguments);
  }
  catch(e) {
    print(e);
    exit(-1);
  }
  if (args["help"] || (args.rest.isEmpty && args['directories']=='')) {
    printUsage(ap);
    return;
  }
  if (args['command'] == 'check_directories') {
    if (args['directories']!='') {
      runDirFile(args['directories']);
      exit(0);
    } else {
      print('For command `check_directories` file with directories list should be set as parameter `directories`');
      printUsage(ap);
      exit(-1);
    }
  }
  if (args.rest.isEmpty) {
    print('ERROR:  Load script file name expected');
    printUsage(ap);
    exit(-1);
  }
  qvs.FileReader reader = run(args.rest[0], args['command']=='open', args['include']);
  if (args['command']=='check') {
    exit(0);
  }
  var cmArgs = [];
  String executable = args['qlikview'];
  if (reader.data.qvwFileName == null) {
    print('Cannot locate qvw file for script ${reader.data.rootFile}');
    exit(0);
  }
  if (args['command']=='open') {
    cmArgs = ['/C', executable, reader.data.qvwFileName];
    print('Opening file ${reader.data.qvwFileName}');
  } else {
    if (args['command']=='check_and_reload') {
      if (reader.errors.isNotEmpty) {
        exit(reader.errors.length);
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

