library qvs_reader;

import 'dart:io';
import 'package:path/path.dart' as path;

class QvsCommandEntry {
  String sourceFileName;
  int sourceLineNum;
  int internalLineNum;
  String sourceText;
  String expandedText;
  QvsCommandType commandType;
  //QvsCommandEntry(this.sourceFileName,this.sourceLineNum, this.internalLineNum, this.sourceText, this.expandedText);
  String toString() => 'QvsCommandEntry($sourceFileName,sourceLineNum=$sourceLineNum, internalLineNum=$internalLineNum,$sourceText)'; 
}
class QvsErrorDescriptor {
  final QvsCommandEntry entry;
  final String errorMessage;
  QvsErrorDescriptor(this.entry,this.errorMessage); 
}
class QvsReaderData {
  int internalLineNum=0;
  final List<QvsCommandEntry> entries = new List<QvsCommandEntry>();
  final Map subMap = {};
  String rootFile;
  final List<QvsErrorDescriptor> errors = new List<QvsErrorDescriptor>();
}
class QvsLineType {
  final int _val;
  const QvsLineType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsLineType._internal(1);
  static const END_OF_COMMAND = const QvsLineType._internal(2);
  static const SIMPLE_LINE = const QvsLineType._internal(3);
}

class QvsCommandType {
  final int _val;
  const QvsCommandType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsCommandType._internal(1);
  static const MUST_INCLUDE = const QvsCommandType._internal(2);
  static const INCLUDE = const QvsCommandType._internal(3);
  static const BASE_COMMAND = const QvsCommandType._internal(4);
}


QvsFileReader newReader() => new QvsFileReader(new QvsReaderData()); 
class QvsFileReader {
  static final commandTerminationPattern = new RegExp(r'^.*;\s*$');
  static final mustIncludePattern = new RegExp(r'^\s*\$\(must_include=(.*)\)\s*;\s*$'); 
  static final controlStructurePatterns = [
    new RegExp(r'^\s*IF.*THEN\s*$',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSEIF.*THEN\s*$',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSE\s*$',caseSensitive: false),                                     
    new RegExp(r'^\s*END\s?IF\s*$',caseSensitive: false)
  ];
  String sourceFileName;
  final QvsReaderData data;
  QvsFileReader(this.data); 
  List<QvsCommandEntry> get entries => data.entries; 
  String toString() => 'QvsReader(${data.entries})';
  bool get hasErrors => data.errors.isNotEmpty;
  QvsFileReader createNestedReader() => new QvsFileReader(data);
  
  void readFile(String fileName, [String fileContent = null, QvsCommandEntry entry = null]) {
    List<String> lines = [];
    if (data.rootFile == null) {
     data.rootFile = path.absolute(path.dirname(Platform.script.toFilePath()),fileName);
     sourceFileName = data.rootFile;
    } else {
      sourceFileName = path.absolute(path.dirname(data.rootFile),fileName);
    }
      
    if (fileContent != null) {
      lines = fileContent.split('\n');
    } else {
      if (! new File(sourceFileName).existsSync()) {
        if (entry != null && entry.commandType == QvsCommandType.MUST_INCLUDE) {
          data.errors.add(new QvsErrorDescriptor(null,'File not found: $sourceFileName'));
        }  
      } else {
        lines = new File(sourceFileName).readAsLinesSync();
      }
    }
    readLines(lines);
  }
  
  void readLines(List<String> lines) {
    int lineCounter = 0;
    int sourceLineNum = 1;
    String command = '';
    for (var line in lines) {
      command = line + command;
      lineCounter++;
      QvsLineType lineType = testLineType(line);
      if (lineType != QvsLineType.SIMPLE_LINE) {
        data.internalLineNum++;
        var entry = new QvsCommandEntry()
        ..sourceFileName = sourceFileName
        ..expandedText =  command
        ..sourceLineNum = sourceLineNum
        ..internalLineNum = data.internalLineNum
        ..sourceText = command;
        addCommand(entry);
        sourceLineNum = lineCounter + 1;
        command = '';
      }
    }
  }
  void addCommand(QvsCommandEntry entry) {
    data.entries.add(entry);
    var m = mustIncludePattern.firstMatch(entry.expandedText);
    if (m != null) {
      entry.commandType = QvsCommandType.MUST_INCLUDE;
      createNestedReader().readFile(m.group(1),null,entry);
    }      
  }
  
  QvsLineType testLineType(line) {
    if (commandTerminationPattern.hasMatch(line)) {
      return QvsLineType.END_OF_COMMAND;
    }
    if (controlStructurePatterns.any((p) => p.hasMatch(line))) {
      return QvsLineType.CONTROL_STRUCTURE;
    }
    return QvsLineType.SIMPLE_LINE;
  }
  
}