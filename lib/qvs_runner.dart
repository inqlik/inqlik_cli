library qvs_runner;
import 'src/parser.dart';


void run(String fileName, bool forceReload, String executable) {
  parseFile(fileName, forceReload, executable);
}