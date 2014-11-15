library qv_exp_reader;

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:petitparser/petitparser.dart';
import 'parser.dart';
import 'reader.dart';
import 'productions.dart';
QvExpReader newReader() => new QvExpReader(new ReaderData());
QvExpReader read(String fileName, String code) {
  var reader = new QvExpReader(new ReaderData());
  reader.sourceFileName = fileName;
  reader.readLines(code.split('\n'));
  return reader;
}
class TagTuple {
  String key;
  String value;
}
class Expression {
  String sourceText;
  String expandedDefinition;
  String name;
  String definition;
  String label;
  String comments;
  String tag;
  Map<String,String> tags = new Map<String,String>(); 
  bool isMacro = false;
  String _currentTag;
  List<String> _currentContent = [];
  ExpressionEntry entry;
  String addLine(String line, LineType lineType) {
    if (lineType == LineType.UNDEFINED || lineType == LineType.BLANK) {
      if (_currentTag == null) {
        return 'Unexpected string $line.';
      }
      _currentContent.add(line);
    }
    if (lineType == LineType.EXPRESSION_NAME) {
      if (_currentTag != null) {
        return 'Name (set|let) tag should be first in expression. $line';
      }
      if (name != null) {
        return 'Repeated expression name definition $line';
      }
      var tagTuple = splitTag(line);
      name = tagTuple.value;
      tags[tagTuple.key] = tagTuple.value;
    }
    if (lineType == LineType.EXPRESSION_TAG) {
      completeCurrentTag();
      var tagTuple = splitTag(line);
      _currentTag = tagTuple.key;
      _currentContent.add(tagTuple.value);
    }
    return '';
  }
  void completeCurrentTag() {
    if (_currentTag == null) {
      return;
    }
    var value = _currentContent.join('\r\n');
    tags[_currentTag] = value;
    _currentTag = null;
    _currentContent.clear();
  }
  toString() => 'Expression(name: $name, lavel: $label, tag: $tag, definition: $definition)';
  TagTuple splitTag(String line) {
    var result = new TagTuple();
    int colonPos = line.indexOf(':');
    result.key = line.substring(0,colonPos).trim();
    result.value = line.substring(colonPos+1).trim();
    return result;
  }
}
class ExpressionEntry {
  int sourceLineNum;
  int internalLineNum;
  String sourceText;
  Expression expression;
  String get content => entryType == EntryType.EXPRESSION ? expression.toString(): sourceText;  
  EntryType entryType;
  bool parsed = false;
  bool hasError = false;
  bool suppressError = false;
  int errorPosition = 0;
  ExpressionEntry(LineType lineType, this.sourceLineNum, this.sourceText) {
    if (lineType == LineType.EXPRESSION_DELIMITER) {
      entryType = EntryType.EXPRESSION;
      expression = new Expression();
    } else if (lineType == LineType.DEFINE) {
      entryType = EntryType.DEFINE;
    } else if (lineType == LineType.SECTION_HEADER) {
      entryType = EntryType.SECTION_HEADER;
    } else if (lineType == LineType.BLANK) {
      entryType = EntryType.BLANK;
    }
    assert(entryType != null);
  }
  String toString() => 'ExpressionEntry(sourceLineNum=$sourceLineNum, $content)';
//  String commandWithError() {
//    if (errorPosition != 0) {
//      return expandedText.substring(0,errorPosition) + ' ^^^ ' + expandedText.substring(errorPosition);
//    }
//    return expandedText;
//  }
}
class ErrorDescriptor {
  final ExpressionEntry entry;
  final String errorMessage;
  int lineNum;
  String commandWithError;
  ErrorDescriptor(this.entry, this.errorMessage, this.lineNum) {
//    commandWithError = entry.commandWithError();
  }
  String toString() => 'ErrorDescriptor(${this.errorMessage})';
}
class ReaderData {
  String qvwFileName;
  int internalLineNum=0;
  final List<ExpressionEntry> entries = [];
  String rootFile;
  final List<ErrorDescriptor> errors = [];
  final Set<String> tables = new Set<String>();
  void printState() {
    print('ReaderData state. entries: ${entries.length}, errors: ${errors.length}');
  }
}
class QvExpDirective {
  static const String EXPRESSION_DELIMITER = '---';
  static const String DEFINE = '#define';
  static const String SECTION = '#SECTION';
}

class LineType {
  final String _val;
  final bool startsNewEntry;
  const LineType._internal(this._val, this.startsNewEntry);
  static const EXPRESSION_DELIMITER = const LineType._internal('EXPRESSION_DELIMITER',true);
  static const EXPRESSION_NAME = const LineType._internal('EXPRESSION_NAME',false);
  static const EXPRESSION_TAG = const LineType._internal('EXPRESSION_TAG',false);
  static const SECTION_HEADER = const LineType._internal('SECTION_HEADER',true);
  static const DEFINE = const LineType._internal('DEFINE',true);
  static const BLANK = const LineType._internal('BLANK',false);
  static const UNDEFINED = const LineType._internal('UNDEFINED',false);
  bool get isEntryDelimiter => _val == 'DEFINE' || _val == 'EXPRESSION_DELIMITER' || _val == 'SECTION_HEADER'; 
  String toString() => 'LineType($_val)';
}

class EntryType {
  final String _val;
  const EntryType._internal(this._val);
  static const EXPRESSION = const EntryType._internal('EXPRESSION');
  static const DEFINE = const EntryType._internal('DEFINE');
  static const SECTION_HEADER = const EntryType._internal('SECTION_HEADER');
  static const MACRO = const EntryType._internal('MACRO');
  static const BLANK = const EntryType._internal('BLANK');
  String toString() => 'CommandType($_val)';
}
class ReaderState {
  final String _val;
  const ReaderState._internal(this._val);
  static const BLANK = const ReaderState._internal('BLANK');
  static const INSIDE_TAG = const ReaderState._internal('INSIDE_TAG');
  static const INSIDE_EXPPRESSION = const ReaderState._internal('INSIDE_EXPPRESSION');
  String toString() => 'CommandType($_val)';
}


class QvExpReader extends QlikViewReader{
  QvsParser parser;
  static final startNewTagPattern = new RegExp(r'^\s*(backgroundColor|billionSymbol|command|definition|description|description|enableCondition|fontColor|label|let|macro|millionSymbol|name|separator|set|showCondition|sortBy|symbol|tag|textFormat|thousandSymbol|visualCueLower|visualCueUpper):');
  static final startDirectivePattern = new RegExp(r'^\s*(#define|#SECTION|---)');
  String currentSection;
  String sourceFileName;
  bool skipParse = false;
  bool inMultiLineCommentBlock = false;
  ExpressionEntry _expEntry;
  final ReaderData data;
  QvExpReader(this.data) {
    parser = new QvsParser(this);
  }
  List<ExpressionEntry> get entries => data.entries; 
  List<ErrorDescriptor> get errors => data.errors; 
  String toString() => 'QvExpReader(${data.entries})';
  bool get hasErrors => data.errors.isNotEmpty;
  void readFile(String fileName, [String fileContent = null]) {
      List<String> lines = [];
      data.rootFile = path.normalize(path.absolute(path.dirname(Platform.script.toFilePath()),fileName));
      if (fileContent != null) {
        lines = fileContent.split('\n');
      } else {
        if (! new File(sourceFileName).existsSync()) {
          try {
            lines = new File(sourceFileName).readAsLinesSync();
          } catch (exception, stacktrace) {
            print(exception);
            return; 
          }
        }
      }
    readLines(lines);
  }
  void addError(ExpressionEntry entry, String message,[int row, int col]) {
    if (entry.suppressError) {
      return;
    }
    if (row == null) {
      row = entry.sourceLineNum;
    }
    if (col == null) {
      col = 1;
    }
    var locMessage = 'Parse error. File: "${sourceFileName}", line: $row col: $col message: $message';
    data.errors.add(new ErrorDescriptor(entry, locMessage, row));  
  } 
  void _processCurrentExpression() {
    if (_expEntry == null) {
      return;
    }
    _expEntry.expression.completeCurrentTag();
    addEntry(_expEntry);
    _expEntry = null;
  }
  void readLines(List<String> lines) {
    ReaderState state = ReaderState.BLANK;
    ExpressionEntry _entry;
    int lineNum = 0;
    for (var line in lines) {
      lineNum ++;
      var lineType = testLineType(line);
      if (lineType.startsNewEntry) {
        _processCurrentExpression();
        _expEntry = new ExpressionEntry(lineType, lineNum, line);
        if (lineType != LineType.EXPRESSION_DELIMITER) {
          _processCurrentExpression();
        }
      } else {
        if (_expEntry == null) {
          if (lineType == LineType.BLANK) {
            _expEntry = new ExpressionEntry(lineType, lineNum, line);
            _processCurrentExpression();
          } else {
            addError(null,'Expression not started. Unexpected line $line', lineNum);
            return;
          }
        }
        _expEntry.expression.addLine(line,lineType);
      }
    }
    _processCurrentExpression();
  }
  LineType testLineType(String line) {
    line = line.trim();
    if (line == '') {
      return LineType.BLANK;
    }
    if (line.startsWith(QvExpDirective.EXPRESSION_DELIMITER)) {
      return LineType.EXPRESSION_DELIMITER;
    }
    if (line.startsWith(QvExpDirective.SECTION)) {
      return LineType.SECTION_HEADER;
    }
    if (line.startsWith(QvExpDirective.DEFINE)) {
      return LineType.DEFINE;
    }
    if (line.startsWith('set:') || line.startsWith('let:')) {
      return LineType.EXPRESSION_NAME;
    }
    if (line.startsWith(startNewTagPattern)) {
      return LineType.EXPRESSION_TAG;
    }
    return LineType.UNDEFINED;
  }
  void addEntry(ExpressionEntry entry) {
    data.entries.add(entry);
  }
   
}