library qvs_reader;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:petitparser/petitparser.dart';
import 'parser.dart';
import 'productions.dart';

QvsFileReader newReader() => new QvsFileReader(new QvsReaderData());
class QvsCommandEntry {
  String sourceFileName;
  int sourceLineNum;
  int internalLineNum;
  String sourceText;
  String expandedText;
  QvsCommandType commandType;
  bool parsed = false;
  bool hasError = false;
  //QvsCommandEntry(this.sourceFileName,this.sourceLineNum, this.internalLineNum, this.sourceText, this.expandedText);
  String toString() => 'QvsCommandEntry($sourceFileName,sourceLineNum=$sourceLineNum, internalLineNum=$internalLineNum,$sourceText)'; 
}
class QvsErrorDescriptor {
  final QvsCommandEntry entry;
  final String errorMessage;
  QvsErrorDescriptor(this.entry,this.errorMessage);
  String toString() => 'QvsErrorDescriptor(${this.errorMessage})';
}
class QvsReaderData {
  int internalLineNum=0;
  final List<QvsCommandEntry> entries = [];
  final Map<String, int> subMap = {};
  String rootFile;
  final List<QvsErrorDescriptor> errors = [];
  final Map<String, String> variables = {};
  String inSubDeclaration = '';
}
class QvsLineType {
  final int _val;
  const QvsLineType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsLineType._internal(1);
  static const END_OF_COMMAND = const QvsLineType._internal(2);
  static const SIMPLE_LINE = const QvsLineType._internal(3);
  static const COMMENT_LINE = const QvsLineType._internal(4);
}

class QvsCommandType {
  final int _val;
  const QvsCommandType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsCommandType._internal(1);
  static const MUST_INCLUDE = const QvsCommandType._internal(2);
  static const INCLUDE = const QvsCommandType._internal(3);
  static const BASE_COMMAND = const QvsCommandType._internal(4);
  static const SUB_DECLARATION = const QvsCommandType._internal(5);
  static const SUB_DECLARATION_END = const QvsCommandType._internal(6);
  static const COMMENT_LINE = const QvsCommandType._internal(7);
}

 
class QvsFileReader {
  static final grammar = new QvsGrammar();
  static final commandTerminationPattern = new RegExp(r'^.*;\s*$');
  static final mustIncludePattern = new RegExp(r'^\s*\$\(must_include=(.*)\)\s*;\s*$'); 
  static final includePattern = new RegExp(r'^\s*\$\(include=(.*)\)\s*;\s*$'); 
  static final variableSetPattern = new RegExp(r'^\s*(LET|SET)\s+(\w[A-Za-z.0-9]*)\s*=',caseSensitive: false); 
  static final startSubroutinePattern = new RegExp(r'^\s*SUB\s+(\w[A-Za-z.0-9_]+)',caseSensitive: false);
  static final endSubroutinePattern = new RegExp(r'^\s*END\s+SUB\s*;?\s*$',caseSensitive: false);
  static final variablePattern = new RegExp(r'\$\((\w[A-Za-z.0-9]*)\)');
  static final singleLineComment = new RegExp(r'^\s*//');
  static final multiLineCommentStart = new RegExp(r'^\s*/[*]');
  static final multiLineCommentEnd = new RegExp(r'[*]/\s*$');
  static final callSubroutinePattern = new RegExp(r'^\s*CALL\s+(\w[A-Za-z.0-9]+)',caseSensitive: false); 
  static final controlStructurePatterns = [
    new RegExp(r'^\s*IF\s.*THEN\s*',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSEIF\s.*THEN\s*',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSE\s*',caseSensitive: false),                                     
    new RegExp(r'^\s*FOR\s',caseSensitive: false),                                     
    new RegExp(r'^\s*EXIT\s',caseSensitive: false),                                     
    new RegExp(r'^\s*DO\s+(WHILE|UNTIL)',caseSensitive: false),                                     
    new RegExp(r'^\s*LOOP\s+(WHILE|UNTIL)',caseSensitive: false),                                     
    new RegExp(r'^\s*NEXT',caseSensitive: false),                                     
    new RegExp(r'^\s*END\s?IF\s*',caseSensitive: false),
    new RegExp(r'^\s*END\s?SUB\s*',caseSensitive: false),
    startSubroutinePattern,
    endSubroutinePattern,
    callSubroutinePattern
    ];
  String sourceFileName;
  bool skipParse = false;
  final QvsReaderData data;
  QvsFileReader(this.data); 
  List<QvsCommandEntry> get entries => data.entries; 
  Map<String, int> get subMap => data.subMap; 
  List<QvsErrorDescriptor> get errors => data.errors; 
  String toString() => 'QvsReader(${data.entries})';
  bool get hasErrors => data.errors.isNotEmpty;
  void addError(QvsCommandEntry entry, String message,[int row, int col]) {
    if (row == null) {
      row = entry.sourceLineNum;
    }
    if (col == null) {
      col = 1;
    }
    var locMessage = 'Parse error. File: "${entry.sourceFileName}", line: $row col: $col message: $message';
    data.errors.add(new QvsErrorDescriptor(entry, locMessage));  
  } 
  QvsFileReader createNestedReader() => new QvsFileReader(data)..skipParse = skipParse;
  
  void readFile(String fileName, [String fileContent = null, QvsCommandEntry entry = null]) {
    List<String> lines = [];
    if (data.rootFile == null) {
     data.rootFile = path.absolute(path.dirname(Platform.script.toFilePath()),fileName);
     String pathToDefaulInclude = path.join(path.dirname(data.rootFile),'default_include.qvs');  
     if (new File(pathToDefaulInclude).existsSync()) {
       createNestedReader().readFile(pathToDefaulInclude); 
     }
     sourceFileName = data.rootFile;
    } else {
      sourceFileName = path.absolute(path.dirname(data.rootFile),fileName);
    }
    if (fileContent != null) {
      lines = fileContent.split('\n');
    } else {
      if (! new File(sourceFileName).existsSync()) {
        if (entry != null && entry.commandType == QvsCommandType.MUST_INCLUDE) {
          addError(entry,'File not found: $sourceFileName');
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
    List<String> commandLines = [];
    for (var line in lines) {
      commandLines.add(line);
      lineCounter++;
      QvsLineType lineType = testLineType(line);
      if (lineType != QvsLineType.SIMPLE_LINE) {
        data.internalLineNum++;
        command = commandLines.join('\n');
        var entry = new QvsCommandEntry()
        ..sourceFileName = sourceFileName
        ..sourceLineNum = sourceLineNum
        ..internalLineNum = data.internalLineNum
        ..sourceText = command;
        if (lineType == QvsLineType.COMMENT_LINE) {
          entry.commandType = QvsCommandType.COMMENT_LINE;
        }
        addCommand(entry);
        if (sourceLineNum == 40) {
          int debug = 1;
        }
        sourceLineNum = lineCounter + 1;
        command = '';
        commandLines = [];
      }
    }
    if (data.inSubDeclaration != '') {
      addError(data.entries.last,'SUB ${data.inSubDeclaration} has not been closed propery');
    }
  }

  void expandCommand(QvsCommandEntry entry, Map<String, String> params) {
    entry.expandedText = entry.sourceText;
    var m = variablePattern.firstMatch(entry.expandedText);
    while (m != null) {
      var varName = m.group(1);
      var varValue = '';
      if (params.containsKey(varName)) {
        varValue = params[varName];
      } else if (data.variables.containsKey(varName)) {
        varValue = data.variables[varName];
      } else {
        addError(entry,'Variable $varName not defined');
      }
      entry.expandedText = entry.expandedText.replaceAll('\$($varName)',varValue);
      m = variablePattern.firstMatch(entry.expandedText);
    }
  }
  void processSetVariableCommand(QvsCommandEntry entry) {
    var m = variableSetPattern.firstMatch(entry.expandedText);
    if (m == null) {
      return;
    }
    Result r = grammar[assignment].end().parse(entry.expandedText);
    if (r.isFailure) {
      return;
    }
    String varName = r.value[1];
    String varValue = r.value[3];
    if (varValue == null) { 
      varValue = '';
    } else {
      varValue = varValue.trim();
    }
    if (varValue.startsWith("'") && varValue.endsWith("'")) {
      varValue = varValue.replaceAll("'",'');
    }
    data.variables[varName] = varValue;
  }
  void processEntry(QvsCommandEntry entry,[Map<String, String> params = const {}]) {
    expandCommand(entry,params);
    parseCommand(entry);  
    processSetVariableCommand(entry);
    var m = mustIncludePattern.firstMatch(entry.expandedText);
    if (m != null) {
      entry.commandType = QvsCommandType.MUST_INCLUDE;
      createNestedReader().readFile(m.group(1),null,entry);
    }
    if (m == null) {
      m = mustIncludePattern.firstMatch(entry.expandedText);
      if (m != null) {
        entry.commandType = QvsCommandType.INCLUDE;
        createNestedReader().readFile(m.group(1),null,entry);
      }
    }
    if (m == null) {
      m = callSubroutinePattern.firstMatch(entry.sourceText);
      if (m != null) {
        walkIntoSubroutine(entry);
      }
    }
  }
  void walkIntoSubroutine(QvsCommandEntry entry) {
    Result r = grammar[call].end().parse(entry.expandedText);
    String subName = r.value[1];
    if (!subMap.containsKey(subName)) {
      addError(entry,'Call of undefined subroutine [$subName]');
      return;
    }
    List<String> actualParams = [];
    if (r.value[2] != null) {
      actualParams.addAll(r.value[2][1][0]);
    }
    int idx = subMap[subName];
    QvsCommandEntry currentEntry = entries[idx];
    r = grammar[subStart].end().parse(currentEntry.sourceText);
    List<String> formalParams = [];
    if (r.value[1] is !String) {
      formalParams.addAll(r.value[1][2]);
    }
    Map<String,String> params = {};
    
    for (int paramIdx = 0; paramIdx<formalParams.length;paramIdx++) {
      String paramValue;
      if (paramIdx<actualParams.length) {
        paramValue = actualParams[paramIdx];
        if (paramValue.startsWith("'") && paramValue.endsWith("'")) {
          paramValue = paramValue.replaceAll("'",'');
        }
      }
      params[formalParams[paramIdx]] = paramValue;
    }
    idx++;
    currentEntry = entries[idx];
    while (currentEntry.commandType != QvsCommandType.SUB_DECLARATION_END) {
      processEntry(currentEntry,params);
      idx++;
      if (idx == entries.length) {
        throw new Exception('Walked past of list boundary in walkIntoSubroutine');
      }
      currentEntry = entries[idx];
    }
  }
  void addCommand(QvsCommandEntry entry) {
    data.entries.add(entry);
    if (entry.commandType == QvsCommandType.COMMENT_LINE) {
      return;
    }
    if (data.inSubDeclaration == '') {
      processEntry(entry);
    }
    var m = startSubroutinePattern.firstMatch(entry.sourceText);
    if (m != null) {
      entry.commandType = QvsCommandType.SUB_DECLARATION;
      String debug = m.group(1).trim();
      subMap[m.group(1)] = entry.internalLineNum -1;
      data.inSubDeclaration = m.group(1);
    }
    if (m == null) {
      m = endSubroutinePattern.firstMatch(entry.sourceText);
      if (m != null) {
        entry.commandType = QvsCommandType.SUB_DECLARATION_END;
        data.inSubDeclaration = '';
      }
    }
  }
  void parseCommand(QvsCommandEntry entry) {
    Result res = grammar.ref(command).end().parse(entry.expandedText);
    entry.parsed = true;
    if (res.isFailure) {
      int maxPosition = -1;
      int row;
      int col;
      var rowAndCol;
      String message;
      for (Parser p in new QvsGrammar().ref(command).children) {
        res = p.end().parse(entry.expandedText);
        if (maxPosition < res.position) {
          maxPosition = res.position;
          rowAndCol = Token.lineAndColumnOf(entry.expandedText, res.position);
          row = entry.sourceLineNum + rowAndCol[0] - 1;
          col = rowAndCol[1];
          message = res.message;
        }
      }  
      addError(entry,message,row,col);
    }
  }
  QvsLineType testLineType(line) {
    if (singleLineComment.hasMatch(line)) {
      return QvsLineType.COMMENT_LINE;
    }
    if (commandTerminationPattern.hasMatch(line)) {
      return QvsLineType.END_OF_COMMAND;
    }
    if (controlStructurePatterns.any((p) => p.hasMatch(line))) {
      return QvsLineType.CONTROL_STRUCTURE;
    }
    return QvsLineType.SIMPLE_LINE;
  }
  
}