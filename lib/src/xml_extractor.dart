library xml_extractor;
import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:csv/csv.dart';
import 'package:collection/equality.dart';
import 'package:xml/xml.dart' as xml;
class QvwFieldDescriptor {
  String name;
  List<String> sourceTables;
  List<String> tags;
  int cardinal;
  int totalCount;
  String toString() => 'QvwFieldDescriptor($name, sourceTables:$sourceTables, tags: $tags)';
}

class QvwVarDescriptor {
  String name;
  bool isConfig;
  bool isReserved;
  String comment;
  String rawValue;
  String toString() => 'QvwVarDescriptor($name, $rawValue)';
}


class XmlExtractor {
  static const MB = 1048576;
  int seekBufferSize;
  String sourceFileName;
  bool _qvwMode;
  Queue<int> token;
  final equality = new IterableEquality<int>();
  XmlExtractor(this.sourceFileName,[int seekBufferSize = 5]) {
    this.seekBufferSize = seekBufferSize * MB;
    setQvwMode(sourceFileName.toUpperCase().endsWith('.QVW'));
  }
  setQvwMode(bool mode) {
    _qvwMode = mode;
  }
  int findStartPosition(List<int> bytes) {
    var tokenToMatch = '<DocumentSummary>'.codeUnits;
    token = new Queue<int>.from(tokenToMatch);
    _moveToken(0);
    int startPos = -1;
    for (int i = seekBufferSize - 1; i > 0 ; i--) {
      _moveToken(bytes[i]);
      if (equality.equals(token, tokenToMatch)) {
        startPos = i;
        break;
      }
    }
    return startPos;
  }
  String extract() {
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
    for (int i = startPos; i < seekBufferSize ; i++) {
      if (bytes[i]==0) {
        endPos = i;
        break;
      }
    }
    if (endPos == -1) {
      return '';
    }
    return UTF8.decoder.convert(bytes.sublist(startPos,endPos));
  }
  void _moveToken(int byte) {
    token.removeLast();
    token.addFirst(byte);
  }

  List<QvwFieldDescriptor> getQvwFieldList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<QvwFieldDescriptor> res = [];
    for (xml.XmlElement each in doc.findAllElements('FieldDescription')) {
      var fd = new QvwFieldDescriptor();
      fd.name = each.findElements('Name').first.text;
      fd.cardinal = int.parse(each.findElements('Cardinal').first.text);
      fd.totalCount = int.parse(each.findElements('TotalCount').first.text);
      fd.sourceTables = each.findElements('SrcTables').first.findElements('String').map((el)=>el.text).toList();
      fd.tags = each.findElements('Tags').first.findElements('String').map((el)=>el.text).toList();
      res.add(fd);
    }
    return res;
  }

  List<QvwVarDescriptor> getQvwVarList(String xmlMetadata) {
    var doc = xml.parse(xmlMetadata);
    List<QvwVarDescriptor> res = [];
    for (xml.XmlElement each in doc.findAllElements('VariableDescription')) {
      var vd = new QvwVarDescriptor();
      vd.name = each.findElements('Name').first.text;
      vd.isConfig = each.findElements('IsConfig').first.text.trim().toLowerCase() == 'true';
      vd.isReserved = each.findElements('IsReserved').first.text.trim().toLowerCase() == 'true';
      vd.comment = each.findElements('Comment').first.text;
      vd.rawValue = each.findElements('RawValue').first.text;
      res.add(vd);
    }
    return res;
  }


  String qvwFieldsToCsv(List<QvwFieldDescriptor> fields) {
    var codec = new CsvCodec(fieldDelimiter: '\t');
    List<List<String>> outputList = [];
    outputList.add(['Name','SourceTables','Tags','Cardinal','TotalCount']);
    for (var each in fields) {
        outputList.add([each.name,each.sourceTables.join(','),each.tags.join(','),each.cardinal,each.totalCount]);
    }
    return codec.encoder.convert(outputList);
  }
  
}