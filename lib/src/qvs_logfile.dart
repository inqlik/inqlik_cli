library qvs_log_reader;

import 'dart:io';
import 'dart:typed_data';

class QvsLogTransformer {
  final String skipUpTo;
  final prefix;
  String get prefixPattern => prefix.isEmpty
      ? r'^\s*\d+[/.-]\d+[/.-]\d+ \d+:\d+:\d+( AM| PM)?: (.{4})  '
      : prefix;
  String fileName;
  RegExp regExp;
  QvsLogTransformer(this.fileName, {this.prefix: '', this.skipUpTo: ''}) {
    regExp = new RegExp(prefixPattern);
  }
  String transform() {
    print(fileName);
    File file = new File(fileName);
    if (!file.existsSync()) {
      throw (new FileSystemException('File not found: $fileName'));
    }
    return file.readAsStringSync();
  }
  String transformString(String input) {
    input.split('\n');
    var sb = new StringBuffer();
    bool headerSkipped = false;
    if (skipUpTo.isEmpty) {
      headerSkipped = true;
    }
    var prevPrefixId;
    for (var line in input.split('\n')) {
      if (!headerSkipped) {
        if (line.contains(skipUpTo)) {
          headerSkipped = true;
        }
      }
      if (headerSkipped) {
        if (prefixPattern.isEmpty) {
          sb.writeln(line);
        } else {
          var match = regExp.firstMatch(line);
          if (match != null) {
            var prefix = match[0];
            var prefixId = match[2];
            if (prefixId == '    ' || prefixId == prevPrefixId) {
              sb.writeln('//>> ' + line);
            } else {
              sb.writeln(line.substring(prefix.length));
            }
            prevPrefixId = prefixId;
          } else {
            sb.writeln(line);
          }
        }
      }
    }
    return sb.toString();
  }
}
