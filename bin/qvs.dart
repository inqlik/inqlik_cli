//import 'package:petitparser/petitparser.dart';
import 'dart:io';
import 'package:args/args.dart';
import 'package:qvs_parser/qvs_runner.dart';
String input = r'''
JOIN (   [asdf]  ) 
''';
void main() {
  var ap = new ArgParser();
  ap.addFlag('forceReload', abbr: 'f', help: 'Reload document even if parse was unsuccessful', defaultsTo: false, negatable: false);
  ap.addFlag('verbose', abbr: 'v', negatable: false, defaultsTo: false);
  ap.addFlag('help',abbr: 'h', negatable: false, defaultsTo: false);
  ap.addOption('qlikview', abbr: 'q', defaultsTo: r'C:\Program Files\QlikView\qv.exe', help: "Full path to QlikView executable");

  var args = ap.parse(new Options().arguments);
  if (args["help"] || args.rest.isEmpty) {
    print('Usage: dart qvs.(dart|snapshot) [optionss] [fileToParse]');
    print('options are:\n');
    print(ap.getUsage());
    print('\nExamples:\n');
    print(r'dart qvs.snapshot --qlikView="c:\QlikView\qv.exe" --forceReload inventory.qvs');
    print('or');
    print(r'c:\dart\dart-sdk\bin\dart.exe -f qvs.dart loadInventory.qvs');
    return;
  }
  
  run(args.rest[0], args['forceReload'], args['qlikview']);
}

