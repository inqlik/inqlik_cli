library qvs_reader;

import 'dart:io';
import 'dart:collection';
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
  bool suppressError = false;
  int errorPosition = 0;
  //QvsCommandEntry(this.sourceFileName,this.sourceLineNum, this.internalLineNum, this.sourceText, this.expandedText);
  String toString() => 'QvsCommandEntry($sourceFileName,sourceLineNum=$sourceLineNum, internalLineNum=$internalLineNum,$sourceText)';
  String commandWithError() {
    if (errorPosition != 0) {
      return expandedText.substring(0,errorPosition) + ' ^^^ ' + expandedText.substring(errorPosition);
    }
    return expandedText;
  }
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
  final Queue<Map<String,String>> subParams = new Queue<Map<String,String>>();
}
class QvsLineType {
  final String _val;
  const QvsLineType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsLineType._internal('CONTROL_STRUCTURE');
  static const END_OF_COMMAND = const QvsLineType._internal('END_OF_COMMAND');
  static const SIMPLE_LINE = const QvsLineType._internal('SIMPLE_LINE');
  static const COMMENT_LINE = const QvsLineType._internal('COMMENT_LINE');
  String toString() => 'QvsLineType($_val)';
}

class QvsCommandType {
  final String _val;
  const QvsCommandType._internal(this._val);
  static const CONTROL_STRUCTURE = const QvsCommandType._internal('CONTROL_STRUCTURE');
  static const MUST_INCLUDE = const QvsCommandType._internal('MUST_INCLUDE');
  static const INCLUDE = const QvsCommandType._internal('INCLUDE');
  static const BASE_COMMAND = const QvsCommandType._internal('BASE_COMMAND');
  static const SUB_DECLARATION = const QvsCommandType._internal('SUB_DECLARATION');
  static const SUB_DECLARATION_END = const QvsCommandType._internal('SUB_DECLARATION_END');
  static const COMMENT_LINE = const QvsCommandType._internal('COMMENT_LINE');
  String toString() => 'QvsCommandType($_val)';
}

 
class QvsFileReader {
  QvsParser parser;
  static final commandTerminationPattern = new RegExp(r'^.*;\s*($|//)');
  static final mustIncludePattern = new RegExp(r'^\s*\$\(must_include=(.*)\)\s*;\s*$'); 
  static final includePattern = new RegExp(r'^\s*\$\(include=(.*)\)\s*;\s*$'); 
  static final variableSetPattern = new RegExp(r'^\s*(LET|SET)\s+(\w[A-Za-z.0-9]*)\s*=',caseSensitive: false); 
  static final startSubroutinePattern = new RegExp(r'^\s*SUB\s+(\w[A-Za-z.0-9_]+)',caseSensitive: false);
  static final endSubroutinePattern = new RegExp(r'^\s*End\s*Sub',caseSensitive: false);
  static final variablePattern = new RegExp(r'\$\((\w[A-Za-z.0-9]*)\)');
  static final singleLineComment = new RegExp(r'^\s*//');
  static final multiLineCommentStart = new RegExp(r'^\s*/[*]');
  static final multiLineCommentEnd = new RegExp(r'\*/\s*$');
  static final suppressErrorPattern = new RegExp(r'//#!SUPPRESS_ERROR\s*$');
  static final callSubroutinePattern = new RegExp(r'^\s*CALL\s+(\w[A-Za-z.0-9]+)',caseSensitive: false); 
  static final controlStructurePatterns = [
    new RegExp(r'^\s*IF\s.*THEN\s*$',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSEIF\s.*THEN\s*',caseSensitive: false),                                     
    new RegExp(r'^\s*ELSE\s*',caseSensitive: false),                                     
    new RegExp(r'^\s*FOR\s',caseSensitive: false),                                     
    new RegExp(r'^\s*EXIT\s',caseSensitive: false),                                     
    new RegExp(r'^\s*DO\s+',caseSensitive: false),                                     
    new RegExp(r'^\s*LOOP\s*$',caseSensitive: false),                                     
    new RegExp(r'^\s*LOOP\s+(WHILE|UNTIL)',caseSensitive: false),                                     
    new RegExp(r'^\s*NEXT',caseSensitive: false),                                     
    new RegExp(r'^\s*END\s?IF\s*',caseSensitive: false),
    startSubroutinePattern,
    endSubroutinePattern,
    callSubroutinePattern
    ];
  String sourceFileName;
  bool skipParse = false;
  String inSubDeclaration = '';
  bool inMultiLineCommentBlock = false;
  final QvsReaderData data;
  QvsFileReader(this.data) {
    parser = new QvsParser(this);
  }
  List<QvsCommandEntry> get entries => data.entries; 
  Map<String, String> get currentParams => data.subParams.isEmpty? {}: data.subParams.first;
  Map<String, int> get subMap => data.subMap; 
  List<QvsErrorDescriptor> get errors => data.errors; 
  String toString() => 'QvsReader(${data.entries})';
  bool get hasErrors => data.errors.isNotEmpty;
  void addError(QvsCommandEntry entry, String message,[int row, int col]) {
    if (entry.suppressError) {
      return;
    }
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
    bool suppressError = false;
    List<String> commandLines = [];
    for (var line in lines) {
      commandLines.add(line);
      if (suppressErrorPattern.hasMatch(line)) {
        suppressError = true;
      }
      lineCounter++;
      QvsLineType lineType = testLineType(line);
      if (lineType == QvsLineType.CONTROL_STRUCTURE 
          || lineType == QvsLineType.END_OF_COMMAND
          || (commandLines.length == 1 && lineType == QvsLineType.COMMENT_LINE )) {
        data.internalLineNum++;
        command = commandLines.join('\n');
        var entry = new QvsCommandEntry()
        ..sourceFileName = sourceFileName
        ..sourceLineNum = sourceLineNum
        ..suppressError = suppressError
        ..internalLineNum = data.internalLineNum
        ..sourceText = command;
        if (lineType == QvsLineType.COMMENT_LINE) {
          entry.commandType = QvsCommandType.COMMENT_LINE;
        }
        addCommand(entry);
        sourceLineNum = lineCounter + 1;
        suppressError = false;
        command = '';
        commandLines = [];
      }
    }
    if (inSubDeclaration != '') {
      addError(data.entries.last,'SUB ${inSubDeclaration} has not been closed propery');
    }
  }

  void expandCommand(QvsCommandEntry entry) {
    entry.expandedText = entry.sourceText;
    var m = variablePattern.firstMatch(entry.expandedText);
    while (m != null) {
      var varName = m.group(1);
      var varValue = '';
      if (currentParams.containsKey(varName)) {
        varValue = currentParams[varName];
      } else if (data.variables.containsKey(varName)) {
        varValue = data.variables[varName];
      } else {
        addError(entry,'Variable $varName not defined');
      }
      entry.expandedText = entry.expandedText.replaceAll('\$($varName)',varValue == null ? '' : varValue);
      m = variablePattern.firstMatch(entry.expandedText);
    }
  }
  void processAssignmentCommand(String varName, String varValue, bool isLetCommand) {
    if (varValue == null) { 
      varValue = '';
    } else {
      varValue = varValue.trim();
    }
    if (varValue.startsWith("'") && varValue.endsWith("'")) {
      varValue = varValue.replaceAll("'",'');
    } else {
      if (isLetCommand) {
        Result num = parser[number].end().parse(varValue);
        if (num.isFailure) {
          varValue = '${varName}_ASSIGNED_VALUE';
        }
      }
    }
    if (currentParams.containsKey(varName)) {
      if (currentParams[varName] == null) {
        currentParams.remove(varName);
        data.variables[varName] = varValue;
      } else {
        currentParams[varName] = varValue;
      }
    } else {
      data.variables[varName] = varValue;
    }
  }
  void processEntry(QvsCommandEntry entry) {
    if (entry.commandType == QvsCommandType.COMMENT_LINE) {
      return;
    }
    expandCommand(entry);
    parseCommand(entry);  
//    processSetVariableCommand(entry);
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
    Result r = parser[call].end().parse(entry.expandedText);
    String subName = r.value[0];
    if (!subMap.containsKey(subName)) {
      addError(entry,'Call of undefined subroutine [$subName]');
      return;
    }
    List<String> actualParams = r.value[1];
    int idx = subMap[subName];
    QvsCommandEntry currentEntry = entries[idx];
    r = parser[subStart].end().parse(currentEntry.sourceText);
    List<String> formalParams = [];
    if (r.value[1] is !String) {
      formalParams.addAll(r.value[1][2]);
    }
    Map<String,String> params = {};
    data.subParams.addFirst(params);
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
    currentEntry = entries[++idx];
    while (currentEntry.commandType != QvsCommandType.SUB_DECLARATION_END) {
      processEntry(currentEntry);
      idx++;
      if (idx == entries.length) {
        throw new Exception('Walked past of list boundary in walkIntoSubroutine');
      }
      currentEntry = entries[idx];
    }
    data.subParams.removeFirst();
  }
  void addCommand(QvsCommandEntry entry) {
    data.entries.add(entry);
    if (inSubDeclaration == '') {
      processEntry(entry);
    }
    var m = startSubroutinePattern.firstMatch(entry.sourceText);
    if (m != null) {
      entry.commandType = QvsCommandType.SUB_DECLARATION;
      String debug = m.group(1).trim();
      subMap[m.group(1)] = entry.internalLineNum -1;
      inSubDeclaration = m.group(1);
    }
    if (m == null) {
      m = endSubroutinePattern.firstMatch(entry.sourceText);
      if (m != null) {
        entry.commandType = QvsCommandType.SUB_DECLARATION_END;
        inSubDeclaration = '';
      }
    }
  }
  void parseCommand(QvsCommandEntry entry) {
    Result res = parser.ref(command).end()
         .parse(entry.expandedText);
    entry.parsed = true;
    if (res.isFailure) {
      int maxPosition = -1;
      int row;
      int col;
      var rowAndCol;
      String message;
      for (Parser p in parser.ref(command).children) {
        res = p.end().parse(entry.expandedText);
        if (maxPosition < res.position) {
          maxPosition = res.position;
          entry.errorPosition = maxPosition;
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
    if (multiLineCommentStart.hasMatch(line)) {
      inMultiLineCommentBlock = true;
      return QvsLineType.COMMENT_LINE;
    }
    if (inMultiLineCommentBlock) {
      if ( multiLineCommentEnd.hasMatch(line)){
        inMultiLineCommentBlock = false;
      }      
      return QvsLineType.COMMENT_LINE;
    }
    if (singleLineComment.hasMatch(line)) {
      return QvsLineType.COMMENT_LINE;
    }
    if (line.trim() == '') {
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