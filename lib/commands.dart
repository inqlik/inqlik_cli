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
  final invocation = "inqlik qvw <subcommand> [params] pathTo\\source_file.qvw";
  QvwCommand() {
    addSubcommand(new QvwXmlCommand());
    addSubcommand(new QvwVariablesCommand());
    addSubcommand(new QvwFieldsCommand());
  }
}

abstract class InqlikCommand extends Command {
  void _outputString(String outStr) {
    if (argResults['output'] == null) {
      print(outStr);
    } else {
      var sink = new File(argResults['output']).openWrite();
      sink.write(outStr);
      sink.close();
    }
  }

  String _getXml() {
    if (argResults.rest.isEmpty) {
      usageException('Qvw file name expected');
      //throw new UsageException('Qvw file name expected', argParser.usage);
    }
    String sourceFile = argResults.rest[0];
    if (!new File(sourceFile).existsSync()) {
      usageException('Source file not found: $sourceFile');
    }
    var extractor = new meta.XmlExtractor(sourceFile);
    return extractor.extract();
  }
}

class QvwXmlCommand extends InqlikCommand {
  final name = "xml";
  final description =
      "Extract full metadata information in XML format from qvw file";
  final invocation = "inqlik qvw xml [params] pathTo\\source_file.qvw";
  QvwXmlCommand() {
    argParser.addOption('output', abbr: 'o', help: 'Output file name');
  }
  void run() {
    String xml = _getXml();
    if (argResults['output'] == null) {
      print('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      print(xml);
    } else {
      var sink = new File(argResults['output']).openWrite();
      sink.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
      sink.write(xml);
      sink.close();
    }
  }
}

class QvwVariablesCommand extends InqlikCommand {
  final name = "variables";
  final description = "Extract information about variables from qvw file";
  QvwVariablesCommand() {
    argParser.addOption('output', abbr: 'o', help: 'Output file name');
    argParser.addOption('format',
        abbr: 'f',
        help: 'Output format',
        allowed: ['names', 'csv', 'qvs'],
        allowedHelp: {
      'names': 'Simple list of variable names',
      'qvs': 'QlikView load script with commands to set variables',
      'csv': 'Table in CSV format'
    });
  }

  void run() {
    String xml = _getXml();
    var format = argResults['format'];
    if (format == null) {
      usageException('Error: mandatory parameter `format` is not set');
    }
    var variables = new meta.XmlExtractor(null).getQvwVarList(xml);
    if (format == 'names') {
      var res = variables.map((e) => e.name).join('\n');
      _outputString(res);
      return;
    }
    if (format == 'qvs') {
      var res = new meta.XmlExtractor(null).qvwVariablesToQvs(
          variables, argResults.rest.first);
      _outputString(res);
      return;
    }
    if (format == 'csv') {
      var res = new meta.XmlExtractor(null).qvwVariablesToCsv(variables);
      _outputString(res);
      return;
    }
  }
}

class QvwFieldsCommand extends InqlikCommand {
  final name = "fields";
  final description = "Extract information about fields from qvw file";
  QvwFieldsCommand() {
    argParser.addOption('output', abbr: 'o', help: 'Output file name');
    argParser.addOption('format',
        abbr: 'f',
        help: 'Output format',
        allowed: ['names', 'csv'],
        allowedHelp: {
      'names': 'Simple list of variable names',
      'csv': 'Table in CSV format'
    });
    argParser.addFlag('exclude-system',
        abbr: 's', help: 'Exclude system fields from the list');
  }

  void run() {
    String xml = _getXml();
    var format = argResults['format'];
    if (format == null) {
      usageException('Error: mandatory parameter `format` is not set');
    }
    var fields = new meta.XmlExtractor(null).getQvwFieldList(xml);
    if(argResults['exclude-system']) {
      fields.removeWhere((e) => e.isSystem);
    }
    if (format == 'names') {
      var res = fields.map((e) => e.name).join('\n');
      _outputString(res);
      return;
    }
    if (format == 'csv') {
      var res = new meta.XmlExtractor(null).qvwFieldsToCsv(fields);
      _outputString(res);
      return;
    }
  }
}

class QvdCommand extends InqlikCommand {
  final name = "qvd";
  final description = "Extract metadata information from qvd file";
  QvwFieldsCommand() {
    argParser.addOption('output', abbr: 'o', help: 'Output file name');
    argParser.addOption('format',
    abbr: 'f',
    help: 'Output format',
    allowed: ['names', 'csv'],
    allowedHelp: {
      'names': 'Simple list of variable names',
      'csv': 'Table in CSV format'
    });
    argParser.addFlag('exclude-system',
    abbr: 's', help: 'Exclude system fields from the list');
  }

  void run() {
    String xml = _getXml();
    var format = argResults['format'];
    if (format == null) {
      usageException('Error: mandatory parameter `format` is not set');
    }
    var fields = new meta.XmlExtractor(null).getQvdFieldList(xml);
    if(argResults['exclude-system']) {
      fields.removeWhere((e) => e.isSystem);
    }
    if (format == 'names') {
      var res = fields.map((e) => e.name).join('\n');
      _outputString(res);
      return;
    }
    if (format == 'csv') {
      var res = new meta.XmlExtractor(null).qvwFieldsToCsv(fields);
      _outputString(res);
      return;
    }
  }
}




class ExpCommand extends Command {
  final name = "exp";
  final description = "Utils for InQlik-Tools explression files";
  ExpCommand();
  void run() {
    if (argResults.rest.isEmpty) {
      usageException('InQlik-Tools expression file name expected');
    }
    String sourceFile = argResults.rest[0];
    var reader = exp.newReader()..readFile(sourceFile);
    reader.checkSyntax();
    reader.printStatus();
  }
}
