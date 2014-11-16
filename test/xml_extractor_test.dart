library xml_extractor_test;
import 'package:qvs/src/xml_extractor.dart';
import 'dart:io';
main () {
//  var extractor = new XmlExtractor(r'xml_extractor\Customers.qvd','QvdTableHeader');
  var extractor = new XmlExtractor(r'xml_extractor\QDF_PROJECT_SAMPLE.qvw','DocumentSummary');
  var res = extractor.extract();
//  print(res);
  var fields = extractor.getQvwFieldList(res);
  //fields.forEach(print);
  var csvOut = extractor.qvwFieldsToCsv(fields);
  //print(csvOut);
  var file = new File(r'xml_extractor\QDF_PROJECT_SAMPLE.meta.fields.csv').openSync(mode:FileMode.WRITE);
  file.writeFromSync(csvOut);
}