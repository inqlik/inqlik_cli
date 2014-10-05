library qvs_reader;

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:petitparser/petitparser.dart';
import 'parser.dart';
import 'productions.dart';


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
FileReader newReader() => new FileReader(new ReaderData());
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
  String commandWithError;
  ErrorDescriptor(this.entry,this.errorMessage) {
    commandWithError = entry.commandWithError();
  }
  String toString() => 'QvsErrorDescriptor(${this.errorMessage})';
}
class Context {
  final SubDescriptor descriptor;
  final Map<String,String> params;
  Context(this.descriptor, this.params);
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
  final Queue<Context> stack = new Queue<Context>();
  final Set<String> tables = new Set<String>();
  Queue<SubDescriptor> currentSubroutineDeclaration = new Queue<SubDescriptor>();

}
class LineType {
  final String _val;
  const LineType._internal(this._val);
  static const CONTROL_STRUCTURE = const LineType._internal('CONTROL_STRUCTURE');
  static const END_OF_COMMAND = const LineType._internal('END_OF_COMMAND');
  static const SIMPLE_LINE = const LineType._internal('SIMPLE_LINE');
  static const COMMENT_LINE = const LineType._internal('COMMENT_LINE');
  String toString() => 'QvsLineType($_val)';
}

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
 
class FileReader {
  QvsParser parser;
  static final commandTerminationPattern = new RegExp(r'^.*;\s*($|//)');
  static final mustIncludePattern = new RegExp(r'^\s*\$\(must_include=(.*)\)\s*;?\s*$',caseSensitive: false); 
  static final includePattern = new RegExp(r'^\s*\$\(include=(.*)\)\s*;?\s*$',caseSensitive: false); 
  static final variableSetPattern = new RegExp(r'^\s*(LET|SET)\s+(\w[A-Za-z.0-9]*)\s*=',caseSensitive: false); 
  static final startSubroutinePattern = new RegExp(r'^\s*SUB\s',caseSensitive: false);
  static final endSubroutinePattern = new RegExp(r'^\s*End\s*Sub',caseSensitive: false);
  static final variablePattern = new RegExp(r'\$\(([\wA-Za-z._0-9]*)\)');
  static final singleLineComment = new RegExp(r'^\s*(//|REM )', caseSensitive: false);
  static final singleLineCommentinNotEmptyLine = new RegExp(r'\S\s*//');
  static final multiLineCommentStart = new RegExp(r'^\s*/[*]');
  static final closedMultiLineComment = new RegExp(r'/\*.*?\*/');
  static final closedMultiLineCommentOnWholeLine = new RegExp(r'^\s*/\*.*?\*/\s*$');
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
  FileReader(this.data) {
    parser = new QvsParser(this);
  }
  List<QvsCommandEntry> get entries => data.entries; 
  Context get context => data.stack.isEmpty? null: data.stack.first;
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
    data.errors.add(new ErrorDescriptor(entry, locMessage));  
  } 
  FileReader createNestedReader() => new FileReader(data)..skipParse = skipParse;
  
  void readFile(String fileName, [String fileContent = null, QvsCommandEntry entry = null]) {
    List<String> lines = [];
    bool rootFileMode = false;
    if (data.rootFile == null) {
     rootFileMode = true;
     data.rootFile = path.normalize(path.absolute(path.dirname(Platform.script.toFilePath()),fileName));
     String pathToDefaulInclude = path.normalize(path.join(path.dirname(data.rootFile),'default_include.qvs')); 
     if (new File(pathToDefaulInclude).existsSync()) {
       createNestedReader().readFile(pathToDefaulInclude); 
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
  void removeSystemVariables() {
    for(var each in _SYSTEM_VARIABLES.keys) {
      data.variables.remove(each);
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
  void readLines(List<String> lines) {
    int lineCounter = 0;
    int sourceLineNum = 1;
    String command = '';
    bool suppressError = false;
    List<String> commandLines = [];
    for (var line in lines) {
      if (line.trim().startsWith('//#!SKIP_PARSING')) {
        return;
      }
      if (line.trim().startsWith('//#!TRACE_TABLES')) {
        print('RESIDENT TABLES ARE: ${data.tables}');
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
      LineType lineType = testLineType(line);
      if (lineType == LineType.CONTROL_STRUCTURE 
          || lineType == LineType.END_OF_COMMAND
          || (commandLines.length == 1 && lineType == LineType.COMMENT_LINE )) {
        data.internalLineNum++;
        command = commandLines.join('\n');
        var entry = new QvsCommandEntry()
        ..sourceFileName = sourceFileName
        ..sourceLineNum = sourceLineNum
        ..suppressError = suppressError
        ..internalLineNum = data.internalLineNum
        ..sourceText = command;
        if (lineType == LineType.COMMENT_LINE) {
          entry.commandType = CommandType.COMMENT_LINE;
        }
        addCommand(entry);
        sourceLineNum = lineCounter + 1;
        suppressError = false;
        command = '';
        commandLines = [];
      }
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
  void processEntry(QvsCommandEntry entry) {
    if (entry.commandType == CommandType.COMMENT_LINE) {
      return;
    }
    expandCommand(entry);
    parseCommand(entry);  
    var m = mustIncludePattern.firstMatch(entry.expandedText);
    if (m != null) {
      entry.commandType = CommandType.MUST_INCLUDE;
      createNestedReader().readFile(m.group(1),null,entry);
    }
    if (m == null) {
      m = includePattern.firstMatch(entry.expandedText);
      if (m != null) {
        entry.commandType = CommandType.INCLUDE;
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
    if (r.isFailure) {
      addError(entry,'Invalid subroutine call');
      return;
    }
    String subName = r.value[0].trim();
    if (!subMap.containsKey(subName)) {
      addError(entry,'Call of undefined subroutine [$subName]');
      return;
    }
    if (data.stack.any((Context cnt) => cnt.descriptor.name == subName)) {
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
    data.stack.addFirst(new Context(subDescriptor,params));
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
  LineType testLineType(line) {
    if (multiLineCommentStart.hasMatch(line)) {
      if (!closedMultiLineComment.hasMatch(line)) {
        inMultiLineCommentBlock = true;
        return LineType.COMMENT_LINE;
      }  
    }
    if (closedMultiLineCommentOnWholeLine.hasMatch(line)) {
      return LineType.COMMENT_LINE;
    }
    if (inMultiLineCommentBlock) {
      if ( multiLineCommentEnd.hasMatch(line)){
        inMultiLineCommentBlock = false;
      }      
      return LineType.COMMENT_LINE;
    }
    if (singleLineComment.hasMatch(line)) {
      return LineType.COMMENT_LINE;
    }
    if (line.trim() == '') {
      return LineType.COMMENT_LINE;
    }

    if (commandTerminationPattern.hasMatch(line)) {
      return LineType.END_OF_COMMAND;
    }
    if (controlStructurePatterns.any((p) => p.hasMatch(line))) {
      return LineType.CONTROL_STRUCTURE;
    }
    return LineType.SIMPLE_LINE;
  }
  
}