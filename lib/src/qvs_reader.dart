library qvs_reader;

import 'dart:collection';
import 'package:petitparser/petitparser.dart';
import 'parser.dart';
import 'productions.dart';
import 'reader.dart';

QvsReader readQvs(String fileName, String code) {
  var reader = new QvsReader(new ReaderData());
  reader.sourceFileName = fileName;
  reader.readLines(code.split('\n'));
  return reader;
}
class QvDirective {
  static const String SUPPRESS_ERROR = '//#!QV_SUPPRESS_ERROR';
  static const String SKIP_PARSING = '//#!QV_SKIP_PARSING';
  static const String TRACE_TABLES = '//#!QV_TRACE_TABLES';
  static const String TRACE_USER_VARIABLES = '//#!QV_TRACE_USER_VARIABLES';
}
const _SYSTEM_VARIABLES = const {
  'CD':  "E:",
  'QvPath':  "C:\PROGRA~1\QlikView",
  'QvRoot':  "C:",
  'QvWorkPath':  "C:\Projects\Qlikview-Components\Examples",
  'QvWorkRoot':  "C:",
  'WinPath': "C:\WINDOWS",
  'WinRoot': "C:",
  'ErrorMode': "1",
  'StripComments': '1',
  'OpenUrlTimeout':  '86400',
  'ScriptErrorCount':  '0',
  'ScriptErrorList': "",
  'ScriptError': null,  
  'ThousandSep': ",",
  'DecimalSep':  ".",
  'MoneyThousandSep':  ",",
  'MoneyDecimalSep': ".",
  'MoneyFormat': r"$#,##0.00;($#,##0.00)",
  'TimeFormat':  "h:mm:ss TT",
  'DateFormat':  "M/D/YYYY",
  'TimestampFormat': "M/D/YYYY h:mm:ss[.fff] TT",
  'MonthNames':  "Jan;Feb;Mar;Apr;May;Jun;Jul;Aug;Sep;Oct;Nov;Dec",
  'DayNames':  "Mon;Tue;Wed;Thu;Fri;Sat;Sun",
  'ScriptErrorDetails':  null
  };
class QvsCommandEntry {
  String sourceFileName;
  int sourceLineNum;
  int internalLineNum;
  String sourceText;
  String expandedText;
  CommandType commandType;
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
class ErrorDescriptor {
  final QvsCommandEntry entry;
  final String errorMessage;
  int lineNum;
  String commandWithError;
  ErrorDescriptor(this.entry, this.errorMessage, this.lineNum) {
    commandWithError = entry.commandWithError();
  }
  String toString() => 'QvsErrorDescriptor(${this.errorMessage})';
}
class ReaderContext {
  final SubDescriptor descriptor;
  final Map<String,String> params;
  ReaderContext(this.descriptor, this.params);
  String toString() => 'StackItem($descriptor, $params)';
}
class ReaderData {
  String qvwFileName;
  int internalLineNum=0;
  final List<QvsCommandEntry> entries = [];
  final Map<String, SubDescriptor> subMap = {};
  final Map<int, SubDescriptor> subEntries = {};
  String rootFile;
  final List<ErrorDescriptor> errors = [];
  final Map<String, String> variables = new Map<String, String>.from(_SYSTEM_VARIABLES);
  final Queue<ReaderContext> stack = new Queue<ReaderContext>();
  final Set<String> tables = new Set<String>();
  Queue<SubDescriptor> currentSubroutineDeclaration = new Queue<SubDescriptor>();
  void printState() {
    print('ReaderData state. entries: ${entries.length}, errors: ${errors.length}');
  }
}
enum _LineType { CONTROL_STRUCTURE, END_OF_COMMAND, SIMPLE_LINE, COMMENT_LINE }

class CommandType {
  final String _val;
  const CommandType._internal(this._val);
  static const CONTROL_STRUCTURE = const CommandType._internal('CONTROL_STRUCTURE');
  static const MUST_INCLUDE = const CommandType._internal('MUST_INCLUDE');
  static const INCLUDE = const CommandType._internal('INCLUDE');
  static const BASE_COMMAND = const CommandType._internal('BASE_COMMAND');
  static const SUB_DECLARATION = const CommandType._internal('SUB_DECLARATION');
  static const SUB_DECLARATION_END = const CommandType._internal('SUB_DECLARATION_END');
  static const COMMENT_LINE = const CommandType._internal('COMMENT_LINE');
  String toString() => 'QvsCommandType($_val)';
}

class SubDescriptor {
  final String name;
  final int startIndex;
  int sourceStart;
  int sourceEnd;
  int endIndex;
  SubDescriptor(this.name,this.startIndex);
  String toString() => "QvsSubDescriptor($name,$sourceStart,$sourceEnd)";
}
 
class QvsReader extends QlikViewReader{
  QvsParser parser;
  static final commandTerminationPattern = new RegExp(r'^.*;\s*($|//)');
  static final mustIncludePattern = new RegExp(r'^\s*\$\(must_include=(.*)\)\s*;?\s*$',caseSensitive: false); 
  static final includePattern = new RegExp(r'^\s*\$\(include=(.*)\)\s*;?\s*$',caseSensitive: false); 
  static final variableSetPattern = new RegExp(r'^\s*(LET|SET)\s+(\w[A-Za-z.0-9]*)\s*=',caseSensitive: false); 
  static final startSubroutinePattern = new RegExp(r'^\s*SUB\s',caseSensitive: false);
  static final endSubroutinePattern = new RegExp(r'^\s*End\s*Sub',caseSensitive: false);
  static final variablePattern = new RegExp(r'\$\(([\wA-Za-za-яА-Я._0-9]*)\)');
  static final singleLineComment = new RegExp(r'^\s*(//|REM )', caseSensitive: false);
  static final singleLineCommentinNotEmptyLine = new RegExp(r'\S\s*//');
  static final multiLineCommentStart = new RegExp(r'^\s*/[*]');
  static final closedMultiLineComment = new RegExp(r'/\*.*?\*/');
  static final closedMultiLineCommentOnWholeLine = new RegExp(r'^\s*/\*.*?\*/\s*$');
  static final multiLineCommentEnd = new RegExp(r'\*/\s*$');
  static final suppressErrorPattern = new RegExp(QvDirective.SUPPRESS_ERROR + r'\s*$');
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
    new RegExp(r'^\s*END\s?(IF|SWITCH)',caseSensitive: false),
    new RegExp(r'^\s*SWITCH',caseSensitive: false),                                     
    new RegExp(r'^\s*CASE',caseSensitive: false),                                     
    new RegExp(r'^\s*DEFAULT\s*;?\s*$',caseSensitive: false),
    startSubroutinePattern,
    endSubroutinePattern,
    callSubroutinePattern,
    mustIncludePattern,
    includePattern
    ];
  String sourceFileName;
  bool skipParse = false;
  bool inMultiLineCommentBlock = false;
  final ReaderData data;
  QvsReader(this.data) {
    parser = new QvsParser(this);
  }
  List<QvsCommandEntry> get entries => data.entries; 
  ReaderContext get context => data.stack.isEmpty? null: data.stack.first;
  Map<String, SubDescriptor> get subMap => data.subMap; 
  List<ErrorDescriptor> get errors => data.errors; 
  String toString() => 'QvsReader(${data.entries})';
  bool get hasErrors => data.errors.isNotEmpty;
  bool justLocateQvw = false;
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
    data.errors.add(new ErrorDescriptor(entry, locMessage, row));  
  } 

  
  void removeSystemVariables() {
    for(var each in _SYSTEM_VARIABLES.keys) {
      data.variables.remove(each);
    }
  }
  void printUserVariables() {
    print('User variables dump: not implemented yet');
  }
  void readLines(List<String> lines) {
    int lineCounter = 0;
    int sourceLineNum = 1;
    String command = '';
    bool suppressError = false;
    _LineType lineType;
    List<String> commandLines = [];
    _processCommand([bool finishMode = false]) {
      data.internalLineNum++;
      command = commandLines.join('\n');
      var entry = new QvsCommandEntry()
      ..sourceFileName = sourceFileName
      ..sourceLineNum = sourceLineNum
      ..suppressError = suppressError
      ..internalLineNum = data.internalLineNum
      ..sourceText = command;
      if (!finishMode && lineType == _LineType.COMMENT_LINE) {
        entry.commandType = CommandType.COMMENT_LINE;
      }
      addCommand(entry);
      sourceLineNum = lineCounter + 1;
      suppressError = false;
      command = '';
      commandLines = [];
      
    }
    for (var line in lines) {
      if (line.trim().startsWith(QvDirective.SKIP_PARSING)) {
        return;
      }
      if (line.trim().startsWith(QvDirective.TRACE_TABLES)) {
        print('RESIDENT TABLES ARE: ${data.tables}');
      }
      if (line.trim().startsWith(QvDirective.TRACE_USER_VARIABLES)) {
        printUserVariables();
      }

      if (suppressErrorPattern.hasMatch(line)) {
        suppressError = true;
      }
      if (singleLineCommentinNotEmptyLine.hasMatch(line)) {
        // Make sure that comment blok is not within the string
        var leftPart = line.split('//').first;
        int i = "'".allMatches(leftPart).toList().length;
        if (i % 2 != 1) {
          line = leftPart;
        }
      }
      commandLines.add(line);
      lineCounter++;
      lineType = testLineType(line);
      if (lineType == _LineType.CONTROL_STRUCTURE 
          || lineType == _LineType.END_OF_COMMAND
          || (commandLines.length == 1 && lineType == _LineType.COMMENT_LINE )) {
        _processCommand();
      }
      
    }
    if (commandLines.isNotEmpty) {
      _processCommand(true);
    }
    if (data.currentSubroutineDeclaration.isNotEmpty) {
      addError(data.entries.last,'SUB ${data.currentSubroutineDeclaration.first.name} has not been closed properly');
    }
  }

  void expandCommand(QvsCommandEntry entry) {
    entry.expandedText = entry.sourceText;
    var m = variablePattern.firstMatch(entry.expandedText);
    while (m != null) {
      var varName = m.group(1);
      var varValue = '';
      if (context != null && context.params.containsKey(varName)) {
        varValue = context.params[varName];
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
    if (varValue.startsWith("'") 
          && varValue.endsWith("'") 
          && "'".allMatches(varValue).toList().length == 2) {
      varValue = varValue.replaceAll("'",'');
    } else {
      if (isLetCommand) {
        Result num = parser[number].end().parse(varValue);
        if (num.isFailure) {
          varValue = '${varName}_ASSIGNED_VALUE';
        }
      }
    }
    if (context != null && context.params.containsKey(varName)) {
      if (context.params[varName].endsWith('_NULL_VALUE')) {
        context.params.remove(varName);
        data.variables[varName] = varValue;
      } else {
        context.params[varName] = varValue;
      }
    } else {
      data.variables[varName] = varValue;
    }
  }
  void readIncludeFile(String fileName, String fileContent, QvsCommandEntry entry) {
    this.addError(entry, 'include directive is not implemented in web parser');
  }
  void processEntry(QvsCommandEntry entry) {
    if (entry.commandType == CommandType.COMMENT_LINE) {
      return;
    }
    expandCommand(entry);
    parseCommand(entry);  
    var m = mustIncludePattern.firstMatch(entry.expandedText);
    if (m != null) {
      entry.commandType = CommandType.MUST_INCLUDE;
      readIncludeFile(m.group(1),null,entry);
    }
    if (m == null) {
      m = includePattern.firstMatch(entry.expandedText);
      if (m != null) {
        entry.commandType = CommandType.INCLUDE;
        readIncludeFile(m.group(1),null,entry);
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
    if (r.isFailure) {
      addError(entry,'Invalid subroutine call');
      return;
    }
    String subName = r.value[0].trim();
    if (!subMap.containsKey(subName)) {
      addError(entry,'Call of undefined subroutine [$subName]');
      return;
    }
    if (data.stack.any((ReaderContext cnt) => cnt.descriptor.name == subName)) {
      // Do not step into recursion
      return;
    }
    List<String> actualParams = r.value[1];
    SubDescriptor subDescriptor = subMap[subName];
    QvsCommandEntry currentEntry = entries[subDescriptor.startIndex];
    r = parser[subStart].end().parse(currentEntry.sourceText);
    if (r.isFailure) {
      throw r.message;
    }
    List<String> formalParams = [];
    if (r.value[1][1] != null) {
      formalParams.addAll(r.value[1][1][1]);
    }
    Map<String,String> params = {};
    if (data.stack.isNotEmpty) {
      params.addAll(data.stack.first.params);
    }
    data.stack.addFirst(new ReaderContext(subDescriptor,params));
    for (int paramIdx = 0; paramIdx<formalParams.length;paramIdx++) {
      String paramValue;
      String paramName = formalParams[paramIdx];
      if (paramIdx<actualParams.length) {
        paramValue = actualParams[paramIdx];
      }
      params[paramName] = paramValue;
      if (paramValue != null) {
        processAssignmentCommand(paramName, paramValue, true);     
      } else {
        params[paramName] = '${paramName}_NULL_VALUE';
      }
    }
    for (int idx = subMap[subName].startIndex+1; idx < subMap[subName].endIndex; idx++) {
      if (idx == entries.length) {
        throw new Exception('Walked past of list boundary in walkIntoSubroutine');
      }
      if (data.subEntries.containsKey(idx)) { // Skip statements in nested sub
        idx = data.subEntries[idx].endIndex;
      } else {
        processEntry(entries[idx]);
      }  
    }
    data.stack.removeFirst();
  }
  void addCommand(QvsCommandEntry entry) {
    data.entries.add(entry);
    if (data.currentSubroutineDeclaration.isEmpty) {
      processEntry(entry);
    }
    var m = startSubroutinePattern.firstMatch(entry.sourceText);
    if (m != null) {
      entry.commandType = CommandType.SUB_DECLARATION;
      Result r = parser[subStart].parse(entry.sourceText.trim());
      if (r.isFailure) {
        addError(entry,'Invalid subroutine call');
        return;
      }
      String subName = r.value[1][0].trim();

//      String debug = m.group(1).trim();
      var sub = new SubDescriptor(subName,entry.internalLineNum - 1);
      sub.sourceStart = entry.sourceLineNum;
      subMap[sub.name] = sub;
      data.subEntries[sub.startIndex] = sub;
      data.currentSubroutineDeclaration.addFirst(sub);
    }
    if (m == null) {
      m = endSubroutinePattern.firstMatch(entry.sourceText);
      if (m != null) {
        entry.commandType = CommandType.SUB_DECLARATION_END;
        if (data.currentSubroutineDeclaration.isNotEmpty) {
          var sub = data.currentSubroutineDeclaration.removeFirst();
          sub.endIndex = entry.internalLineNum - 1;
          sub.sourceEnd = entry.sourceLineNum;
        } else {
          addError(entry,'Extra end of sub.');  
        }
//        else {
//          addError(entry,'');  
//        }
      }
    }
  }
  void parseCommand(QvsCommandEntry entry) {
    if (entry.expandedText == null) {
      throw entry;
    }
    Result res = parser.guarded_parse(entry.expandedText,command);
//    Result res = parser.ref(command).end()
//         .parse(entry.expandedText);
    entry.parsed = true;
    if (res.isFailure) {
      int maxPosition = -1;
      int row;
      int col;
      var rowAndCol;
      String message;
      for (Parser p in parser.ref(command).children) {
        res = qv_parse(p.end(),entry.expandedText);
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
  _LineType testLineType(line) {
    if (multiLineCommentStart.hasMatch(line)) {
      if (!closedMultiLineComment.hasMatch(line)) {
        inMultiLineCommentBlock = true;
        return _LineType.COMMENT_LINE;
      }  
    }
    if (closedMultiLineCommentOnWholeLine.hasMatch(line)) {
      return _LineType.COMMENT_LINE;
    }
    if (inMultiLineCommentBlock) {
      if ( multiLineCommentEnd.hasMatch(line)){
        inMultiLineCommentBlock = false;
      }      
      return _LineType.COMMENT_LINE;
    }
    if (singleLineComment.hasMatch(line)) {
      return _LineType.COMMENT_LINE;
    }
    if (line.trim() == '') {
      return _LineType.COMMENT_LINE;
    }

    if (commandTerminationPattern.hasMatch(line)) {
      return _LineType.END_OF_COMMAND;
    }
    if (controlStructurePatterns.any((p) => p.hasMatch(line))) {
      return _LineType.CONTROL_STRUCTURE;
    }
    return _LineType.SIMPLE_LINE;
  }
  void addTable(String tableName) {
    data.tables.add(tableName);
  }
  void removeTable(String tableName) {
    data.tables.remove(tableName);
  }
}