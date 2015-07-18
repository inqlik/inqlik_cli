library inqlik_command_runner;

import 'package:args/command_runner.dart';
import 'package:inqlik_cli/qvs.dart';
import 'package:inqlik_cli/src/qvs_file_reader.dart' as qvs;
import 'package:inqlik_cli/src/qv_exp_reader.dart' as exp;
import 'package:inqlik_cli/src/xml_extractor.dart' as meta;
import 'dart:io';
import 'package:inqlik_cli/qvs.dart' as qvs_runner;

CommandRunner createRunner() {
  return new CommandRunner(
      'inqlik', 'Command line interface to various InQlik utils')
    ..addCommand(new ExpCommand())
    ..addCommand(new QvwCommand())
    ..addCommand(new QvsCommand());
}

class QvsCommand extends Command {
  final name = "qvs";
  final description = "Utils for QlikView Script files";

  QvsCommand() {
    argParser.addOption('command',
        allowed: [
      'check_and_reload',
      'open',
      'force_reload',
      'just_reload',
      'check',
      'check_directories',
    ],
        abbr: 'c',
        defaultsTo: 'check_and_reload',
        allowedHelp: {
      'check_and_reload':
          'Check script for errors and run reload task on success',
      'open': 'Open related qvw application',
      'force_reload': 'Check syntax and run reload task regardless of errors',
      'check': 'Check syntax, do not run reload task',
      'just_reload': 'Just reload qvw, without qvs syntax check',
      'check_directories':
          'Read file passed as parameter -d --directories, get list of directories to batch check syntax',
    });
    argParser.addOption('include',
        abbr: 'i', defaultsTo: 'default_include.qvs');
//  ap.addFlag('show-resident-tables', negatable: false, defaultsTo: false);
    argParser.addOption('directories', abbr: 'd', defaultsTo: '');
    argParser.addOption('qlikview',
        abbr: 'q',
        defaultsTo: r'C:\Program Files\QlikView\qv.exe',
        help: "Full path to QlikView executable");
  }

  void run() {
    if (argResults['command'] == 'check_directories') {
      if (argResults['directories'] != '') {
        runDirFile(argResults['directories']);
        return;
      } else {
        throw new UsageException(
            'For command `check_directories` file with directories list should be set as parameter `directories`',
            argParser.usage);
      }
    }
    if (argResults.rest.isEmpty) {
      throw new UsageException(
          'ERROR:  Load script file name expected', argParser.usage);
    }
    qvs.FileReader reader = qvs_runner.run(
        argResults.rest[0], argResults['command'], argResults['include']);

    if (argResults['command'] == 'check') {
      return;
    }
    var cmArgs = [];
    String executable = argResults['qlikview'];
    if (reader.data.qvwFileName == null) {
      print('Cannot locate qvw file for script ${reader.data.rootFile}');
      return;
    }
    if (argResults['command'] == 'open') {
      cmArgs = ['/C', executable, reader.data.qvwFileName];
      print('Opening file ${reader.data.qvwFileName}');
    } else {
      if (argResults['command'] == 'check_and_reload') {
        if (reader.errors.isNotEmpty) {
          exit(0);
        }
      }
      cmArgs = [
        '/C',
        executable,
        '/r',
        '/Nodata',
        '/Nosecurity',
        reader.data.qvwFileName
      ];
      print('Reloading file ${reader.data.qvwFileName}');
    }
    Process.run('cmd', cmArgs).then((ProcessResult res) {
      var message = 'QlikView process finished. ${res.stderr}';
      print(message);
    }).catchError((Object err) {
      print('Error while invoking qlikview: $err');
    });
  }
}

class QvwCommand extends Command {
  final name = "qvw";
  final description = "Utils for QlikView application (qvw) file";
  QvwCommand() {
    addSubcommand(new QvwXmlCommand());
  }
}

class QvwXmlCommand extends Command {
  final name = "xml";
  final description = "Extract full metadata information in XML format";
  void run() {
    print('FULL XML');
  }
}



class QvwCommandOld extends Command {
  final name = "qvw";
  final description = "Utils for QlikView application (qvw) files";
  final invocation = "inqlik qvw [params] pathTo\\fileName.qvw";
  String get usage => super.usage +
  r'''

  --------------------------------------
  Usage sample:  To extract full xml into test.xml and simple list of field names into fieldNames.txt

 inqlik qvw --xml=test.xml --field-names=c:\output\fieldNames.txt c:\test\test.qvw
  ''';
  QvwCommandOld() {
//    argParser.addOption('command',
//        allowed: ['xml', 'fields_csv', 'field_names', 'vars_csv','var_names','vars_qvs'],
//        abbr: 'c',
//        defaultsTo: 'xml',
//        allowedHelp: {
//      'xml': 'Extract full header xml from qvw application',
//      'fields_csv': 'Extract fields info from qvw application in csv format',
//      'field_names': 'Extract simple list of field names from qvw application',
//      'vars_csv': 'Extract variables info from qvw file into csv format',
//      'vars_qvs': 'Create QVS script setting all variables from qvw application',
//      'var_names': 'Extract simple list of variable names from qvw application',
//    });
    argParser.addOption('xml',help:'Output full header xml from qvw application into XML file',defaultsTo: '');
    argParser.addOption('fields-csv',help:'Output fields info from qvw application into csv file',defaultsTo: '');
    argParser.addOption('field-names',help:'Output simple list of field names from qvw application into txt file',defaultsTo: '');
  }
  void run() {
    if (argResults.rest.isEmpty) {
      throw new UsageException('Qvw file name expected', argParser.usage);
    }
    bool used = false;
    String sourceFile = argResults.rest[0];
    var extractor = new meta.XmlExtractor(sourceFile);
    var xmlContent = extractor.extract();
    if (argResults['xml'] != '') {
      var sink = new File(argResults['xml']).openWrite();
      sink.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
      sink.write(xmlContent);
      sink.close();
      used = true;
    }
    if (argResults['field-names'] != '') {
      var sink = new File(argResults['field-names']).openWrite();
      var fields = extractor.getQvwFieldList(xmlContent);
        for (var each in fields) {
          sink.writeln(each.name);
        }
      sink.close();
      used = true;
    }
    if (argResults['fields-csv'] != '') {
      var sink = new File(argResults['fields-csv']).openWrite();
      var fields = extractor.getQvwFieldList(xmlContent);
      sink.write(extractor.qvwFieldsToCsv(fields));
      sink.close();
      used = true;
    }


//    switch (argResults['command']) {
//      case 'xml':
//        print('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
//        print(res);
//        break;
//      case 'field_names':
//        var fields = extractor.getQvwFieldList(res);
//        for (var each in fields) {
//          print(each.name);
//        }
//        break;
//      case 'var_names':
//        var vars = extractor.getQvwVarList(res);
//        for (var each in vars) {
//          print(each.name);
//        }
//        break;
//      case 'vars_qvs':
//        var vars = extractor.getQvwVarList(res);
//        for (var each in vars) {
//          print('LET ${each.name} = "${each.rawValue}";' );
//        }
//        break;

  }
}
void _writeToFile(String fileName,String content) {
  File outFile = new File(fileName);
  var sink = outFile.openWrite();
  sink.write(content);
  sink.close();
}
class QvdCommand extends Command {
  final name = "qvd";
  final description = "Utils for QVD files";
  QvdCommand() {
    argParser.addOption('command',
        allowed: ['qvw_extract_fields', 'qvw_extract_vars'],
        abbr: 'c',
        allowedHelp: {
      'qvw_extract_fields':
          'Extract field list from qvw file into *.metadata.fields.csv',
      'qvw_extract_vars':
          'Extract variables from qvw file into *.metadata.vars.csv'
    });
  }
  void run() {
    if (argResults.rest.isEmpty) {
      throw new UsageException('QVD file name expected', argParser.usage);
    }
    String sourceFile = argResults.rest[0];

    var extractor = new meta.XmlExtractor(sourceFile);
    var res = extractor.extract();
    print(res);
    var fields = extractor.getQvwFieldList(res);
    for (var each in fields) {
      print(each.name);
    }

    print('----------');
    var vars = extractor.getQvwVarList(res);
    for (var each in vars) {
      print(
          '${each.name} ${each.isReserved} ${each.isConfig} ${each.rawValue}');
    }
  }
}

class ExpCommand extends Command {
  final name = "exp";
  final description = "Utils for InQlik-Tools explression files";
  ExpCommand();
  void run() {
    if (argResults.rest.isEmpty) {
      throw new UsageException(
          'InQlik-Tools expression file name expected', argParser.usage);
    }
    String sourceFile = argResults.rest[0];
    var reader = exp.newReader()..readFile(sourceFile);
    reader.checkSyntax();
    reader.printStatus();
  }
}
