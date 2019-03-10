library xml_extractor;

import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:collection/equality.dart';
import 'package:xml/xml.dart' as xml;

class XmlField {
  String name;
  List<String> sourceTables;
  List<String> tags;
  int uniqueValues;
  bool isSystem;
  int totalCount;
  String toString() =>
      'XmlField($name, sourceTables:$sourceTables, tags: $tags)';
}

class QvwVar {
  String name;
  bool isConfig;
  bool isReserved;
  String comment;
  String rawValue;
  String toString() => 'QvwVar($name, $rawValue)';
}

class QvwSheetObject {
  String id;
  String title;
  String text;
  String type;
  String field;
  String parent = '';
  String toString() => 'QvwSheetObject($id, $type)';
}

class XmlExtractor {
  static const MB = 1048576;
  int seekBufferSize;
  String sourceFileName;
  bool _qvwMode;
  Queue<int> token;
  String mode;
  final equality = new IterableEquality<int>();
  XmlExtractor(this.sourceFileName, [int seekBufferSize = 5]) {
    this.seekBufferSize = seekBufferSize * MB;
  }
  setQvwMode(bool mode) {
    _qvwMode = mode;
  }
  int findStartPosition(List<int> bytes) {
    var tokenToMatch = '<DocumentSummary>'.codeUnits;
    token = new Queue<int>.from(tokenToMatch);
    _moveToken(0);
    int startPos = -1;
    for (int i = seekBufferSize - 1; i > 0; i--) {
      _moveToken(bytes[i]);
      if (equality.equals(token, tokenToMatch)) {
        startPos = i;
        break;
      }
    }
    return startPos;
  }
  String extract() {
    setQvwMode(sourceFileName.toUpperCase().endsWith('.QVW'));
    var file = new File(sourceFileName);
    if (!file.existsSync()) {
      throw new Exception('Source file not found $sourceFileName');
    }
    var raf = file.openSync(mode: FileMode.READ);
    if (_qvwMode) {
      int seekPos = raf.lengthSync() - seekBufferSize;
      if (seekPos > 0) {
        raf.setPositionSync(seekPos);
      } else {
        seekBufferSize = raf.lengthSync();
      }
    }
    var bytes = raf.readSync(seekBufferSize);
    int startPos = 0;
    if (_qvwMode) {
      startPos = findStartPosition(bytes);
    }
    if (startPos == -1) {
      return '';
    }
    int endPos = -1;
    for (int i = startPos; i < seekBufferSize; i++) {
      if (bytes[i] == 0) {
        endPos = i;
        break;
      }
    }
    if (endPos == -1) {
      return '';
    }
    return utf8.decoder.convert(bytes.sublist(startPos, endPos));
  }
  void _moveToken(int byte) {
    token.removeLast();
    token.addFirst(byte);
  }

  List<XmlField> getQvwFieldList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<XmlField> res = [];
    for (xml.XmlElement each in doc.findAllElements('FieldDescription')) {
      var fd = new XmlField();
      fd.name = each.findElements('Name').first.text;
      fd.uniqueValues = int.parse(each.findElements('Cardinal').first.text);
      fd.isSystem = each.findElements('IsSystem').first.text
              .trim()
              .toLowerCase() ==
          'true';
      fd.totalCount = int.parse(each.findElements('TotalCount').first.text);
      fd.sourceTables = each.findElements('SrcTables').first
          .findElements('String')
          .map((el) => el.text)
          .toList();
      fd.tags = each.findElements('Tags').first
          .findElements('String')
          .map((el) => el.text)
          .toList();
      res.add(fd);
    }
    return res;
  }

  List<XmlField> getQvdFieldList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<XmlField> res = [];
    var recordsCount = int.parse(doc.findAllElements('NoOfRecords').first.text,
        onError: (str) => 0);
    for (xml.XmlElement each in doc.findAllElements('QvdFieldHeader')) {
      var fd = new XmlField();
      fd.name = each.findElements('FieldName').first.text;
      fd.uniqueValues = int.parse(each.findElements('NoOfSymbols').first.text);
      fd.totalCount = recordsCount;
      res.add(fd);
    }
    return res;
  }

  List<XmlField> getQvxFieldList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<XmlField> res = [];
    for (xml.XmlElement each in doc.findAllElements('QvxFieldHeader')) {
      var fd = new XmlField();
      fd.name = each.findElements('FieldName').first.text;
      res.add(fd);
    }
    return res;
  }

  String qvdFieldsToCsv(List<XmlField> fields) {
    var codec = new CsvCodec(fieldDelimiter: '\t');
    List<List<String>> outputList = [];
    outputList.add(['FieldName', 'NoOfSymbols', 'NoOfRecords']);
    for (var each in fields) {
      outputList.add([each.name, each.uniqueValues.toString(), each.totalCount.toString()]);
    }
    return codec.encoder.convert(outputList);
  }

  List<QvwVar> getQvwVarList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<QvwVar> res = [];
    for (xml.XmlElement each in doc.findAllElements('VariableDescription')) {
      var vd = new QvwVar();
      vd.name = each.findElements('Name').first.text;
      vd.isConfig = each.findElements('IsConfig').first.text
              .trim()
              .toLowerCase() ==
          'true';
      vd.isReserved = each.findElements('IsReserved').first.text
              .trim()
              .toLowerCase() ==
          'true';
      vd.comment = each.findElements('Comment').first.text;
      vd.rawValue = each.findElements('RawValue').first.text;
      res.add(vd);
    }
    return res;
  }

  String qvwFieldsToCsv(List<XmlField> fields) {
    var codec = new CsvCodec(fieldDelimiter: '\t');
    List<List<String>> outputList = [];
    outputList.add(
        ['Name', 'SourceTables', 'Tags', 'Cardinal', 'TotalCount', 'IsSystem']);
    for (var each in fields) {
      outputList.add([
        each.name,
        each.sourceTables.join(','),
        each.tags.join(','),
        each.uniqueValues.toString(),
        each.totalCount.toString(),
        each.isSystem.toString()
      ]);
    }
    return codec.encoder.convert(outputList);
  }

  String qvwObjectsToCsv(List<QvwSheetObject> objects) {
    var codec = new CsvCodec(fieldDelimiter: '\t');
    List<List<String>> outputList = [];
    outputList.add(['Id', 'Title', 'Type', 'Parent', 'Field','Text']);
    for (var each in objects) {
      outputList.add([
        each.id,
        each.title,
        each.type,
        each.parent,
        each.field,
        each.text
      ]);
    }
    return codec.encoder.convert(outputList);
  }

  String qvwVariablesToCsv(List<QvwVar> vars) {
    var codec = new CsvCodec(fieldDelimiter: '\t');
    List<List<String>> outputList = [];
    outputList.add(['Name', 'Value', 'IsConfig', 'IsReserved', 'Comment']);
    for (var each in vars) {
      outputList.add([
        each.name,
        each.rawValue,
        each.isConfig.toString(),
        each.isReserved.toString(),
        each.comment
      ]);
    }
    return codec.encoder.convert(outputList);
  }
  String qvwVariablesToQvs(List<QvwVar> vars, String sourceFile) {
    var sb = new StringBuffer();
    sb.writeln('//// Autogenerated from $sourceFile');
    for (var each in vars) {
      var str = each.rawValue;
      if (str.contains(r'$(')) {
        var res = str.replaceAll(r'$(', '@(');
        res = res.replaceAll("'", '~~~');
        res = "replace(replace('$res','~~~', chr(39)), '@(', chr(36) & '(')";
        sb.writeln('LET ${each.name} = $res;');
      } else {
        sb.writeln('SET ${each.name} = $str;');
      }
    }
    return sb.toString();
  }
  String getLoadStatement(List<XmlField> fields, bool forceQuote) {
    String quote(String field) {
      if (forceQuote) {
        return '  [$field]';
      }
      if (field.contains(r'[ ().,)]')) {
        return '  [$field]';
      }
      return '  $field';
    }
    var fileName = path.absolute(sourceFileName);
    var sb = new StringBuffer();
    var quotedFields = fields.map((f) => quote(f.name));
    sb.writeln(fileName);
    sb.writeln('------------------------------------------------\n');
    sb.writeln('LOAD');
    sb.writeln(quotedFields.join(',\n'));
    var quotedFileName = '    FROM [$fileName] ($mode);';
    sb.writeln(quotedFileName);
    return sb.toString();
  }
  List<QvwSheetObject> getSheetObjects(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<QvwSheetObject> res = <QvwSheetObject>[];
    Map<String, String> relations = {};

    for (xml.XmlElement each in doc.findAllElements('Sheet')) {
      var obj = new QvwSheetObject();
      obj.id = each.findElements('SheetId').first.text;
      obj.type = 'Sheet';
      obj.text = '';
      obj.parent = 'Root';
      obj.title = each.findElements('Title').first.text;
      res.add(obj);
      var childElements = each.findElements('ChildObjects');
      if (childElements.isNotEmpty) {
        for (xml.XmlElement objectId
            in childElements.first.findAllElements('ObjectId')) {
          var id = objectId.text.trim();
          if (relations.containsKey(id)) {
            relations[id] = '>${relations[id]},${obj.id}';
          } else {
            relations[id] = obj.id;
          }
        }
      }
    }
    for (xml.XmlElement each in doc.findAllElements('SheetObject')) {
      var obj = new QvwSheetObject();
      obj.id = elementText(each.findElements('ObjectId')).trim();
      obj.type = elementText(each.findElements('Type'));
      obj.title = elementText(each.findElements('Caption'));
      obj.text = elementText(each.findElements('Text'));
      obj.field = elementText(each.findElements('Field'));
      var parent = relations[obj.id];
      if (!parent.startsWith('>')) {
        obj.parent = parent;
      }
      res.add(obj);
    }
    return res;
  }
}
String elementText(List<xml.XmlElement> list) {
  if (list.isEmpty) {
    return '';
  }
  return list.first.text;
}
