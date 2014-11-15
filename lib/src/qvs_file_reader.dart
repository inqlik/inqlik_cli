library qvs_file_reader;

import 'dart:io';
import 'qvs_reader.dart';
import 'package:path/path.dart' as path;
FileReader newReader() => new FileReader(new ReaderData());
class FileReader extends QvsReader{
  String defaultInclude = 'default_include.qvs';
  FileReader(ReaderData data):super(data);
  FileReader readIncludeFile(String fileName, String fileContent, QvsCommandEntry entry) {
    var result =  new FileReader(data)..skipParse = skipParse
      ..readFile(fileName,fileContent,entry);
//    print('State after $fileName');
//    data.printState();
    return result;
  }
  void readFile(String fileName, [String fileContent = null, QvsCommandEntry entry = null]) {
    List<String> lines = [];
    bool rootFileMode = false;
    if (data.rootFile == null) {
     rootFileMode = true;
     data.rootFile = path.normalize(path.absolute(path.dirname(Platform.script.toFilePath()),fileName));
     String pathToDefaulInclude = path.normalize(path.join(path.dirname(data.rootFile),defaultInclude)); 
     if (new File(pathToDefaulInclude).existsSync()) {
       readIncludeFile(pathToDefaulInclude, null, null); 
     }
      sourceFileName = data.rootFile;
    } else {
      sourceFileName = path.normalize(path.absolute(path.dirname(data.rootFile),fileName));
    }
    if (fileContent != null) {
      lines = fileContent.split('\n');
    } else {
      if (! new File(sourceFileName).existsSync()) {
        if (entry != null && entry.commandType == CommandType.MUST_INCLUDE) {
          addError(entry,'File not found: $sourceFileName');
        }  
      } else {
        try {
          lines = new File(sourceFileName).readAsLinesSync();
        } catch (exception, stacktrace) {
          print(exception);
          return; 
        }
      }
    }
    if (rootFileMode) {
      locateQvwFile(lines);
    }
    if (justLocateQvw) {
      return;
    }
    readLines(lines);
    if (rootFileMode) {
      removeSystemVariables();
    }
  }
  void locateQvwFile(List<String> lines) {
    if (lines.isEmpty) {
      return;
    }
    String baseName = path.basename(data.rootFile); 
    String testFile;
    if (lines.first.trim().startsWith('//#!')) {
      String directive = lines.first.trim().replaceFirst('//#!', '');
      directive = directive.replaceAll(';', '');
      testFile = '';
      if (directive.endsWith('.qvw')) {
        testFile = directive;
      } else {
        testFile = path.join(directive,path.basenameWithoutExtension(data.rootFile)+'.qvw');
      }
      if (path.isRelative(testFile)) {
        testFile = path.join(path.dirname(data.rootFile),testFile);
        testFile = path.normalize(testFile);
      }
    } else {
      testFile = data.rootFile.replaceFirst('.qvs','.qvw');
    }
    if (new File(testFile).existsSync()) {
      data.qvwFileName = testFile;
    }
  }
}
