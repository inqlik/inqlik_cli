library qvs_runner;
import 'src/qvs_file_reader.dart';
import 'dart:io';

FileReader run(String fileName, String runCommand, String defaultInclude, [bool traceResidentTables=false]) {
  bool justLocateQvw = ['open','just_reload','qvw_extract_fields','qvw_extract_vars'].contains(runCommand);
  FileReader reader = newReader()
      ..justLocateQvw = justLocateQvw
      ..defaultInclude = defaultInclude
      ..readFile(fileName);
  for (var error in reader.errors) {
    print('------------------------------');
    print(error.commandWithError);
    print('>>>>> ' + error.errorMessage);
  }
  var parseStatusString = 'successfully';
  if (reader.errors.isNotEmpty) {
    parseStatusString = 'with ${reader.errors.length} errors/warnings';
  }
  if (!justLocateQvw) {
    print('Parse finished $parseStatusString');
    if (traceResidentTables) {
      print('Resident tables: ${reader.data.tables}');
    }      
  }
  return reader;
}

void runDirFile(String dirFileName) {
  File dirFile = new File(dirFileName);
  if (!dirFile.existsSync()) {
    print('Cannot open file $dirFileName');
    exit(2);
  }
  int errorsTotal = 0;
  int filesTotal = 0;
  int filesBroken = 0;

  List<String> directories = dirFile.readAsLinesSync();
  for (var d in directories) {
    Directory dir = new Directory(d);
    if (!dir.existsSync()) {
      print('Error - Directory not exists: $d');
      continue;
    }
    for (var file in dir.listSync(recursive: true)) {
      if (file is File) {
        if (file.path.endsWith('.qvs')) {
          FileReader reader = newReader()
              ..readFile(file.path);
          filesTotal++;
          if (reader.errors.isNotEmpty)  {
            errorsTotal += reader.errors.length;
            print('File ${file.path} has ${reader.errors.length} errors');
            filesBroken++;
          }
        }
      }
    }
  }
  print('$filesTotal files checked. $filesBroken files broken. $errorsTotal errors in total');
}