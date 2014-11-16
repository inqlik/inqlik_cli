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
class XmlExtractor {
  static const SEEK_BUFFER_SIZE = 500000;
  String sourceFileName;
  bool qvwMode = false;
  String rootTag;
  Queue<int> token;
  final equality = new IterableEquality<int>();
  XmlExtractor(this.sourceFileName,this.rootTag);
  String extract() {
    qvwMode = sourceFileName.toUpperCase().endsWith('.QVW');
    var file = new File(sourceFileName);
    if (!file.existsSync()) {
      throw new Exception('Source file not found $sourceFileName');
    }
    var raf = file.openSync(mode: FileMode.READ);
    if (qvwMode) {
      int seekPos = raf.lengthSync() - SEEK_BUFFER_SIZE;
      if (seekPos > 0) {
        raf.setPositionSync(seekPos);
      }
    } 
    var bytes = raf.readSync(SEEK_BUFFER_SIZE);
    var tokenToMatch = '<$rootTag>'.codeUnits;
    token = new Queue<int>.from(tokenToMatch);
    _moveToken(0);
    int startPos = -1;
    for (int i = 0; i < SEEK_BUFFER_SIZE; i++) {
      _moveToken(bytes[i]);
      if (equality.equals(token, tokenToMatch)) {
        startPos = i;
        break;
      }
    }
    if (startPos == -1) {
      return '';
    }
    startPos -= tokenToMatch.length;
    tokenToMatch = '</$rootTag>'.codeUnits;
    token = new Queue<int>.from(tokenToMatch);
    _moveToken(0);
    int endPos = -1;
    for (int i = startPos; i < SEEK_BUFFER_SIZE; i++) {
      _moveToken(bytes[i]);
      if (equality.equals(token, tokenToMatch)) {
        endPos = i;
        break;
      }
    }
    if (endPos == -1) {
      return '';
    }
    print('XML range from $startPos to $endPos');
    return UTF8.decoder.convert(bytes.sublist(startPos,endPos+1));
  }
  void _moveToken(int byte) {
    token.removeFirst();
    token.addLast(byte);
//    print(new String.fromCharCodes(token));
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
  List<int> qvwFieldsToCsv(List<QvwFieldDescriptor> fields) {
    var codec = new CsvCodec(fieldDelimiter: ';');
    List<List<String>> outputList = [];
    outputList.add(['Name','SourceTables','Tags','Cardinal','TotalCount']);
    for (var each in fields) {
        outputList.add([each.name,each.sourceTables.join(','),each.tags.join(','),each.cardinal,each.totalCount]);
    }
    var csvOut = codec.encoder.convert(outputList);
    return SYSTEM_ENCODING.encoder.convert(csvOut);
  }
  
}