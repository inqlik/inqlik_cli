library qvs_runner;
import 'src/qvs_reader.dart';


void run(String fileName) {
  QvsFileReader reader = newReader()..readFile(fileName);
  for (var error in reader.errors) {
    print(error.entry.commandWithError());
    print(error.errorMessage);
  }
  print('Finished.');
}