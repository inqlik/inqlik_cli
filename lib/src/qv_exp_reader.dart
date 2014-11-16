library qv_exp_reader;

import 'dart:io';
import 'dart:collection';
import 'package:csv/csv.dart';
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
  String section;
  Map<String,String> tags = new Map<String,String>(); 
  bool isMacro = false;
  String _currentTag;
  List<String> _currentContent = [];
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
      name = tagTuple.value.trim();
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
    var value = _currentContent.join('\n');
    tags[_currentTag] = value;
    _currentTag = null;
    _currentContent.clear();
  }
  toString() => 'Expression(name: $name, lavel: $label, section: $section, definition: $definition)';
  TagTuple splitTag(String line) {
    var result = new TagTuple();
    int colonPos = line.indexOf(':');
    result.key = line.substring(0,colonPos).trim();
    result.value = line.substring(colonPos+1);
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
  final Map<String,Expression> expMap = {};
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
  String toString() => '$_val';
}
class ReaderState {
  final String _val;
  const ReaderState._internal(this._val);
  static const BLANK = const ReaderState._internal('BLANK');
  static const INSIDE_TAG = const ReaderState._internal('INSIDE_TAG');
  static const INSIDE_EXPPRESSION = const ReaderState._internal('INSIDE_EXPPRESSION');
  String toString() => '$_val';
}


class QvExpReader extends QlikViewReader{
  QvsParser parser;
  static final startNewTagPattern = new RegExp(r'^\s*(backgroundColor|billionSymbol|command|definition|comment|enableCondition|fontColor|label|let|macro|millionSymbol|name|separator|set|showCondition|sortBy|symbol|tag|textFormat|thousandSymbol|visualCueLower|visualCueUpper):');
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
      sourceFileName = data.rootFile;
      if (fileContent != null) {
        lines = fileContent.split('\n');
      } else {
        var file = new File(sourceFileName);
        if (file.existsSync()) {
          try {
            lines = file.readAsLinesSync();
          } catch (exception, stacktrace) {
            print(exception);
            return; 
          }
        }
      }
      readLines(lines);
  }
  void printErrors() {
    for (var error in data.errors) {
      print('------------------------------');
      print('>>>>> ' + error.errorMessage);
    }
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
    if (_expEntry.entryType == EntryType.EXPRESSION) {
      _expEntry.expression.completeCurrentTag();
    }
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
        } else {
          _expEntry.expression.addLine(line,lineType);
        }
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
    if (entry.entryType == EntryType.EXPRESSION) {
      var exp = entry.expression;
      String def = exp.tags['definition'];
      if (def == null) {
        setDefinitionFromMacro(entry);
      } else  {
        exp.definition = def;
      }
      exp.section = currentSection;
      data.expMap[exp.name] = exp;
    }
    if (entry.entryType == EntryType.SECTION_HEADER) {
      currentSection = entry.sourceText.substring(QvExpDirective.SECTION.length).trim();
    }
  }
  setDefinitionFromMacro(ExpressionEntry entry) {
    var exp = entry.expression;
    var macro = exp.tags['macro'];
    if (macro == null) {
      addError(entry,'Expression should have definition or macro defined');
      throw data.errors.last;
    } else {
      var macroList = macro.replaceAll('\n\r','\n').split('\n');
      if (macroList.length < 2) {
        addError(entry,'Invalid macro format');
        throw data.errors.last;
      }
      var macroFunName = macroList.first.trim();
      var macroFunExpr = data.expMap[macroFunName];
      if (macroFunExpr == null) {
        addError(entry,'Cannot find expression $macroFunName for macro');
        throw data.errors.last;
      }
      var def = macroFunExpr.definition;
      int paramNum = 0;
      for (var param in macroList.sublist(1)) {
        param = param.trim();
        if (param == '') {
          continue;
        }
        paramNum++;
        if (!param.startsWith('- ')) {
          addError(entry,'Invalid macro parameter format $param');
          throw data.errors.last;
        }
        param = param.substring(1).trim();
        def = def.replaceAll('\$$paramNum', param);
      }
      exp.definition = def.trim();
      entry.entryType = EntryType.MACRO;
    }
  }
  String printOut() {
    var sb = new StringBuffer();
    for (var entry in data.entries) {
      if (entry.entryType != EntryType.EXPRESSION && entry.entryType != EntryType.MACRO) {
        sb.writeln(entry.sourceText);
      } else {
        var expr = entry.expression;
        sb.writeln(QvExpDirective.EXPRESSION_DELIMITER);
        expr.tags.forEach((tag,value) {
          sb.writeln('$tag:$value');
        });
      }
    }
    return sb.toString();
  }
  String _nullToStr(str) => str == null? '': str;
  void importLabels(String labelsFileName, String outFileName) {
    List<String> header;
    int _getColumnPos(String colName) {
      int pos = header.indexOf(colName);
      if (pos == -1) {
        throw new Exception('Cannot fine ExpressionName in header row');
      }
      return pos;
    }
    var file = new File(labelsFileName);
    if (!file.existsSync()) {
      throw new Exception('Labels file not found: %labelsFileName');
    }
    var bytes = file.readAsBytesSync();
    String contents = SYSTEM_ENCODING.decoder.convert(bytes);
    List<List<String>> rows = new CsvCodec(fieldDelimiter: ';').decoder.convert(contents);
    header = rows[0];
    int namePos = _getColumnPos('ExpressionName');
    int labelPos = _getColumnPos('Label');
    int commentPos = _getColumnPos('Comments');
    int versionPos = _getColumnPos('Version');
    for (var row in rows.sublist(1)) {
      var name = row[namePos];
      var expr = data.expMap[name];
      if (expr == null) {
        print('Not found expression $name while improting labels');
      } else {
        bool updated = false;
        var label = row[labelPos].toString();
        if (_nullToStr(expr.tags['label']).trim() != label) {
          print('Updated label in expression $name');
          updated = true;
          expr.tags['label'] = label;
        }
        var comment = row[commentPos];
        if (_nullToStr(expr.tags['comment']).trim() != comment) {
          print('Updated comment in expression $name');
          updated = true;
          expr.tags['comment'] = comment;
        }
      }
    }
    new File(outFileName).writeAsStringSync(this.printOut());;
  }
  List<int> csvOut() {
    var codec = new CsvCodec();
    List<List<String>> outputList = [];
    outputList.add(['ExpressionName','Label','Comments','Section','Version','Definition']);
    for (var each in data.entries) {
      if (each.entryType == EntryType.EXPRESSION) {
        var expression = each.expression;
        var name = expression.name;
        var label = _nullToStr(expression.tags['label']).replaceAll('\n',' ').trim();
        var comments = _nullToStr(expression.tags['comment']).replaceAll('\n',' ').trim();
        var section = _nullToStr(expression.section);
        var version = _nullToStr(expression.tags['version']);
        var definition = _nullToStr(expression.tags['definition']).replaceAll('\n',' ').trim();
        outputList.add([name,label,comments,section,version,definition]);
      }
    }
    String strOut = codec.encoder.convert(outputList, fieldDelimiter: ';');
    return SYSTEM_ENCODING.encoder.convert(strOut);
  }
  void saveAsCsv(String outFileName) {
    var file = new File(outFileName);
    file.writeAsBytesSync(csvOut());
  }
}