// Copyright (c) 2013, Lukas Renggli <renggli@gmail.com>

library simple_tests;

import 'package:qvs_parser/qvs_parser.dart';
import 'package:unittest/unittest.dart';

var qvs = new QvsGrammar();

dynamic validate(String source, String production) {
  var parser = qvs[production].end();
  var result = parser.parse(source);
  return result.value;
}

void main() {
  test('testIdentifier1', () {
    return validate('SimpleName', 'identifier');
  });
  test('testIdentifier2', () {
    return validate('_SimpleNameWithUnderscore', 'identifier');
  });
  test('testIdentifier3', () {
    return validate('@4', 'identifier');
  });
  test('testIdentifier4', () {
    return validate('_КодНоменклатуры', 'identifier');
  });

}
