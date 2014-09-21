library qvs_runner;
import 'src/qvs_reader.dart';
import 'dart:io';

QvsFileReader run(String fileName, bool justLocateQvw, bool traceResidentTables) {
  QvsFileReader reader = newReader()
      ..justLocateQvw = justLocateQvw
      ..readFile(fileName);
  for (var error in reader.errors) {
    print('------------------------------');
    print(error.commandWithError);
    print('>>>>> ' + error.errorMessage);
  }
  int exitStatus = 0;
  var parseStatusString = 'successfully';
  if (reader.errors.isNotEmpty) {
    exitStatus = 1;
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
          QvsFileReader reader = newReader()
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