library qvs_runner;
import 'src/qvs_reader.dart';


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