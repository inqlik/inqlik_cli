import 'package:args/args.dart';
import 'package:qvs/qvs.dart';
import 'package:qvs/src/qvs_file_reader.dart' as qvs;
import 'package:qvs/src/qv_exp_reader.dart' as exp;
import 'package:qvs/src/xml_extractor.dart' as meta;

import 'dart:io';
String input = r'''
JOIN (   [asdf]  ) 
''';
void printUsage(ArgParser ap) {
  print('-------------------');
  print('Inqlik command line interface tools');
  print(ap.usage);
  print('available commands are:');
  print('  qvs');
  print('  exp');
  print('  qvw');
  
}
void main(arguments) {
  
  var ap = new ArgParser();
  ap.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  var qvsArgs = new ArgParser();
  qvsArgs.addOption('command', allowed: ['check_and_reload', 'open','force_reload','check', 'check_directories'], abbr: 'c', defaultsTo: 'check_and_reload',
    allowedHelp: {
         'check_and_reload': 'Check script for errors and run reload task on success',
         'open': 'Open related qvw application',
         'force_reload': 'Check syntax and run reload task regardless of errors',
         'check': 'Check syntax, do not run reload task',
         'check_directories': 'Read file passed as parameter -d --directories, get list of directories to batch check syntax'}  
  );
  qvsArgs.addOption('include', abbr: 'i',defaultsTo: 'default_include.qvs');
//  ap.addFlag('show-resident-tables', negatable: false, defaultsTo: false);
  qvsArgs.addOption('directories',abbr: 'd', defaultsTo: '');
  qvsArgs.addOption('qlikview', abbr: 'q', defaultsTo: r'C:\Program Files\QlikView\qv.exe', help: "Full path to QlikView executable");
  qvsArgs.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  ap.addCommand('qvs',qvsArgs);

  var expArgs = new ArgParser();
  expArgs.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  ap.addCommand('exp',expArgs);  

  var qvwArgs = new ArgParser();
  qvwArgs.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  qvwArgs.addOption('command', allowed: ['fields', 'field_names'], abbr: 'c', defaultsTo: 'get_fields',
    allowedHelp: {
         'fields': 'Print fields metadata from qvw file',
         'field_names': 'Print field names list from qvw file'} 
  );

  qvwArgs.addOption('xmlSize', allowed: ['1', '2','3','4','5','6','7','8','9','10'], abbr: 'x', defaultsTo: '2',
    help: 'Size of buffer at the end of qvw file where to seak xml part');

  
  ap.addCommand('qvw',qvwArgs);  

  
  var args;
  try {
    args = ap.parse(arguments);
  }
  catch(e) {
    print(e);
    exit(-1);
  }
  if (args["help"] || (args.command == null)) {
    printUsage(ap);
    return;
  }
  if (args.command.name == 'qvs') {
    runQvsCommand(args.command, qvsArgs);
  }
  if (args.command.name == 'exp') {
    runExpCommand(args.command, expArgs);
  }
  if (args.command.name == 'qvw') {
    runQvwCommand(args.command, qvwArgs);
  }

  
}

void runQvsCommand(ArgResults args, ArgParser ap) {
  String message = '''
-------------------
Parser for QlikView load scripts
usage: ${ap.usage}
''';
  if (args["help"] || (args.rest.isEmpty && args['directories']=='')) {
    print(message);
    return;
  }
  if (args['command'] == 'check_directories') {
    if (args['directories']!='') {
      runDirFile(args['directories']);
      exit(0);
    } else {
      print('For command `check_directories` file with directories list should be set as parameter `directories`');
      print(message);
      exit(-1);
    }
  }
  if (args.rest.isEmpty) {
    print('ERROR:  Load script file name expected');
    print(message);
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


void runExpCommand(ArgResults args, ArgParser ap) {
  String message = '''
-------------------
Parser for Inqlik-Tools Expression files
usage: ${ap.usage}
''';
  if (args["help"] || args.rest.isEmpty || args.rest.length != 1) {
    print(message);
    return;
  }
  String sourceFile = args.rest.first;
  print(sourceFile);
  var reader = exp.newReader()..readFile(sourceFile);
  reader.checkSyntax();
  reader.printStatus();
}

void runQvwCommand(ArgResults args, ArgParser ap) {
  String message = '''
-------------------
Metadata extractor tool for Qvw files
 
usage: inqlik qvw [options] [sourceFile]
Options: 
${ap.usage}
''';
  if (args["help"] || args.rest.isEmpty || args.rest.length != 1) {
    print(message);
    return;
  }
  String sourceFile = args.rest[0];
  
  var extractor = new meta.XmlExtractor(sourceFile,'DocumentSummary');
  var res = extractor.extract();
//  print(res);
  var fields = extractor.getQvwFieldList(res);
  for (var each in fields) {
    print(each.name);
  }
  
}
